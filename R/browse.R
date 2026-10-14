# ----------------------------------------------------------------------------
# browse.R: WFO.browse(), WFO.synonyms(), WFO.family(), WFO.url()
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - All four functions, their arguments and results; the vascular.families
#       table used by WFO.family().
#   Changed:
#     - Ranks are compared in both WFO conventions (up to 2025 and from
#       2026-06), via .rank.key().
#     - WFO.browse(): accepted names of listed synonyms in one lookup
#       (.accepted.names()) instead of a backbone scan per row.
#     - WFO.family(): no list of bryophyte families in the code; families not in
#       vascular.families give a warning (WorldFlora: "bryophytes", or no
#       warning because of is.null() on a data.frame; NEWS 13).
#     - WFO.url(): works for data.tables and tibbles (NEWS 15).
#   New in WorldFloraFast:
#     - Documentation of the equivalent data.table queries; .accepted.names(),
#       .vascular.families().
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

#' Browse the taxonomic backbone: lower taxa, synonyms, family and order, web
#' links
#'
#' `WFO.browse()` lists the genera of a family, the species of a genus or the
#' infraspecific taxa of a species. `WFO.synonyms()` lists the synonyms of the
#' accepted name of a taxon. `WFO.family()` gives the order and higher
#' classification of the family of a taxon. `WFO.url()` gives the World Flora
#' Online web pages of matched names.
#'
#' @param taxon Name of one taxon (matched first with [WFO.match()] and
#'   [WFO.one()]). For `WFO.browse()`, `NULL` lists all families.
#' @inheritParams WFO.match
#' @param accepted.only If `TRUE`, list accepted names only.
#' @param acceptedNameUsageID.match If `TRUE` (and `accepted.only = FALSE`), add
#'   column `New.name` with the accepted name of each listed synonym.
#' @param WFO.result Results of [WFO.match()] or [WFO.one()] (or a vector of
#'   `taxonID`s).
#' @param browse If `TRUE`, open the pages of rows `browse.rows` in a web
#'   browser.
#' @param browse.rows Rows of `WFO.result` to open.
#' @param ... Further arguments for [WFO.match()] (`WFO.browse()`,
#'   `WFO.synonyms()`, `WFO.family()`) or [utils::browseURL()] (`WFO.url()`).
#'
#' @details These functions are kept from WorldFlora, so that code written for
#' WorldFlora (and its graphical interface, RcmdrPlugin.WorldFlora) keeps
#' working. With the backbone loaded as a data.table, the same results are
#' simple queries; what the functions add is:
#' \itemize{
#'   \item the submitted taxon is first matched with [WFO.match()] and
#'     [WFO.one()], so misspelled names and synonyms are accepted;
#'   \item ranks are compared in both the WFO conventions up to 2025 and from
#'   2026-06 on;
#'   \item `WFO.browse()` adds the accepted name of listed synonyms
#'   (`New.name`);
#'   \item `WFO.family()` adds the order and higher classification of
#'     [vascular.families], which the backbone does not contain.
#' } Equivalent queries, for a backbone `W` read with [WFO.read()] and a
#' correctly spelled accepted name:
#' \preformatted{
#' # WFO.synonyms("Gambeya boiviniana")
#' id <- W[scientificName == "Gambeya boiviniana", taxonID]
#' W[taxonID == id | acceptedNameUsageID == id]
#'
#' # WFO.browse("Gambeya"): species of a genus
#' W[genus == "Gambeya" & tolower(taxonRank) == "species"]
#'
#' # WFO.browse("Gambeya boiviniana"): infraspecific taxa of a species
#' W[genus == "Gambeya" & specificEpithet == "boiviniana" &
#'     infraspecificEpithet != ""]
#'
#' # WFO.browse("Sapotaceae"): genera of a family
#' W[family == "Sapotaceae" & tolower(taxonRank) == "genus"]
#'
#' # WFO.family("Gambeya boiviniana")
#' vascular.families[vascular.families$Family ==
#'                   W[scientificName == "Gambeya boiviniana", family], ]
#'
#' # WFO.url()
#' paste0("http://worldfloraonline.org/taxon/", W$taxonID[1])
#' }
#'
#' @return `WFO.browse()` and `WFO.synonyms()`: a data.table with columns
#'   `taxonID`, `scientificName`, `scientificNameAuthorship`, `taxonRank`,
#'   `taxonomicStatus`, `acceptedNameUsageID` (and `New.name`), or `NULL` when
#'   nothing is found. For an order, `WFO.browse()` returns the matching rows of
#'   [vascular.families].
#'
#'   `WFO.family()`: the row of [vascular.families] for the family; an empty
#'   data.frame, with a warning, for families that are not in this table, such
#'   as those of bryophytes (WorldFlora returned `"bryophytes"` for families in
#'   a list kept in its code).
#'
#'   `WFO.url()`: a character vector of web addresses, as in WorldFlora
#'   ("http://worldfloraonline.org/taxon/<taxonID>"; `NA` for unmatched
#'   records).
#' @seealso [WFO.match()], [vascular.families]
#' @export
#' @examples
#' data(WFO.example2026) # small extract of the WFO Plant List 2026-06
#' WFO.synonyms("Gambeya boiviniana",
#'   WFO.data = WFO.example2026,
#'   verbose = FALSE
#' )
#' # varieties of a species
#' WFO.browse("Gambeya boiviniana",
#'   WFO.data = WFO.example2026,
#'   verbose = FALSE
#' )
#' # genera of a family
#' WFO.browse("Sapotaceae", WFO.data = WFO.example2026, verbose = FALSE)
#' WFO.family("Gambeya boiviniana", WFO.data = WFO.example2026, verbose = FALSE)
#' WFO.url(WFO.match("Faidherbia albida",
#'   WFO.data = WFO.example2026,
#'   verbose = FALSE
#' ))
#' \dontrun{
#' WFO.remember() # backbone downloaded with WFO.download()
#' WFO.browse("Fabaceae", WFO.data = WFO.data, accepted.only = TRUE)
#' }
WFO.browse <- function(
  taxon = NULL, WFO.file = NULL, WFO.data = NULL,
  accepted.only = FALSE, acceptedNameUsageID.match = TRUE, ...
) {
  WFO.data <- .read.WFO(WFO.file, WFO.data)
  rank.of <- function(x) tolower(as.character(x))
  species.ranks <- c("species", "nothospecies")

  if (is.null(taxon)) {
    result <- WFO.data[rank.of(WFO.data$taxonRank) == "family", ]
    result <- result[order(result$scientificName),
      .browse.columns,
      with = FALSE
    ]
    cat("Results are a list of all families\n")
  } else {
    found <- WFO.one(WFO.match(
      taxon,
      WFO.file = NULL,
      WFO.data = WFO.data,
      ...
    ))
    if (nrow(found) == 0) stop("no matches found")
    rank.found <- rank.of(found$taxonRank)
    cat("Submitted name ", taxon, " was matched with: ", found$scientificName,
      " of taxonRank: ", found$taxonRank, "\n",
      sep = ""
    )

    if (rank.found %in% species.ranks) {
      rows <- WFO.data$genus == found$genus &
        WFO.data$specificEpithet == found$specificEpithet &
        # infraspecific rows: rank other than species (WFO <= 2025: ""; 2026-06:
        # "species")
        !(.rank.key(WFO.data$verbatimTaxonRank) %in% "")
    } else if (rank.found == "genus") {
      rows <- WFO.data$genus == found$scientificName &
        rank.of(WFO.data$taxonRank) %in% species.ranks
    } else if (rank.found == "family") {
      rows <- WFO.data$family == found$scientificName &
        rank.of(WFO.data$taxonRank) == "genus"
    } else if (rank.found == "order") {
      families <- .vascular.families()
      return(families[families$Order == found$scientificName, ])
    } else {
      stop("Listings are only provided for families, genera and species")
    }
    result <- WFO.data[rows %in% TRUE, ]
    result <- result[order(result$scientificName),
      .browse.columns,
      with = FALSE
    ]
  }

  if (nrow(result) == 0) {
    message("No taxa at the next level")
    return(NULL)
  }
  if (accepted.only) {
    result <- result[result$taxonomicStatus %in% c("Accepted", "ACCEPTED"), ]
  } else if (acceptedNameUsageID.match) {
    result$New.name <- .accepted.names(result$acceptedNameUsageID, WFO.data)
  }
  result
}

