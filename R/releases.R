# ----------------------------------------------------------------------------
# releases.R: per-user data folder for the backbone, one folder per release
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - none
#   Changed:
#     - WorldFlora downloaded the backbone to the working directory (save.dir =
#       getwd()); WorldFloraFast downloads it by default to a per-user data
#       folder (tools::R_user_dir()), one subfolder per release (1.0.5).
#   New in WorldFloraFast:
#     - The whole file: the data folder, the release folders, the choice of the
#       backbone in a new session, and WFO.releases() (1.0.5).
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

#' Releases of the backbone in the data folder
#'
#' Lists the releases of the World Flora Online Plant List downloaded by
#' [WFO.download()] to the per-user data folder of WorldFloraFast, and deletes
#' the ones that are no longer needed (each takes about 1 GB).
#'
#' @param remove Releases to delete, as given in column `release` of the
#'   result (for example `"2025-12"`). `NULL` deletes nothing.
#'
#' @details By default, [WFO.download()] saves each release in its own folder
#' of the per-user data folder of WorldFloraFast, given by
#' [tools::R_user_dir()] (`R_user_dir("WorldFloraFast", "data")`, subfolder
#' `wfo`). This folder is the same in every session and project, and is kept
#' when the package or R are reinstalled. Its location can be changed with the
#' environment variable `R_USER_DATA_DIR`.
#'
#' In a new session, [WFO.match()] (without `WFO.data` or `WFO.file`),
#' [WFO.read()] and [WFO.remember()] (without `WFO.file`) use the backbone file
#' remembered by the last call to [WFO.download()] or [WFO.remember()]; if that
#' file no longer exists, they use the newest release in the data folder.
#'
#' Releases downloaded elsewhere with `WFO.download(save.dir = ...)` are not
#' listed or deleted.
#'
#' @return A data.frame with one row per release, newest first: `release`
#'   (version), `record.id` and `doi` (Zenodo), `downloaded` (date), `size.mb`,
#'   `in.use` (`TRUE` for the release that [WFO.read()] would use) and `file`.
#'   The data folder is given as attribute `folder`.
#' @seealso [WFO.download()], [WFO.read()]
#' @export
#' @examples
#' \dontrun{
#' WFO.releases() # releases in the data folder
#' WFO.releases(remove = "2025-12") # delete an old release
#' }
WFO.releases <- function(remove = NULL) {
  base <- .wfo.data.dir()
  rel <- .list.releases(base)
  if (length(remove) > 0) {
    unknown <- setdiff(remove, rel$release)
    if (length(unknown) > 0) {
      stop("No release ", paste(unknown, collapse = ", "), " in ", base,
        call. = FALSE
      )
    }
    for (r in remove) {
      folder <- dirname(rel$file[rel$release == r])
      unlink(folder, recursive = TRUE)
      message("Deleted release ", r, " (", folder, ")")
    }
    rel <- .list.releases(base)
  }
  message("WFO backbone releases in ", base)
  if (nrow(rel) == 0) message("  none; download one with WFO.download()")
  current <- .default.backbone.file()
  rel$in.use <- !is.null(current) &
    normalizePath(rel$file, mustWork = FALSE) ==
      normalizePath(as.character(current %||% ""), mustWork = FALSE)
  rel <- rel[, c(
    "release", "record.id", "doi", "downloaded", "size.mb", "in.use",
    "file"
  )]
  structure(rel, folder = base)
}

# Per-user data folder for the backbone: R_user_dir("WorldFloraFast", "data"),
# subfolder "wfo"
.wfo.data.dir <- function() {
  file.path(tools::R_user_dir("WorldFloraFast", which = "data"), "wfo")
}

# Name of the folder of a release: its version ("2026-06"), or the Zenodo record
# when the version is unknown
.release.folder <- function(version, rec.id) {
  if (is.null(version) || is.na(version) || !nzchar(version)) {
    return(paste0("record_", rec.id))
  }
  gsub("[^A-Za-z0-9._-]", "_", version)
}

