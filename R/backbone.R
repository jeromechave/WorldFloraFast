## --------------------------------------------------------------------------------------
## backbone.R: new.backbone(), use of another taxonomic list as backbone
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - new.backbone(): arguments, columns of the result, conversion to character,
##       emptying of self-referencing acceptedNameUsageID.
##   Changed:
##     - Self-referencing IDs are emptied before the status is derived, so these records
##       are "Accepted" (WorldFlora: "Synonym"; NEWS 14).
##     - Missing acceptedNameUsageID values become "" (WorldFlora: error; NEWS 14).
##     - A single extra column keeps its name (drop = FALSE; NEWS 14); column names are
##       not altered by data.frame().
##   New in WorldFloraFast:
##     - Documentation and example.
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

#' Use another taxonomic backbone
#'
#' Converts a taxonomic list (for example the World Checklist of Vascular Plants, or a
#' list for another group of organisms) into a backbone that [WFO.match()], [WFO.one()]
#' and the other functions of this package can use instead of the World Flora Online.
#'
#' @param x A data.frame with the taxonomic list.
#' @param taxonID Name of the column with the identifiers of the names.
#' @param scientificName Name of the column with the full names (without authors).
#' @param scientificNameAuthorship Name of the column with the naming authors.
#' @param acceptedNameUsageID Name of the column with, for synonyms, the identifier
#'   (`taxonID`) of the accepted name; empty for accepted names. If `NULL`, all names are
#'   treated as accepted.
#' @param taxonomicStatus Name of the column with the status of the name (such as
#'   "Accepted" or "Synonym"). If `NULL`, names with an `acceptedNameUsageID` become
#'   "Synonym" and the others "Accepted".
#'
#' @details All columns are converted to character. Other columns of `x` are kept.
#'   An `acceptedNameUsageID` that refers to the record itself is emptied (with a message),
#'   as is a missing one.
#'
#' @return A data.table with the columns `taxonID`, `scientificName`,
#'   `scientificNameAuthorship`, `acceptedNameUsageID` and `taxonomicStatus`, followed by
#'   the other columns of `x`.
#' @references Kindt, R. (2021). Standardizing mammal species names with the Mammal
#'   Diversity Database via WorldFlora. <https://rpubs.com/Roeland-KINDT>
#' @export
#' @examples
#' x <- data.frame(id = c("A1", "A2", "A3"),
#'                 name = c("Felis catus", "Felis domesticus", "Panthera leo"),
#'                 author = c("Linnaeus, 1758", "Erxleben, 1777", "(Linnaeus, 1758)"),
#'                 accepted = c("", "A1", ""))
#' bb <- new.backbone(x, taxonID = "id", scientificName = "name",
#'                    scientificNameAuthorship = "author", acceptedNameUsageID = "accepted")
#' m <- WFO.match("Felis domestica", WFO.data = bb, verbose = FALSE)
#' m[, c("spec.name", "scientificName", "Old.name")]
new.backbone <- function(
    x,
    taxonID = "taxonID", scientificName = "scientificName",
    scientificNameAuthorship = "scientificNameAuthorship",
    acceptedNameUsageID = NULL, taxonomicStatus = NULL)
{
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  for (j in seq_along(x)) x[[j]] <- as.character(x[[j]])

  out <- data.frame(taxonID = x[[taxonID]],
                    scientificName = x[[scientificName]],
                    scientificNameAuthorship = x[[scientificNameAuthorship]],
                    stringsAsFactors = FALSE)
  out$acceptedNameUsageID <- if (is.null(acceptedNameUsageID)) rep("", nrow(out)) else x[[acceptedNameUsageID]]
  out$acceptedNameUsageID[is.na(out$acceptedNameUsageID)] <- ""
  ## self-referencing acceptedNameUsageID (since WorldFlora 1.14-1); emptied *before*
  ## deriving the status, so that such records are "Accepted" (WorldFlora: "Synonym")
  selfies <- out$taxonID == out$acceptedNameUsageID
  selfies[is.na(selfies)] <- FALSE
  if (any(selfies)) {
    message("Self-referencing was detected for ", sum(selfies),
            " records, so emptying acceptedNameUsageID for these.")
    out$acceptedNameUsageID[selfies] <- ""
  }
  if (is.null(taxonomicStatus)) {
    out$taxonomicStatus <- ifelse(out$acceptedNameUsageID != "", "Synonym", "Accepted")
  } else {
    out$taxonomicStatus <- x[[taxonomicStatus]]
  }


  standard <- c("taxonID", "scientificName", "scientificNameAuthorship", "acceptedNameUsageID", "taxonomicStatus")
  out <- data.table::data.table(out, x[, !names(x) %in% standard, drop = FALSE])

  out
}
