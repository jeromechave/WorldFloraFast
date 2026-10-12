## --------------------------------------------------------------------------------------
## one.R: WFO.one(), one match per submitted name
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - WFO.one(): arguments, the sequence of criteria (Old.author.dist, Auth.dist,
##       First.dist, priority, smallest ID) and One.Reason.
##   Changed:
##     - Works per group of candidates instead of scanning and deleting rows of the whole
##       table.
##     - The authorship step no longer recycles a logical index computed on part of the
##       candidates (NEWS 9).
##     - Selections use which(), so NA distances cannot add empty rows; a group can never
##       disappear.
##     - Stops with an error if the result does not have each submitted record exactly once
##       (1.0.2).
##   New in WorldFloraFast:
##     - none
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

#' Keep one match per submitted name
#'
#' Reduces the results of [WFO.match()] to one row per
#' submitted name, choosing among several candidates with a fixed sequence of criteria.
#'
#' @param WFO.result Results of [WFO.match()].
#' @param priority `"Accepted"`: prefer accepted names, then names that are not synonyms.
#'   `"Synonym"`: prefer names that were not synonyms, then accepted names.
#' @param spec.name Name of the column with the submitted names. If given, submitted names
#'   without a match are copied to `scientificName` (with `One.Reason` "no match found").
#' @param Auth.dist Name of the column with the distance between submitted and matched
#'   authors (usually `"Auth.dist"`); if given, candidates with the closest authors are
#'   preferred.
#' @param Old.author.dist Name of the column with the distance between submitted authors and
#'   those of replaced synonyms (usually `"Old.author.dist"`); if given, synonym candidates
#'   with closer authors than any current-name candidate are preferred first.
#' @param First.dist Name of the column with the distance between first words (usually
#'   `"First.dist"`); if given, candidates with the closest genus are preferred.
#' @param verbose If `TRUE`, report the choices made.
#' @param counter Progress is reported every `counter` submitted names with several
#'   candidates.
#'
#' @details For each submitted name with several candidates, the criteria are applied in
#' this order, each only while several candidates remain: authorship of synonyms
#' (`Old.author.dist`), authorship of current names (`Auth.dist`), genus distance
#' (`First.dist`), `priority`, and finally the smallest numeric part of `taxonID`.
#' Column `One.Reason` gives the criterion that decided.
#'
#' Unlike WorldFlora 1.14-5, the authorship step compares the candidates that were not
#' replaced by accepted names, rather than a recycled selection of all candidates; the
#' chosen records were the same in our comparisons, but `One.Reason` can differ.
#'
#' @return `WFO.result` with one row per submitted name, and column `One.Reason`.
#' @seealso [WFO.match()]
#' @export
#' @examples
#' data(WFO.example2026)
#' m <- WFO.match(c("Omalanthus populneus", "World agroforestry"), WFO.data = WFO.example2026,
#'                Fuzzy.min = FALSE)        # non-default (of WFO.match): all fuzzy candidates
#' nrow(m)   # several candidates for the first name
#'
#' ## ---- default settings (those of WorldFlora) ----
#' WFO.one(m)[, c("spec.name", "scientificName", "One.Reason")]
#'
#' # homonyms of "Acacia albida": with the default settings, authors are not used
#' aa <- data.frame(spec.name = "Acacia albida", Authorship = c("Delile", "Lindl."))
#' m2 <- WFO.match(aa, WFO.data = WFO.example2026)
#' WFO.one(m2)[, c("Authorship", "scientificName", "scientificNameAuthorship", "One.Reason")]
#'
#' ## ---- non-default settings, marked "non-default" ----
#' # the authors decide between homonyms
#' o <- WFO.one(m2, Old.author.dist = "Old.author.dist")      # non-default
#' o[, c("Authorship", "scientificName")]
#'
#' # unmatched names keep the submitted name
#' o <- WFO.one(m, spec.name = "spec.name")                   # non-default
#' o[, c("spec.name", "scientificName", "One.Reason")]
WFO.one <- function(
    WFO.result=NULL, priority="Accepted",
    spec.name=NULL, Auth.dist=NULL, Old.author.dist=NULL, First.dist=NULL,
    verbose=TRUE, counter=1000
)
{
  if (!priority %in% c("Accepted", "Synonym")) stop("Priority should either be 'Accepted' or 'Synonym'")
  WFO.result <- as.data.frame(WFO.result)
  n <- nrow(WFO.result)
  WFO.result$One.Reason <- rep("", n)
  if (n == 0) return(WFO.result)

  msg <- function(...) if (verbose) message(...)
  num <- function(x) suppressWarnings(as.numeric(x))
  has.col <- function(v) length(v) > 0 && v %in% names(WFO.result)

  accepted.select <- function(d) d[d[, "taxonomicStatus"] %in% c("Accepted", "ACCEPTED"), , drop = FALSE]
  synonym.select <- function(d) d[d[, "New.accepted"] %in% FALSE, , drop = FALSE]
  smallID.select <- function(d) {
    if (verbose) message("Smallest ID candidates for ", d[1, "OriSeq"], " were: ",
                         paste(sort(as.character(d[, "scientificName"])), collapse = ", "))
    d[which.min(as.numeric(gsub("[^0-9]", "", x = d[, "taxonID"]))), , drop = FALSE]
  }

  ## Choose one candidate within a group (same decision sequence as WorldFlora)
  choose <- function(case) {
    reason <- ""
    case2 <- case
    os <- case[1, "OriSeq"]
    msg("Different candidates for original record # ", os, ", including ", case[1, "scientificName"])

    if (has.col(Old.author.dist)) {
      # synonym matches first (WorldFlora 1.14-4)
      na <- case$New.accepted %in% TRUE
      min.dist <- suppressWarnings(min(num(case[na, Old.author.dist]), na.rm = TRUE))
      min.nosyn <- if (has.col(Auth.dist)) suppressWarnings(min(num(case[!na, Auth.dist]), na.rm = TRUE)) else Inf
      if (!is.na(min.dist) && min.dist != Inf && min.dist < min.nosyn) {
        reason <- "Authorship best match for synonym"
        case2 <- case[which(num(case[, Old.author.dist]) == min.dist), , drop = FALSE]
        if (nrow(case2) == 1) msg("Found unique best Authorship match case for record # ", os)
        case <- case2
      }
    }
    if (has.col(Auth.dist) && nrow(case) > 1) {
      cur <- case$New.accepted %in% FALSE
      min.dist <- suppressWarnings(min(num(case[cur, Auth.dist]), na.rm = TRUE))
      if (!is.na(min.dist) && min.dist != Inf) {
        reason <- "Authorship best match"
        # WorldFlora <= 1.14-5 indexed all candidates with a logical vector computed on
        # the current-name candidates only (recycled when lengths differ)
        case2 <- case[which(cur & num(case[, Auth.dist]) == min.dist), , drop = FALSE]
        if (nrow(case2) == 1) msg("Found unique best Authorship match case for record # ", os)
        case <- case2
      }
    }
    if (has.col(First.dist) && nrow(case) > 1) {
      min.dist <- min(num(case[, First.dist]), na.rm = TRUE)
      if (!is.na(min.dist)) {
        reason <- "First distance best match"
        case2 <- case[which(num(case[, First.dist]) == min.dist), , drop = FALSE]
        if (nrow(case2) == 1) msg("Found unique best first distance match case for record # ", os)
        case <- case2
      }
    }
    if (nrow(case) > 1) {
      first <- if (priority == "Accepted") accepted.select else synonym.select
      second <- if (priority == "Accepted") synonym.select else accepted.select
      lab1 <- if (priority == "Accepted") "Accepted" else "Not a synonym"
      lab2 <- if (priority == "Accepted") "Not a synonym" else "Accepted"
      case1 <- first(case)
      if (nrow(case1) == 1) {
        reason <- lab1
        case2 <- case1
      } else {
        case2 <- second(if (nrow(case1) > 1) case1 else case)
        reason <- lab2
        if (nrow(case2) == 0) case2 <- case
      }
      if (nrow(case2) == 1) msg("Found unique ", tolower(reason), " case for record # ", os)
    }
    if (nrow(case2) == 0) case2 <- case
    if (nrow(case2) > 1) {
      case2 <- smallID.select(case2)
      msg("Selected record with smallest ID for record # ", os)
      reason <- "smallest ID"
    }
    list(subseq = case2[1, "Subseq"], reason = reason)
  }

  groups <- split(seq_len(n), WFO.result$OriSeq)
  groups <- groups[lengths(groups) > 1]
  drop <- integer(0)
  for (i in seq_along(groups)) {
    if (i %% counter == 0) message("Reached case # ", i)
    g <- groups[[i]]
    ch <- choose(WFO.result[g, , drop = FALSE])
    keep <- g[WFO.result$Subseq[g] == ch$subseq]
    WFO.result$One.Reason[keep] <- ch$reason
    drop <- c(drop, setdiff(g, keep))
  }
  WFO.new <- if (length(drop)) WFO.result[-drop, , drop = FALSE] else WFO.result
  ## guarantee: each submitted record (OriSeq) exactly once, in the order of WFO.result
  if (nrow(WFO.new) != length(unique(WFO.result$OriSeq)) || anyDuplicated(WFO.new$OriSeq) > 0) {
    stop("WFO.one() did not obtain one row per submitted record (", nrow(WFO.new), " rows for ",
         length(unique(WFO.result$OriSeq)), " records); please report this with the names concerned.",
         call. = FALSE)
  }

  if (!is.null(spec.name)) {
    sn <- as.character(WFO.new$scientificName)
    empty <- is.na(sn) | sn == ""
    sn[empty] <- as.character(WFO.new[empty, spec.name])
    WFO.new$scientificName <- sn
    WFO.new$One.Reason[empty] <- "no match found"
  }
  WFO.new
}
