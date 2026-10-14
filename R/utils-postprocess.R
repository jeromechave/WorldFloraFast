# ----------------------------------------------------------------------------
# utils-postprocess.R: post-processing of matches
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - Hybrid flag, one-step replacement of synonyms by accepted names with the
#       columns New.accepted and Old.*, exclusion of infraspecific ranks,
#       Auth.dist and Old.author.dist (from WFO.match()).
#   Changed:
#     - Vectorised: one lookup of accepted IDs instead of a backbone scan per
#       row; columns replaced by name, not position (NEWS 6); one summary
#       warning instead of one per row.
#     - Ranks compared in standard form (WFO 2026-06).
#   New in WorldFloraFast:
#     - .finish.match(): these steps shared by WFO.match() and #
#       WFO.match.fuzzyjoin().
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

# "\u00d7" for hybrid names, else ""
.hybrid.flag <- function(x) ifelse(grepl(.HYBRID, x, fixed = TRUE), .HYBRID, "")

# Replace synonyms by their accepted names (one step), vectorised.
.accepted.replace <- function(
  out,
  WFO.data,
  WFO.cols,
  WFO.index.ID,
  has.auth,
  Authorship
) {
  message("\nChecking new accepted IDs")
  n <- nrow(out)
  acc <- as.character(out$acceptedNameUsageID)
  acc[is.na(acc)] <- ""
  out$acceptedNameUsageID <- acc
  out$New.accepted <- rep(FALSE, n)
  out$Old.status <- rep("", n)
  out$Old.ID <- rep("", n)
  out$Old.name <- rep("", n)
  if (has.auth) {
    out$Old.author <- rep("", n)
    out$Old.author.dist <- rep(NA_real_, n)
  }
  todo <- which(acc != "")
  if (length(todo) == 0) {
    return(out)
  }

  id <- match(acc[todo], WFO.index.ID$u)
  cnt <- ifelse(is.na(id), 0L, WFO.index.ID$cnt[id])
  if (any(cnt == 0L)) {
    bad <- todo[cnt == 0L]
    warning(
      length(bad),
      " record(s) with acceptedNameUsageID not found in WFO.data, e.g. ",
      paste0(
        utils::head(acc[bad], 3),
        " from ",
        utils::head(out$scientificName[bad], 3),
        collapse = "; "
      ),
      call. = FALSE
    )
  }
  if (any(cnt > 1L)) {
    bad <- todo[cnt > 1L]
    warning(
      length(bad),
      " record(s) with more than 1 row of matches for acceptedNameUsageID, ",
      "e.g. ",
      paste0(
        utils::head(acc[bad], 3),
        " from ",
        utils::head(out$scientificName[bad], 3),
        collapse = "; "
      ),
      call. = FALSE
    )
  }
  ok <- cnt == 1L
  rows <- todo[ok]
  if (length(rows) == 0) {
    return(out)
  }
  new.rows <- WFO.index.ID$ord[WFO.index.ID$start[id[ok]]]

  out$New.accepted[rows] <- TRUE
  out$Old.status[rows] <- as.character(out$taxonomicStatus[rows])
  out$Old.ID[rows] <- as.character(out$taxonID[rows])
  out$Old.name[rows] <- as.character(out$scientificName[rows])
  if (has.auth) {
    out$Old.author[rows] <- as.character(out$scientificNameAuthorship[rows])
    out$Old.author.dist[rows] <- .pair.adist(
      out[[Authorship]][rows],
      out$scientificNameAuthorship[rows]
    )
  }
  # columns replaced by NAME (previous versions used column positions)
  repl <- .as.dt(WFO.data)[new.rows, WFO.cols, with = FALSE]
  for (v in WFO.cols) {
    if (is.factor(out[[v]])) out[[v]] <- as.character(out[[v]])
    out[[v]][rows] <- repl[[v]]
  }
  out$Hybrid[rows] <- .hybrid.flag(out$scientificName[rows])
  out
}

# Steps after matching, shared by WFO.match and WFO.match.fuzzyjoin: hybrid
# flag, replacement of synonyms, exclusion of infraspecific ranks, authorship
# distances
.finish.match <- function(out, WFO.data, WFO.cols, Authorship, has.auth,
                          acceptedNameUsageID.match,
                          exclude.infraspecific = FALSE,
                          infraspecific.excluded = NULL) {
  out$Hybrid <- .hybrid.flag(out$scientificName)
  if (acceptedNameUsageID.match) {
    idx <- .cached(
      .as.dt(WFO.data),
      "index.ID",
      function() .build.index(WFO.data$taxonID)
    )
    out <- .accepted.replace(out, WFO.data, WFO.cols, idx, has.auth, Authorship)
  }
  if (exclude.infraspecific) {
    # ranks compared in standard form: works with "var." (WFO <= 2025) and
    # "variety" (2026-06)
    excluded <- .rank.std(out$verbatimTaxonRank) %in%
      .rank.std(infraspecific.excluded)
    out <- out[!excluded, , drop = FALSE]
  }
  if (has.auth) {
    out$Auth.dist <- .pair.adist(
      out[[Authorship]],
      out$scientificNameAuthorship
    )
  }
  # as in WorldFlora: Old.author.dist is a character column ("" where no synonym
  # was replaced)
  if ("Old.author.dist" %in% names(out)) {
    out$Old.author.dist <- ifelse(
      is.na(out$Old.author.dist),
      "",
      as.character(out$Old.author.dist)
    )
  }
  out
}
