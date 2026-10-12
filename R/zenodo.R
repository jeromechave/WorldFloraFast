## --------------------------------------------------------------------------------------
## zenodo.R: download of the WFO Plant List from Zenodo
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - none
##   Changed:
##     - none
##   New in WorldFloraFast:
##     - The whole file, factored from the stand-alone script download_classification.R:
##       resolving the newest version of the Zenodo record, both JSON layouts, retries
##       with back-off, MD5 verification, extraction from the Darwin Core archives,
##       atomic installation, and classification_source.json.
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

## Base URL; can be overridden with the environment variable ZENODO_BASE (mirrors, tests)
.zenodo.base <- function() Sys.getenv("ZENODO_BASE", "https://zenodo.org")

## Download `url` to `dest`, retrying with exponential back-off (Zenodo rate-limits and
## has intermittent outages). A 404 is permanent and is not retried.
.download.with.retry <- function(url, dest, tries = 4L, quiet = FALSE, timeout = 3600) {
  wait <- as.numeric(Sys.getenv("ZENODO_RETRY_WAIT", "5"))
  op <- options(HTTPUserAgent = paste0("R package WorldFloraFast ", utils::packageVersion("WorldFloraFast")),
                timeout = max(timeout, getOption("timeout")))
  on.exit(options(op), add = TRUE)

  last.err <- ""
  for (i in seq_len(tries)) {
    msgs <- character()
    ok <- withCallingHandlers(
      tryCatch({
        utils::download.file(url, dest, mode = "wb", quiet = quiet, method = "libcurl")
        .file.ok(dest)
      }, error = function(e) { msgs <<- c(msgs, conditionMessage(e)); FALSE }),
      warning = function(w) { msgs <<- c(msgs, conditionMessage(w)); invokeRestart("muffleWarning") }
    )
    if (ok) return(invisible(dest))

    last.err <- paste(unique(msgs), collapse = " | ")
    unlink(dest)
    if (grepl("404", last.err, fixed = TRUE)) break
    if (i < tries) {
      message(sprintf("  attempt %d/%d failed (%s); retrying in %gs ...",
                      i, tries, substr(last.err, 1, 120), wait))
      Sys.sleep(wait)
      wait <- wait * 2
    }
  }
  stop(sprintf("Could not download %s\n  %s", url, last.err), call. = FALSE)
}

.zenodo.json <- function(path) {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)
  .download.with.retry(paste0(.zenodo.base(), path), tmp, quiet = TRUE)
  jsonlite::fromJSON(tmp, simplifyVector = FALSE)
}

## Record ID as a plain string (never scientific notation such as "1e+08")
.record.id.chr <- function(rec) {
  if (is.numeric(rec$id)) format(rec$id, scientific = FALSE, trim = TRUE) else as.character(rec$id)
}

## Newest version of the record family that `record.id` belongs to (or the record itself)
.resolve.record <- function(record.id, pinned = FALSE) {
  if (!pinned) {
    rec <- tryCatch(
      .zenodo.json(sprintf("/api/records/%s/versions/latest", record.id)),
      error = function(e) {
        warning("Could not resolve the latest version (", conditionMessage(e),
                ").\n  Falling back to record ", record.id, " as given.", call. = FALSE)
        NULL
      })
    if (!is.null(rec)) return(rec)
  }
  .zenodo.json(sprintf("/api/records/%s", record.id))
}

## File entries of a record, whichever JSON layout Zenodo returns:
##   files: [ {key, size, checksum, ...}, ... ]                    (legacy)
##   files: { entries: [ ... ] } or { entries: { key: {...} } }    (InvenioRDM)
##   files: { enabled: true }  -> fetch /api/records/<id>/files
.extract.files <- function(rec) {
  f <- rec$files
  if (is.list(f) && length(f) && is.null(names(f))) {
    entries <- f
  } else if (is.list(f) && !is.null(f$entries)) {
    entries <- unname(f$entries)
  } else {
    listing <- .zenodo.json(sprintf("/api/records/%s/files", .record.id.chr(rec)))
    entries <- unname(listing$entries %||% list())
  }
  out <- lapply(entries, function(e) list(
    key      = e$key %||% e$filename %||% NA_character_,
    size     = as.numeric(e$size %||% NA),
    checksum = sub("^md5:", "", as.character(e$checksum %||% NA_character_))
  ))
  Filter(function(e) !is.na(e$key), out)
}

.file.url <- function(rec.id, key) {
  sprintf("%s/records/%s/files/%s?download=1", .zenodo.base(), rec.id,
          utils::URLencode(key, reserved = TRUE))
}

.verify.md5 <- function(path, expected) {
  if (is.na(expected) || !nzchar(expected)) {
    message("  (no checksum published for this file; skipping verification)")
    return(invisible(TRUE))
  }
  got <- unname(tools::md5sum(path))
  if (!identical(tolower(got), tolower(expected))) {
    unlink(path)
    stop(sprintf("Checksum mismatch for %s: expected %s, got %s. The file was deleted; try again.",
                 basename(path), expected, got), call. = FALSE)
  }
  message("  checksum OK (md5 ", got, ")")
  invisible(TRUE)
}