# Accepted names for a vector of acceptedNameUsageID ("" when missing, unknown
# or ambiguous)
.accepted.names <- function(usage, WFO.data) {
  usage <- as.character(usage)
  usage[is.na(usage)] <- ""
  index <- .build.index(WFO.data$taxonID)
  id <- match(usage, index$u)
  n.found <- ifelse(is.na(id), 0L, index$cnt[id])
  n.found[usage == ""] <- NA
  if (any(n.found %in% 0)) {
    warning(sum(n.found %in% 0), " acceptedNameUsageID(s) without data, e.g. ",
      usage[which(n.found %in% 0)[1]],
      call. = FALSE
    )
  }
  if (any(n.found > 1, na.rm = TRUE)) {
    warning(
      sum(n.found > 1, na.rm = TRUE),
      " acceptedNameUsageID(s) with more than 1 row of matches",
      call. = FALSE
    )
  }
  out <- rep("", length(usage))
  ok <- n.found %in% 1
  first_row <- index$ord[index$start[id[ok]]]
  out[ok] <- as.character(WFO.data$scientificName[first_row])
  out
}

#' @rdname WFO.browse
#' @export
WFO.synonyms <- function(
  taxon = NULL, WFO.file = NULL, WFO.data = NULL, ...
) {
  WFO.data <- .read.WFO(WFO.file, WFO.data)
  found <- WFO.one(WFO.match(taxon, WFO.file = NULL, WFO.data = WFO.data, ...))
  if (nrow(found) == 0 || found$taxonID[1] == "") {
    message("no matches found")
    return(NULL)
  }
  found <- data.table::as.data.table(found)[, .browse.columns, with = FALSE]
  syn <- WFO.data[WFO.data$acceptedNameUsageID == found$taxonID, ]
  syn <- syn[order(syn$scientificName), .browse.columns, with = FALSE]
  rbind(found, syn)
}

