#' Example subset of the World Flora Online taxonomic backbone (WorldFlora)
#'
#' The example data set of WorldFlora, unchanged: a small subset of an earlier release of the
#' World Flora Online taxonomic backbone. Kept so that code written for WorldFlora keeps
#' working; the examples of this package use [WFO.example2026], an extract of the WFO Plant
#' List 2026-06.
#'
#' @format A data.frame with 13 rows and the columns of the WFO backbone of that release
#'   (`taxonID`, `scientificName`, `scientificNameAuthorship`, `taxonRank`, `family`,
#'   `genus`, `specificEpithet`, `infraspecificEpithet`, `verbatimTaxonRank`,
#'   `taxonomicStatus`, `acceptedNameUsageID`, ...).
#' @source World Flora Online. <https://www.worldfloraonline.org>
#' @examples
#' data(WFO.example)
#' WFO.match("Faidherbia albida", WFO.data = WFO.example)$scientificName
"WFO.example"

## --------------------------------------------------------------------------------------
## data.R: documentation of the data sets
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - vascular.families and WFO.example: data and documentation unchanged.
##   Changed:
##     - none
##   New in WorldFloraFast:
##     - WFO.example2026: an extract of the WFO Plant List 2026-06 (48 rows, 12 columns),
##       used by the examples; documentation written for roxygen2.
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

#' Example subset of the World Flora Online taxonomic backbone (Plant List 2026-06)
#'
#' A small extract of the WFO Plant List 2026-06, used in the examples. It contains the
#' names of the examples, the edge cases discussed in [WFO.match()] (a truncated genus, a
#' species transferred to another genus, a local name) and every accepted name that these
#' names refer to. For real work, download the complete backbone with [WFO.download()].
#'
#' @format A data.frame with 48 rows and the 12 columns read by `WFO.read(core.only =
#'   TRUE)`: `taxonID`, `scientificName`, `scientificNameAuthorship`, `taxonRank`,
#'   `taxonomicStatus`, `nomenclaturalStatus`, `acceptedNameUsageID`, `family`, `genus`,
#'   `specificEpithet`, `verbatimTaxonRank` and `infraspecificEpithet`. As in the 2026-06
#'   release, ranks are written in full and in lower case ("species", "variety"), and
#'   hybrids as "Mentha × piperita".
#' @source The World Flora Online Consortium et al. (2026). World Flora Online Plant List
#'   June 2026. Zenodo. \doi{10.5281/zenodo.20782718}
#' @examples
#' data(WFO.example2026)
#' WFO.example2026[, c("scientificName", "taxonomicStatus", "acceptedNameUsageID")]
"WFO.example2026"

#' Orders and higher classification of vascular plant families
#'
#' Orders of the families of vascular plants (angiosperms, gymnosperms and pteridophytes).
#' For angiosperms, orders and higher levels of classification follow the fourth update of
#' the Angiosperm Phylogeny Group (APG IV, \doi{10.1111/boj.12385}); higher levels are the
#' names of nodes of the consensus tree (Figure 1 of APG IV). Orders of gymnosperms and
#' pteridophytes were obtained from the website of the Missouri Botanical Garden. Used by
#' [WFO.family()] and [WFO.browse()].
#'
#' @format A data.frame with 476 rows and 10 columns:
#' \describe{
#'   \item{Group}{Group.}
#'   \item{Family.ID}{Unique ID for each family; for angiosperms, as in APG IV.}
#'   \item{Family}{Name of the family.}
#'   \item{Family.taxonID}{taxonID in the World Flora Online.}
#'   \item{Order}{Name of the order.}
#'   \item{Order.taxonID}{taxonID in the World Flora Online.}
#'   \item{Node.1}{Name of the node in the consensus tree.}
#'   \item{Node.2}{Name of the node, nested within Node.1.}
#'   \item{Node.3}{Name of the node, nested within Node.2.}
#'   \item{Node.4}{Name of the node, nested within Node.3.}
#' }
#' @source The Angiosperm Phylogeny Group et al. (2016). An update of the Angiosperm
#'   Phylogeny Group classification for the orders and families of flowering plants:
#'   APG IV. Botanical Journal of the Linnean Society 181: 1-20. \doi{10.1111/boj.12385}
#' @examples
#' data(vascular.families)
#' head(vascular.families[, c("Family", "Order", "Node.1")])
"vascular.families"
