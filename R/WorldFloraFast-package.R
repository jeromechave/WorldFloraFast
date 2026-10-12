## --------------------------------------------------------------------------------------
## WorldFloraFast-package.R: package documentation
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - none
##   Changed:
##     - none
##   New in WorldFloraFast:
##     - The whole file: package help page, and .datatable.aware (data.table syntax
##       without importing data.table).
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

#' WorldFloraFast: fast standardization of plant names against the World Flora Online
#'
#' Matches plant names against a static copy of the World Flora Online (WFO) taxonomic
#' backbone, exactly or with fuzzy matching, and finds the currently accepted names.
#' WorldFloraFast is a faster, refactored derivative of the WorldFlora package (Kindt 2020);
#' functions and arguments are the same.
#'
#' @section Workflow:
#' \enumerate{
#'   \item Obtain the backbone with [WFO.download()] (later sessions: [WFO.remember()] or
#'     [WFO.read()]).
#'   \item Optionally split full names with authors via [WFO.prepare()].
#'   \item Match names with [WFO.match()].
#'   \item Keep one match per submitted name with [WFO.one()].
#'   \item Explore with [WFO.browse()], [WFO.synonyms()], [WFO.family()] and [WFO.url()];
#'     check whether fuzzy matches are explained by misspellings with [WFO.spelling.check()].
#' }
#' Other taxonomic lists can be used as backbone via [new.backbone()].
#'
#' @section Speed:
#' The backbone is indexed once per call, so that exact matches, accepted names and genera
#' are found with hash lookups. Fuzzy matching is done once per distinct name, optionally in
#' parallel (argument `cores`), and each [agrep()] search is preceded by an exact
#' prefilter (see [WFO.match()]). Results are those of WorldFlora 1.14-5, apart from the
#' corrections listed in the NEWS file (`news(package = "WorldFloraFast")`).
#'
#' @section Compatibility with WorldFlora:
#' By default, functions behave as in WorldFlora 1.14-5: same arguments, defaults, result
#' columns (names, order, types) and example data set. Only errors of WorldFlora are
#' corrected (listed in the NEWS file); in [WFO.match()], three of these corrections can be
#' switched off (`Fuzzy.keep.genus`, `Fuzzy.epithet.check`, `Fuzzy.skip.placeholder`). The
#' matching steps added by WorldFloraFast (`Fuzzy.genus`, `Fuzzy.transfer`,
#' `Fuzzy.one.strict`) are optional and switched off by default.
#'
#' @section Cache:
#' The index of the backbone and the context used by the matching steps (about 5 s to
#' build for the 1.6 million names of the WFO Plant List 2026-06) are kept for the last
#' backbone used, so that further calls with the same `WFO.data` take a fraction of a
#' second. This works when `WFO.data` is a data.table, as returned by [WFO.read()] (a
#' data.frame is copied at each call). A changed backbone is detected. Set
#' `options(WorldFloraFast.cache = FALSE)` to switch the cache off.
#'
#' @section Deprecated:
#' [WFO.match.fuzzyjoin()], [WFO.acceptable.match()] (replaced by [WFO.spelling.check()])
#' and the argument `no.dates` of [WFO.match()] still work, with a warning, and will be
#' removed in a later version.
#'
#' @section Provenance:
#' WorldFloraFast is derived from WorldFlora 1.14-5 (Roeland Kindt, GPL-3). Each R source
#' file of the package starts with a caption that lists what it inherits from WorldFlora,
#' what was changed, and what is new; the NEWS file lists all changes of results.
#'
#' @references
#' Kindt, R. (2020). WorldFlora: An R package for exact and fuzzy matching of plant names
#' against the World Flora Online taxonomic backbone data. Applications in Plant Sciences
#' 8(9): e11388. \doi{10.1002/aps3.11388}
#'
#' World Flora Online. An Online Flora of All Known Plants. <https://www.worldfloraonline.org>
#' @keywords internal
"_PACKAGE"

## data.table syntax (DT[i, j, with = FALSE]) is used without importing data.table
.datatable.aware <- TRUE