# Releases in the data folder: one row per subfolder that holds a backbone
# file, newest first (releases named by date, such as "2026-06", by version;
# others by the time of download)
.list.releases <- function(base = .wfo.data.dir()) {
  empty <- data.frame(
    release = character(0), record.id = character(0), doi = character(0),
    downloaded = character(0), size.mb = numeric(0), file = character(0),
    stringsAsFactors = FALSE
  )
  if (!dir.exists(base)) {
    return(empty)
  }
  folders <- list.dirs(base, full.names = TRUE, recursive = FALSE)
  rows <- lapply(folders, function(d) {
    f <- file.path(d, c(.WFO.TARGET.FILE, "classification.txt"))
    f <- f[file.exists(f)]
    if (length(f) == 0) {
      return(NULL)
    }
    info <- .read.source.info(d)
    data.frame(
      release = basename(d),
      record.id = as.character(info$record_id %||% NA),
      doi = as.character(info$doi %||% NA),
      downloaded = as.character(info$downloaded %||% NA),
      size.mb = round(file.size(f[1]) / 1e6, 1),
      file = f[1],
      mtime = as.numeric(file.mtime(f[1])),
      stringsAsFactors = FALSE
    )
  })
  rel <- do.call(rbind, rows)
  if (is.null(rel)) {
    return(empty)
  }
  is.version <- grepl("^[0-9]{4}[-._][0-9]{2}", rel$release)
  ord <- order(!is.version, -rank(rel$release), -rel$mtime)
  rel <- rel[ord, setdiff(names(rel), "mtime")]
  rownames(rel) <- NULL
  rel
}

# Backbone file of the newest release in the data folder, or NULL
.latest.release <- function(base = .wfo.data.dir()) {
  rel <- .list.releases(base)
  if (nrow(rel) == 0) NULL else rel$file[1]
}

# Backbone file to use when none is given: the remembered file if it still
# exists, otherwise the newest release in the data folder; NULL if neither.
# Attribute "how" says which.
.default.backbone.file <- function() {
  rem <- .remembered.file()
  if (!is.null(rem)) {
    path <- as.character(rem)
    ok <- .file.ok(path) || (dir.exists(path) && length(list.files(
      path,
      pattern = "^classification[.](csv|txt)$"
    )) > 0)
    if (ok) {
      return(structure(path, how = "remembered", date = attr(rem, "date")))
    }
  }
  latest <- .latest.release()
  if (!is.null(latest)) {
    return(structure(latest, how = "newest release in the data folder"))
  }
  NULL
}

# Download to the data folder, in the folder of the release (save.dir = NULL)
.download.release <- function(force, update, record.id, pinned, timeout) {
  base <- .wfo.data.dir()
  latest <- .latest.release(base)
  # a pinned release is looked up even when other releases are present
  if (!is.null(latest) && !force && !update && !pinned) {
    info <- .read.source.info(dirname(latest))
    message(
      "Already downloaded: ", normalizePath(latest),
      " (release ", basename(dirname(latest)), ")"
    )
    message(
      "  Skipping the download. Use update = TRUE to look for a newer ",
      "release, or force = TRUE to redo it."
    )
    return(.with.source(latest, info))
  }
  message(
    "Looking up the ",
    if (pinned) "record " else "latest version of record ",
    record.id, " ..."
  )
  rec <- tryCatch(.resolve.record(record.id, pinned), error = function(e) {
    if (!is.null(latest) && !force) {
      warning("Zenodo could not be reached (", conditionMessage(e),
        "); keeping the local copy.",
        call. = FALSE
      )
      return(NULL)
    }
    stop(e)
  })
  if (is.null(rec)) {
    return(.with.source(latest, .read.source.info(dirname(latest))))
  }
  rec.id <- .record.id.chr(rec)
  version <- rec$metadata$version %||% NA
  message(sprintf(
    "  -> record %s, version %s (%s)", rec.id, version,
    rec$doi %||% rec$pids$doi$identifier %||% NA
  ))
  dir <- file.path(base, .release.folder(version, rec.id))
  final <- file.path(dir, .WFO.TARGET.FILE)
  prev <- .read.source.info(dir)
  same.release <- .file.ok(final) && !is.null(prev) &&
    identical(as.character(prev$record_id), rec.id)
  if (same.release && !force) {
    message("Release ", basename(dir), " is already downloaded; nothing to do.")
    return(.with.source(final, prev))
  }
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  message("Downloading release ", basename(dir), " to ", dir)
  .zenodo.fetch(rec, dir, timeout)
}