## Name of `target` inside a zip (any folder), or NA
.find.in.zip <- function(zipfile, target) {
  lst <- utils::unzip(zipfile, list = TRUE)
  hit <- lst$Name[!grepl("/$", lst$Name) & tolower(basename(lst$Name)) %in% tolower(target)]
  if (length(hit)) hit[[1]] else NA_character_
}

## Move `src` to `dest` atomically (via dest.part), so an interrupted transfer can never
## leave a truncated file that looks finished. Renames when possible (no 1 GB copy).
.install.file <- function(src, dest) {
  part <- paste0(dest, ".part")
  on.exit(unlink(part), add = TRUE)
  if (!suppressWarnings(file.rename(src, part))) {
    if (!file.copy(src, part, overwrite = TRUE)) stop("Could not write ", part, call. = FALSE)
  }
  if (file.exists(dest)) unlink(dest)
  if (!file.rename(part, dest)) stop("Could not move ", part, " to ", dest, call. = FALSE)
  invisible(dest)
}

## Metadata saved by a previous download (NULL if unavailable)
.read.source.info <- function(dir) {
  path <- file.path(dir, .WFO.SOURCE.INFO)
  if (!file.exists(path)) return(NULL)
  tryCatch(jsonlite::fromJSON(path), error = function(e) NULL)
}

.with.source <- function(path, info) {
  structure(path,
            version = info$version %||% NA_character_,
            record_id = as.character(info$record_id %||% NA_character_),
            doi = info$doi %||% NA_character_)
}

## Download classification.csv from a Zenodo record into out.dir (no-op logic is in WFO.download)
.zenodo.fetch <- function(rec, out.dir, timeout) {
  final <- file.path(out.dir, .WFO.TARGET.FILE)
  rec.id <- .record.id.chr(rec)
  version <- rec$metadata$version %||% NA_character_
  doi <- rec$doi %||% rec$pids$doi$identifier %||% NA_character_

  files <- .extract.files(rec)
  if (!length(files)) stop("Record ", rec.id, " lists no files.", call. = FALSE)
  keys <- vapply(files, `[[`, "", "key")

  work <- file.path(out.dir, ".download")
  dir.create(work, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  source.file <- source.md5 <- NA_character_

  direct <- which(tolower(keys) == tolower(.WFO.TARGET.FILE))
  if (length(direct)) {
    ## 1) classification.csv published directly
    f <- files[[direct[[1]]]]
    message("Downloading ", f$key, " ...")
    part <- file.path(work, f$key)
    .download.with.retry(.file.url(rec.id, f$key), part, timeout = timeout)
    .verify.md5(part, f$checksum)
    .install.file(part, final)
    source.file <- f$key; source.md5 <- f$checksum
  } else {
    ## 2) inside one of the Darwin Core archives
    archives <- .WFO.ARCHIVES[.WFO.ARCHIVES %in% keys]
    if (!length(archives)) {
      stop(sprintf(paste0(
        "Version %s (record %s) does not contain %s or any of the archives that normally hold it (%s).\n",
        "Files in this record: %s\n",
        "If an earlier release still has them, re-run with e.g.  record_id = \"%s\", pinned = TRUE"),
        version, rec.id, .WFO.TARGET.FILE, paste(.WFO.ARCHIVES, collapse = ", "),
        paste(keys, collapse = ", "), .WFO.SEED.RECORD), call. = FALSE)
    }
    for (a in archives) {
      f <- files[[match(a, keys)]]
      message(sprintf("Downloading %s (%s) ...", f$key,
                      if (is.na(f$size)) "size unknown"
                      else format(structure(f$size, class = "object_size"), units = "auto")))
      zipfile <- file.path(work, f$key)
      .download.with.retry(.file.url(rec.id, f$key), zipfile, timeout = timeout)
      .verify.md5(zipfile, f$checksum)

      member <- .find.in.zip(zipfile, .WFO.TARGET.FILE)
      if (is.na(member)) {
        message("  ", .WFO.TARGET.FILE, " is not in ", f$key, "; trying the next archive ...")
        unlink(zipfile)
        next
      }
      message("Extracting ", member, " ...")
      xdir <- file.path(work, "x")
      utils::unzip(zipfile, files = member, exdir = xdir, junkpaths = TRUE)
      unlink(zipfile)
      extracted <- file.path(xdir, basename(member))
      if (!file.exists(extracted)) stop("Extraction of ", member, " failed.", call. = FALSE)
      .install.file(extracted, final)
      source.file <- f$key; source.md5 <- f$checksum
      break
    }
    if (is.na(source.file)) {
      stop(sprintf("%s was not found in any of: %s (record %s, version %s).",
                   .WFO.TARGET.FILE, paste(archives, collapse = ", "), rec.id, version), call. = FALSE)
    }
  }

  info <- list(record_id = rec.id, version = version, doi = doi, source_file = source.file,
               source_md5 = source.md5, downloaded = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  jsonlite::write_json(info, file.path(out.dir, .WFO.SOURCE.INFO), auto_unbox = TRUE, pretty = TRUE)
  message(sprintf("Done: %s  (%s)", normalizePath(final),
                  format(structure(file.size(final), class = "object_size"), units = "auto")))
  .with.source(final, info)
}
