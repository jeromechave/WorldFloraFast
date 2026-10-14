# ----------------------------------------------------------------------------
# utils-input.R: input checks and coercion, reading the backbone
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - Behaviour of: converting a vector of names to a data.frame
#       (.as.spec.data()), renaming conflicting columns to .ORIG
#       (.rename.conflicts()), leaving out the columns created and modified
#       (.WFO.columns()), squishing with stringr::str_squish() (.squish()).
#   Changed:
#     - These steps are functions shared by all matching functions instead of
#       code repeated in each.
#   New in WorldFloraFast:
#     - .read.WFO() (reads via WFO.read(), or the remembered backbone), %||%,
#       .file.ok(), .as.dt() (no copy of a data.table backbone; 1.0.0),
#       .no.dates.deprecated().
#     - .parallel.lapply(): parallel processing that recomputes the results of
#       failed processes (1.0.2).
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

# `a` unless it is NULL or empty, else `b`
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# Remove repeated white space and white space at both ends (as WorldFlora)
.squish <- function(x) stringr::str_squish(x)

# TRUE if `path` is an existing, non-empty file
.file.ok <- function(path) {
  length(path) == 1L &&
    file.exists(path) && isTRUE(file.size(path) > 0)
}

# Coerce the submitted names to a data.frame (vector, factor, data.table, tibble
# ...)
.as.spec.data <- function(spec.data, default.name = "spec.name") {
  if (is.factor(spec.data) || is.atomic(spec.data)) {
    spec.data <- data.frame(spec.data, stringsAsFactors = FALSE)
    names(spec.data) <- default.name
  }
  as.data.frame(spec.data, stringsAsFactors = FALSE)
}

# Read or check the backbone. The user's object is never modified by reference.
.read.WFO <- function(WFO.file = NULL, WFO.data = NULL) {
  if (is.null(WFO.data)) {
    # WFO.file = NULL falls back to the location saved by WFO.remember or
    # WFO.download
    message("Reading WFO data")
    WFO.data <- WFO.read(WFO.file)
  }
  if (!data.table::is.data.table(WFO.data)) {
    WFO.data <- data.table::as.data.table(WFO.data)
  }
  for (v in c("taxonID", "scientificName")) {
    if (!v %in% names(WFO.data)) {
      stop(
        "WFO.data does not contain the required column '",
        v,
        "'"
      )
    }
  }
  WFO.data
}

# Backbone columns kept in results (dates are left out, as in WorldFlora >= 1.9)
.WFO.columns <- function(WFO.data) {
  setdiff(
    names(WFO.data),
    c("created", "modified")
  )
}

# Rename variables of spec.data that would clash with variables added by the
# matching
.rename.conflicts <- function(
  spec.data,
  WFO.cols,
  Authorship,
  acceptedNameUsageID.match
) {
  has.auth <- Authorship %in% names(spec.data)
  WFO.names <- c(WFO.cols, "Hybrid")
  if (has.auth) WFO.names <- c(WFO.names, "Auth.dist")
  if (acceptedNameUsageID.match) {
    WFO.names <- c(
      WFO.names,
      "New.accepted",
      "Old.status",
      "Old.ID",
      "Old.name"
    )
    if (has.auth) WFO.names <- c(WFO.names, "Old.author", "Old.author.dist")
  }
  for (nm in intersect(WFO.names, names(spec.data))) {
    message(
      "Original data set variable '",
      nm,
      "' replaced by variable '",
      nm,
      ".ORIG'"
    )
    names(spec.data)[names(spec.data) == nm] <- paste0(nm, ".ORIG")
  }
  spec.data
}

# The backbone as a data.table without copying it: data.table::as.data.table()
# copies a data.table (1.6 million rows: about 0.7 s, and new memory addresses
# that defeat the cache)
.as.dt <- function(x) {
  if (data.table::is.data.table(x)) x else data.table::as.data.table(x)
}

# Warning for the deprecated argument no.dates of WFO.match and
# WFO.match.fuzzyjoin
.no.dates.deprecated <- function() {
  warning(
    "Argument 'no.dates' is deprecated and ignored: columns 'created' and ",
    "'modified' ",
    "are always left out. It will be removed in a later version.",
    call. = FALSE
  )
}

# lapply(X, FUN), in parallel with `cores` processes where possible
# (parallel::mclapply, not on Windows). A worker process can fail without a
# result (for example when the system kills it for lack of memory); mclapply()
# then returns NULL or an error for all elements of that worker. Such elements
# are computed again in this R session, with a warning, so that results are
# always complete.
.parallel.lapply <- function(X, FUN, cores = 1) {
  if (cores <= 1 || .Platform$OS.type != "unix" || length(X) < 2) {
    return(lapply(X, FUN))
  }
  r <- suppressWarnings(parallel::mclapply(X, FUN, mc.cores = cores))
  failed <- which(!vapply(r, is.list, logical(1)))
  if (length(failed) > 0) {
    warning(
      length(failed),
      " of ",
      length(X),
      " names could not be matched by the parallel processes ",
      "(a process failed, for example for lack of memory); they were matched ",
      "again without ",
      "parallel processing. Use fewer cores to avoid this.",
      call. = FALSE
    )
    r[failed] <- lapply(X[failed], FUN)
  }
  r
}