#' @rdname WFO.browse
#' @export
WFO.family <- function(
  taxon = NULL, WFO.file = NULL, WFO.data = NULL, ...
) {
  WFO.data <- .read.WFO(WFO.file, WFO.data)
  found <- WFO.one(WFO.match(taxon, WFO.file = NULL, WFO.data = WFO.data, ...))
  if (nrow(found) == 0) stop("no matches found")
  message(
    "Submitted name ", taxon, " was matched with: ", found$scientificName,
    " of family: ", found$family
  )
  families <- .vascular.families()
  family.match <- families[families$Family %in% found$family, ]
  if (nrow(family.match) == 0) {
    # WorldFlora returned "bryophytes" from a list of bryophyte families kept in
    # its code; the major group is now only taken from the backbone itself, when
    # it has one
    group <- if ("majorGroup" %in% names(found)) {
      as.character(found$majorGroup)
    } else {
      ""
    }
    warning(
      "Family ",
      found$family,
      " is not in vascular.families (which covers vascular plants only)",
      if (!is.na(group) && group != "") {
        paste0(
          "; majorGroup in the backbone: ",
          group
        )
      },
      call. = FALSE
    )
  }
  family.match
}

# The vascular.families data set of this package
.vascular.families <- function() {
  env <- new.env()
  utils::data("vascular.families", package = "WorldFloraFast", envir = env)
  env$vascular.families
}

#' @rdname WFO.browse
#' @export
WFO.url <- function(
  WFO.result = NULL, browse = FALSE, browse.rows = c(1:1), ...
) {
  # WorldFlora failed for data.tables and tibbles (class() of length > 1)
  ids <- if (is.data.frame(WFO.result)) WFO.result[["taxonID"]] else WFO.result
  ids <- as.character(ids)
  result <- ifelse(is.na(ids) | ids == "", NA_character_,
    paste0("http://worldfloraonline.org/taxon/", ids)
  )
  if (browse) {
    for (i in browse.rows) {
      if (!is.na(result[i])) utils::browseURL(url = result[i], ...)
    }
  }
  result
}
