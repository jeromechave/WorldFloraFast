# ----------------------------------------------------------------------------
# one.R: WFO.one(), one match per submitted name
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - WFO.one(): arguments, the sequence of criteria (Old.author.dist,
#       Auth.dist, First.dist, priority, smallest ID) and One.Reason.
#   Changed:
#     - Works per group of candidates instead of scanning and deleting rows of
#       the whole table.
#     - The authorship step no longer recycles a logical index computed on part
#       of the candidates (NEWS 9).
#     - Selections use which(), so NA distances cannot add empty rows; a group
#       can never disappear.
#     - Stops with an error if the result does not have each submitted record
#       exactly once (1.0.2).
#     - The choice is made once per distinct set of candidates and copied to the
#       records with the same candidates (1.0.8).
#   New in WorldFloraFast:
#     - none
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

#' Keep one match per submitted name
#'
#' Reduces the results of [WFO.match()] to one row per submitted name, choosing
#' among several candidates with a fixed sequence of criteria.
#'
#' @param WFO.result Results of [WFO.match()].
#' @param priority `"Accepted"`: prefer accepted names, then names that are not
#'   synonyms. `"Synonym"`: prefer names that were not synonyms, then accepted
#'   names.
#' @param spec.name Name of the column with the submitted names. If given,
#'   submitted names without a match are copied to `scientificName` (with
#'   `One.Reason` "no match found").
#' @param Auth.dist Name of the column with the distance between submitted and
#'   matched authors (usually `"Auth.dist"`); if given, candidates with the
#'   closest authors are preferred.
#' @param Old.author.dist Name of the column with the distance between submitted
#'   authors and those of replaced synonyms (usually `"Old.author.dist"`); if
#'   given, synonym candidates with closer authors than any current-name
#'   candidate are preferred first.
#' @param First.dist Name of the column with the distance between first words
#'   (usually `"First.dist"`); if given, candidates with the closest genus are
#'   preferred.
#' @param verbose If `TRUE`, report the choices made.
#' @param counter Progress is reported every `counter` submitted names with
#'   several candidates.
#'
#' @details For each submitted name with several candidates, the criteria are
#' applied in this order, each only while several candidates remain: authorship
#' of synonyms (`Old.author.dist`), authorship of current names (`Auth.dist`),
#' genus distance (`First.dist`), `priority`, and finally the smallest numeric
#' part of `taxonID`. Column `One.Reason` gives the criterion that decided.
#'
#' Records with the same candidates (the same candidate rows, with the same
#' values of the columns used by these criteria) get the same choice. The
#' choice is therefore made once per distinct set of candidates and copied to
#' the other records, which makes large inventories with repeated names much
#' faster (113,432 records: 3.7 s in 1.0.7, 0.2 s). The result is unchanged:
#' one row per submitted record. With `verbose = TRUE`, messages are given
#' once per distinct set of candidates.
#'
#' Unlike WorldFlora 1.14-5, the authorship step compares the candidates that
#' were not replaced by accepted names, rather than a recycled selection of all
#' candidates; the chosen records were the same in our comparisons, but
#' `One.Reason` can differ.
#'
#' @return `WFO.result` with one row per submitted name, and column
#'   `One.Reason`.
#' @seealso [WFO.match()]
#' @export
#' @examples
#' data(WFO.example2026)
#' m <- WFO.match(c("Omalanthus populneus", "World agroforestry"),
#'   WFO.data = WFO.example2026,
#'   Fuzzy.min = FALSE
#' ) # non-default (of WFO.match): all fuzzy candidates
#' nrow(m) # several candidates for the first name
#'
#' ## ---- default settings (those of WorldFlora) ----
#' WFO.one(m)[, c("spec.name", "scientificName", "One.Reason")]
#'
#' # homonyms of "Acacia albida": with the default settings, authors are not
#' # used
#' aa <- data.frame(
#'   spec.name = "Acacia albida",
#'   Authorship = c("Delile", "Lindl.")
#' )
#' m2 <- WFO.match(aa, WFO.data = WFO.example2026)
#' WFO.one(m2)[, c(
#'   "Authorship", "scientificName", "scientificNameAuthorship",
#'   "One.Reason"
#' )]
#'
#' ## ---- non-default settings, marked "non-default" ----
#' # the authors decide between homonyms
#' o <- WFO.one(m2, Old.author.dist = "Old.author.dist") # non-default
#' o[, c("Authorship", "scientificName")]
#'
#' # unmatched names keep the submitted name
#' o <- WFO.one(m, spec.name = "spec.name") # non-default
#' o[, c("spec.name", "scientificName", "One.Reason")]
WFO.one <- function(
  WFO.result = NULL, priority = "Accepted",
  spec.name = NULL, Auth.dist = NULL, Old.author.dist = NULL, First.dist = NULL,
  verbose = TRUE, counter = 1000
) {
  if (!priority %in% c(
    "Accepted",
    "Synonym"
  )) {
    stop("Priority should either be 'Accepted' or 'Synonym'")
  }
  WFO.result <- as.data.frame(WFO.result)
  n <- nrow(WFO.result)
  WFO.result$One.Reason <- rep("", n)
  if (n == 0) {
    return(WFO.result)
  }

  msg <- function(...) if (verbose) message(...)
  num <- function(x) suppressWarnings(as.numeric(x))
  has.col <- function(v) length(v) > 0 && v %in% names(WFO.result)

  accepted.select <- function(d) {
    d[d[, "taxonomicStatus"] %in% c(
      "Accepted",
      "ACCEPTED"
    ), , drop = FALSE]
  }
  synonym.select <- function(d) {
    d[d[, "New.accepted"] %in% FALSE, ,
      drop = FALSE
    ]
  }
  smallest.id.select <- function(d) {
    if (verbose) {
      message(
        "Smallest ID candidates for ", d[1, "OriSeq"], " were: ",
        paste(sort(as.character(d[, "scientificName"])), collapse = ", ")
      )
    }
    d[which.min(as.numeric(gsub(
      "[^0-9]",
      "",
      x = d[, "taxonID"]
    ))), , drop = FALSE]
  }

  # Choose one candidate within a group (same decision sequence as WorldFlora)
  choose <- function(case) {
    reason <- ""
    case2 <- case
    os <- case[1, "OriSeq"]
    msg(
      "Different candidates for original record # ",
      os,
      ", including ",
      case[1, "scientificName"]
    )

    if (has.col(Old.author.dist)) {
      # synonym matches first (WorldFlora 1.14-4)
      na <- case$New.accepted %in% TRUE
      min.dist <- suppressWarnings(min(
        num(case[na, Old.author.dist]),
        na.rm = TRUE
      ))
      min.nosyn <- if (has.col(Auth.dist)) {
        suppressWarnings(min(
          num(case[!na, Auth.dist]),
          na.rm = TRUE
        ))
      } else {
        Inf
      }
      if (!is.na(min.dist) && min.dist != Inf && min.dist < min.nosyn) {
        reason <- "Authorship best match for synonym"
        case2 <- case[which(num(case[, Old.author.dist]) == min.dist), ,
          drop = FALSE
        ]
        if (nrow(case2) == 1) {
          msg(
            "Found unique best Authorship match case for record # ",
            os
          )
        }
        case <- case2
      }
    }
    if (has.col(Auth.dist) && nrow(case) > 1) {
      cur <- case$New.accepted %in% FALSE
      min.dist <- suppressWarnings(min(num(case[cur, Auth.dist]), na.rm = TRUE))
      if (!is.na(min.dist) && min.dist != Inf) {
        reason <- "Authorship best match"
        # WorldFlora <= 1.14-5 indexed all candidates with a logical vector
        # computed on the current-name candidates only (recycled when lengths
        # differ)
        case2 <- case[which(cur & num(case[, Auth.dist]) == min.dist), ,
          drop = FALSE
        ]
        if (nrow(case2) == 1) {
          msg(
            "Found unique best Authorship match case for record # ",
            os
          )
        }
        case <- case2
      }
    }
    if (has.col(First.dist) && nrow(case) > 1) {
      min.dist <- min(num(case[, First.dist]), na.rm = TRUE)
      if (!is.na(min.dist)) {
        reason <- "First distance best match"
        case2 <- case[which(num(case[, First.dist]) == min.dist), ,
          drop = FALSE
        ]
        if (nrow(case2) == 1) {
          msg(
            "Found unique best first distance match case for record # ",
            os
          )
        }
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
      if (nrow(case2) == 1) {
        msg(
          "Found unique ",
          tolower(reason),
          " case for record # ",
          os
        )
      }
    }
    if (nrow(case2) == 0) case2 <- case
    if (nrow(case2) > 1) {
      case2 <- smallest.id.select(case2)
      msg("Selected record with smallest ID for record # ", os)
      reason <- "smallest ID"
    }
    list(subseq = case2[1, "Subseq"], reason = reason)
  }

  groups <- split(seq_len(n), WFO.result$OriSeq)
  groups <- groups[lengths(groups) > 1]
  drop <- integer(0)
  if (length(groups) > 0) {
    # Records with the same candidates (the same rows, in the same order, with
    # the same values of the columns that decide the choice) get the same
    # choice, so choose() runs once per distinct set of candidates and its
    # choice is copied to the other records (large inventories repeat names).
    cols <- intersect(c(
      "taxonID", "Subseq", "New.accepted", "taxonomicStatus",
      if (has.col(Old.author.dist)) Old.author.dist,
      if (has.col(Auth.dist)) Auth.dist,
      if (has.col(First.dist)) First.dist
    ), names(WFO.result))
    rows <- unlist(groups, use.names = FALSE)
    size <- lengths(groups)
    row.key <- do.call(paste, c(lapply(cols, function(v) {
      as.character(WFO.result[[v]][rows])
    }), sep = "\r"))
    key <- vapply(split(row.key, rep(seq_along(groups), size)), paste, "",
      collapse = "\n"
    )
    distinct <- which(!duplicated(key))
    pos <- integer(length(distinct))
    reason <- character(length(distinct))
    for (j in seq_along(distinct)) {
      if (j %% counter == 0) message("Reached case # ", j)
      g <- groups[[distinct[j]]]
      ch <- choose(WFO.result[g, , drop = FALSE])
      pos[j] <- match(ch$subseq, WFO.result$Subseq[g])
      reason[j] <- ch$reason
    }
    same <- match(key, key[distinct])
    keep <- rows[cumsum(c(0, size[-length(size)])) + pos[same]]
    WFO.result$One.Reason[keep] <- reason[same]
    drop <- setdiff(rows, keep)
    if (length(distinct) < length(groups)) {
      msg(
        length(groups) - length(distinct), " of ", length(groups),
        " records had the same candidates as an earlier record and were",
        " resolved in the same way"
      )
    }
  }
  WFO.new <- if (length(drop)) WFO.result[-drop, , drop = FALSE] else WFO.result
  # guarantee: each submitted record (OriSeq) exactly once, in the order of
  # WFO.result
  one.per.record <- nrow(WFO.new) == length(unique(WFO.result$OriSeq)) &&
    anyDuplicated(WFO.new$OriSeq) == 0
  if (!one.per.record) {
    stop(
      "WFO.one() did not obtain one row per submitted record (",
      nrow(WFO.new),
      " rows for ",
      length(unique(WFO.result$OriSeq)),
      " records); please report this with the names concerned.",
      call. = FALSE
    )
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
