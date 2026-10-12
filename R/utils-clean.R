## --------------------------------------------------------------------------------------
## utils-clean.R: cleaning of submitted names
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - The cleaning steps, their order, and the columns <spec.name>.ORIG, Squished,
##       Brackets.detected and Number.detected (from WFO.match() and
##       WFO.match.fuzzyjoin(), where they were duplicated).
##   Changed:
##     - Vectorised: all records at once instead of a loop per record.
##     - tolower is applied to the squished name (NEWS 4).
##   New in WorldFloraFast:
##     - none
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

## Clean submitted names before matching (squish, tolower, sub.pattern, brackets, numbers,
## hybrid notation), in the order of WorldFlora, for all records at once. Adds the columns
## <spec.name>.ORIG, Squished, Brackets.detected and Number.detected.
.clean.spec.names <- function(spec.data, spec.name,
                              squish = TRUE, spec.name.tolower = FALSE, spec.name.sub = TRUE,
                              sub.pattern,
                              spec.name.nobrackets = TRUE, spec.name.nonumber = TRUE) {
  x <- as.character(spec.data[[spec.name]])
  x[is.na(x)] <- ""
  orig.name <- paste0(spec.name, ".ORIG")
  any.step <- squish || spec.name.tolower || spec.name.sub || spec.name.nobrackets || spec.name.nonumber
  if (any.step) spec.data[[orig.name]] <- x
  orig <- x

  if (squish) {
    x <- .squish(x)
    spec.data$Squished <- nchar(orig) > 0 & orig != x
  }
  if (spec.name.tolower) {
    # NOTE: previous versions lower-cased the ORIGINAL name, silently undoing squish
    x <- tolower(x)
    substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  }
  if (spec.name.sub) {
    for (p in sub.pattern) x <- gsub(pattern = p, replacement = "", x = x)
  }
  if (spec.name.nobrackets) {
    br <- grepl("(", x, fixed = TRUE)
    spec.data$Brackets.detected <- br
    if (any(br)) x[br] <- .squish(sub("[(].*$", "", x[br]))
  }
  if (spec.name.nonumber) {
    nb <- grepl("[[:digit:]]", x)
    spec.data$Number.detected <- nb
    if (any(nb)) x[nb] <- sub("[[:digit:]]+$", "", sub(" .*$", "", x[nb]))
  }
  hy <- grepl(" x ", x, fixed = TRUE)
  if (any(hy)) {
    message("pattern ' x ' was interpreted as hybrid notation and replaced by ' ", .HYBRID, "'")
    if (!any.step) spec.data[[orig.name]] <- x
    x[hy] <- gsub(" x ", paste0(" ", .HYBRID), x[hy], fixed = TRUE)
  }
  spec.data[[spec.name]] <- x
  spec.data
}
