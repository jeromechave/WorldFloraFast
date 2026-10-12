## --------------------------------------------------------------------------------------
## acceptable.R: checks whether fuzzy matches are explained by misspellings
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - The replacement rules (gender endings, hyphen, hybrid sign, i/j, double letters,
##       dt/d, optional removal of vowels), from WFO.acceptable.match().
##     - WFO.acceptable.match(): same arguments and results.
##   Changed:
##     - WFO.acceptable.match() is deprecated and now calls WFO.spelling.check().
##     - The hybrid sign is removed with a following space (WFO 2026-06 notation).
##   New in WorldFloraFast:
##     - WFO.spelling.check(): classifies each row as "identical", "spelling corrected"
##       or "other difference" instead of TRUE/FALSE.
##     - The rules are kept in a table (.misspelling.rules) instead of a sequence of
##       statements.
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

#' Check whether fuzzy matches are explained by misspellings
#'
#' A name has one correct spelling, the one in the taxonomic backbone. When [WFO.match()]
#' finds a name by fuzzy matching, the submitted spelling differs from the correct one.
#' `WFO.spelling.check()` tells whether the difference is explained by common misspellings
#' that do not change which name was meant (so that the correction made by fuzzy matching
#' can be trusted), or whether the names differ in other ways (so that the match should be
#' checked: it may be a different name).
#'
#' @param x Results of [WFO.match()] or [WFO.one()].
#' @param spec.name Name of the column with the submitted names.
#' @param no.vowels If `TRUE`, also treat differences in vowels as misspellings.
#'
#' @details The submitted name is compared with the matched name; for synonyms replaced by
#' their accepted names, with the synonym that was matched (`Old.name`). Both are first put
#' in a form where these common misspellings disappear (examples from the WFO):
#' \itemize{
#'   \item wrong gender of the epithet: endings -um and -us become -a, and -is becomes -e
#'     (Decarydendron ranomafanensis for *Decarydendron ranomafanense*);
#'   \item a missing or extra hyphen (the first one) or hybrid sign (Sorbus avonensis for
#'     *Sorbus* × *avonensis*);
#'   \item i written as j, or ii as i (Syzygium naiadum for *Syzygium najadum*);
#'   \item single and double letters confused (tt, ll, rr, mm, nn, ff, hh, dd; Ficus
#'     scott-elliottii for *Ficus scott-elliotii*), and dt for d (Stadtmannia for
#'     *Stadmania*);
#'   \item with `no.vowels = TRUE`, any vowel (including y).
#' }
#'
#' @return A character vector with one value per row of `x`:
#' \describe{
#'   \item{"identical"}{the submitted name is spelled as in the backbone;}
#'   \item{"spelling corrected"}{the names differ only by the misspellings listed above;}
#'   \item{"other difference"}{the names differ in other ways: check the match;}
#'   \item{NA}{no name was matched.}
#' }
#' @seealso [WFO.match()]
#' @export
#' @examples
#' x <- data.frame(spec.name = c("Ficus scott-elliotii", "Ficus scott-elliottii",
#'                               "Coffea arabicus", "Acacia nilotica", "Xx yy"),
#'                 scientificName = c("Ficus scott-elliotii", "Ficus scott-elliotii",
#'                                    "Coffea arabica", "Acacia senegal", NA),
#'                 New.accepted = FALSE, Old.name = "")
#' WFO.spelling.check(x)
#'
#' data(WFO.example2026)
#' m <- WFO.match(c("Faidherbia albida", "Faidherbia albidum", "Pygeum afric"),
#'                WFO.data = WFO.example2026, verbose = FALSE)
#' cbind(m[, c("spec.name", "Fuzzy", "Old.name", "scientificName")],
#'       spelling = WFO.spelling.check(m))
WFO.spelling.check <- function(
    x, spec.name = "spec.name",
    no.vowels = FALSE
)
{
  submitted <- .hybrid.key(as.character(x[[spec.name]]))
  matched <- as.character(x$scientificName)
  syn <- x$New.accepted %in% TRUE
  matched[syn] <- as.character(x$Old.name[syn])
  matched <- .hybrid.key(matched)
  out <- ifelse(submitted == matched, "identical",
         ifelse(.misspelling.normalise(submitted, no.vowels) == .misspelling.normalise(matched, no.vowels),
                "spelling corrected", "other difference"))
  out[is.na(matched) | matched == ""] <- NA
  out
}

#' Deprecated: use WFO.spelling.check()
#'
#' `WFO.acceptable.match()` (from WorldFlora) returns `TRUE` when the submitted and matched
#' names are identical or differ only by common misspellings, i.e. when
#' [WFO.spelling.check()] gives "identical" or "spelling corrected". It is kept for
#' compatibility and will be removed in a later version.
#'
#' @inheritParams WFO.spelling.check
#' @return A logical vector (`NA` where no name was matched).
#' @export
#' @keywords internal
WFO.acceptable.match <- function(x, spec.name = "spec.name", no.vowels = FALSE)
{
  .Deprecated("WFO.spelling.check", package = "WorldFloraFast")
  r <- WFO.spelling.check(x, spec.name = spec.name, no.vowels = no.vowels)
  ifelse(is.na(r), NA, r %in% c("identical", "spelling corrected"))
}

## Common misspellings, removed in this order from both names; all = FALSE replaces the
## first occurrence only (stringr::str_replace), as in WorldFlora.
.misspelling.rules <- data.frame(
  pattern = c("um$", "us$", "is$", "-", paste0(intToUtf8(215), " ?"),
              "j", "ii", "tt", "ll", "rr", "mm", "nn", "ff", "hh", "dd", "dt"),
  replacement = c("a", "a", "e", "", "",
                  "i", "i", "t", "l", "r", "m", "n", "f", "h", "d", "d"),
  all = c(rep(FALSE, 5), rep(TRUE, 11)),
  stringsAsFactors = FALSE)

.misspelling.normalise <- function(s, no.vowels = FALSE) {
  for (i in seq_len(nrow(.misspelling.rules))) {
    f <- if (.misspelling.rules$all[i]) stringr::str_replace_all else stringr::str_replace
    s <- f(s, pattern = .misspelling.rules$pattern[i], replacement = .misspelling.rules$replacement[i])
  }
  if (no.vowels) s <- stringr::str_replace_all(s, pattern = "[aeiouy]", replacement = "")
  s
}
