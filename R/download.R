# ----------------------------------------------------------------------------
# download.R: download of the backbone (WFO.download)
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - WFO.download(): name, the arguments WFO.url, save.dir, WFO.remember and
#       timeout, and downloading a zip from WFO.url (.download.legacy()).
#   Changed:
#     - Without WFO.url, the backbone is downloaded from Zenodo (see zenodo.R);
#       the result is the path of the backbone.
#   New in WorldFloraFast:
#     - Arguments force, update, record.id and pinned; download_classification()
#       (name of the stand-alone script; deprecated in 1.0.3).
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

#' Download the World Flora Online taxonomic backbone
#'
#' Downloads the latest `classification.csv` of the World Flora Online (WFO)
#' Plant List from Zenodo (<https://zenodo.org/records/18007552> and its newer
#' versions), unless a copy is already present. Downloads are verified with the
#' published MD5 checksum and retried with exponential back-off.
#'
#' @param WFO.url If given, download a zip archive from this address and extract
#'   `classification.csv` (or `classification.txt`) instead of using Zenodo.
#' @param save.dir,out_dir Directory for the backbone (created if needed).
#' @param WFO.remember If `TRUE`, remember the location of the file and load the
#'   backbone as `WFO.data` with [WFO.remember()].
#' @param timeout Minimum timeout in seconds for the download.
#' @param force If `TRUE`, download again even if a copy exists.
#' @param update If `TRUE` and a copy exists, check Zenodo for a newer release
#'   and download it if there is one. Without it, an existing copy is used and
#'   Zenodo is not contacted. If Zenodo cannot be reached, the local copy is
#'   kept with a warning.
#' @param record.id,record_id Zenodo record to start from (any version of the
#'   WFO Plant List).
#' @param pinned If `TRUE`, use `record.id` itself instead of its newest
#'   version.
#' @param ... Further arguments for [utils::download.file()] (with `WFO.url`
#'   only).
#'
#' @details Next to the backbone, `classification_source.json` records the
#' Zenodo record, version, DOI, source file, MD5 checksum and date of the
#' download. A mirror can be used by setting the environment variable
#' `ZENODO_BASE`; `ZENODO_RETRY_WAIT` sets the first waiting time (in seconds)
#' between retries.
#'
#' `download_classification()` is deprecated: use `WFO.download()`. It used the
#' argument names of the stand-alone download script, unlike the other
#' functions, and does not remember or load the backbone (`WFO.remember =
#' FALSE`).
#'
#' @return The path of the backbone file (invisibly), with attributes `version`,
#'   `record_id` and `doi` (`NA` when unknown).
#' @seealso [WFO.read()], [WFO.remember()]
#' @export
#' @examples
#' \dontrun{
#' # download (or find) the backbone, remember it and load it as WFO.data
#' WFO.download(save.dir = "wfo_data")
#'
#' # later: look for a newer release
#' WFO.download(save.dir = "wfo_data", update = TRUE)
#'
#' # a specific release: the WFO Plant List 2026-06
#' WFO.download(save.dir = "wfo_2026_06", record.id = "20782718", pinned = TRUE)
#' }
WFO.download <- function(
  WFO.url = NULL, save.dir = getwd(), WFO.remember = TRUE, timeout = 3600,
  force = FALSE, update = FALSE, record.id = "18007552", pinned = FALSE, ...
) {
  dir.create(save.dir, showWarnings = FALSE, recursive = TRUE)

  if (!is.null(WFO.url)) {
    final <- .download.legacy(WFO.url, save.dir, timeout, ...)
  } else {
    final <- file.path(save.dir, .WFO.TARGET.FILE)
    have.local <- .file.ok(final)
    prev <- .read.source.info(save.dir)

    if (have.local && !force && !update) {
      # 1) already downloaded: decide locally, without touching the network
      message(
        "Already downloaded: ", normalizePath(final),
        if (!is.null(prev)) {
          sprintf(
            " (WFO Plant List %s, downloaded %s)",
            prev$version,
            prev$downloaded
          )
        }
      )
      message(
        "  Skipping the download. Use update = TRUE to look for a newer ",
        "release, or force = TRUE to redo it."
      )
      final <- .with.source(final, prev)
    } else {
      message(
        "Looking up the ",
        if (pinned) "record " else "latest version of record ",
        record.id,
        " ..."
      )
      rec <- tryCatch(.resolve.record(record.id, pinned), error = function(e) {
        if (have.local && !force) {
          warning("Zenodo could not be reached (", conditionMessage(e),
            "); keeping the local copy.",
            call. = FALSE
          )
          return(NULL)
        }
        stop(e)
      })
      if (is.null(rec)) {
        final <- .with.source(final, prev)
      } else {
        rec.id <- .record.id.chr(rec)
        message(sprintf(
          "  -> record %s, version %s (%s)", rec.id,
          rec$metadata$version %||% NA,
          rec$doi %||% rec$pids$doi$identifier %||% NA
        ))
        if (have.local && !force && !is.null(prev) && identical(
          as.character(prev$record_id),
          rec.id
        )) {
          # 2) update = TRUE and the local copy is from this release
          message(
            "Your local copy is already the newest release (",
            prev$version,
            "); nothing to do."
          )
          final <- .with.source(final, prev)
        } else {
          if (have.local && !force) {
            message("A different release is available; downloading it ...")
          }
          final <- .zenodo.fetch(rec, save.dir, timeout)
        }
      }
    }
  }

  if (WFO.remember == TRUE) WFO.remember(WFO.file = final)
  invisible(final)
}

#' @rdname WFO.download
#' @export
download_classification <- function(
  out_dir = "wfo_data",
  force = FALSE,
  update = FALSE,
  record_id = "18007552", pinned = FALSE
) {
  .Deprecated("WFO.download", package = "WorldFloraFast")
  WFO.download(
    save.dir = out_dir, WFO.remember = FALSE, force = force, update = update,
    record.id = record_id, pinned = pinned
  )
}

# Previous behaviour: download a zip from a given URL and unzip the backbone
# file
.download.legacy <- function(WFO.url, save.dir, timeout, ...) {
  op <- options(timeout = max(timeout, getOption("timeout")))
  on.exit(options(op), add = TRUE)
  message("Downloading and extracting zip file in ", save.dir)
  save.file <- file.path(save.dir, basename(sub("[?].*$", "", WFO.url)))
  if (!grepl(
    "[.]zip$",
    save.file,
    ignore.case = TRUE
  )) {
    save.file <- file.path(save.dir, "WFO_Backbone.zip")
  }
  utils::download.file(WFO.url, destfile = save.file, mode = "wb", ...)
  member <- .find.in.zip(
    save.file,
    c("classification.csv", "classification.txt")
  )
  if (is.na(member)) {
    stop(
      "Taxonomic backbone data of 'classification.txt' or ",
      "'classification.csv' could not be found in ",
      save.file,
      call. = FALSE
    )
  }
  utils::unzip(save.file, files = member, exdir = save.dir, junkpaths = TRUE)
  file.path(save.dir, basename(member))
}
