# ----------------------------------------------------------------------------
# utils-clean.R: cleaning of submitted names
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - The cleaning steps, their order, and the columns <spec.name>.ORIG,
#       Squished, Brackets.detected and Number.detected (from WFO.match() and
#       WFO.match.fuzzyjoin(), where they were duplicated).
#   Changed:
#     - Vectorised: all records at once instead of a loop per record.
#     - tolower is applied to the squished name (NEWS 4).
#   New in WorldFloraFast:
#     - .is.placeholder(): names made only of placeholder words (1.0.2).
#     - Morphospecies codes removed before cleaning (.drop.morphospecies());
#       names with aff. reduced to the genus on request (.has.aff()) (1.0.6).
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

# Clean submitted names before matching (squish, tolower, sub.pattern, brackets,
# numbers, hybrid notation), in the order of WorldFlora, for all records at
# once. Adds the columns <spec.name>.ORIG, Squished, Brackets.detected and
# Number.detected.
.clean.spec.names <- function(spec.data, spec.name,
                              squish = TRUE,
                              spec.name.tolower = FALSE,
                              spec.name.sub = TRUE,
                              sub.pattern,
                              spec.name.nobrackets = TRUE,
                              spec.name.nonumber = TRUE,
                              spec.name.aff.genus = FALSE) {
  x <- as.character(spec.data[[spec.name]])
  x[is.na(x)] <- ""
  orig.name <- paste0(spec.name, ".ORIG")
  any.step <- squish || spec.name.tolower || spec.name.sub ||
    spec.name.nobrackets || spec.name.nonumber
  if (any.step) spec.data[[orig.name]] <- x
  orig <- x

  if (squish) {
    x <- .squish(x)
    spec.data$Squished <- nchar(orig) > 0 & orig != x
  }
  if (spec.name.tolower) {
    # NOTE: previous versions lower-cased the ORIGINAL name, silently undoing
    # squish
    x <- tolower(x)
    substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  }
  if (spec.name.aff.genus) {
    af <- .has.aff(x)
    if (any(af)) x[af] <- sub(" .*$", "", x[af])
  }
  if (spec.name.nonumber) {
    # names with a morphospecies code still count as containing a number
    morpho <- grepl(.MORPHOSPECIES, x, perl = TRUE)
    x <- .drop.morphospecies(x)
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
    spec.data$Number.detected <- nb | morpho
    if (any(nb)) x[nb] <- sub("[[:digit:]]+$", "", sub(" .*$", "", x[nb]))
  }
  hy <- grepl(" x ", x, fixed = TRUE)
  if (any(hy)) {
    message(
      "pattern ' x ' was interpreted as hybrid notation and replaced by ' ",
      .HYBRID,
      "'"
    )
    if (!any.step) spec.data[[orig.name]] <- x
    x[hy] <- gsub(" x ", paste0(" ", .HYBRID), x[hy], fixed = TRUE)
  }
  spec.data[[spec.name]] <- x
  spec.data
}

# TRUE for names made only of placeholder words ("indet.", "sp.", "cf.", "spp.",
# "indet", "unknown"): the words of sub.pattern without punctuation, and a few
# others. Such names are not fuzzy-matched (Fuzzy.skip.placeholder), because
# they are not plant names: WorldFlora matched "indet." with "Opuntia
# coindetti", found within that name.
.is.placeholder <- function(x, sub.pattern) {
  words <- unlist(strsplit(sub.pattern, " ", fixed = TRUE))
  ph <- unique(c(
    tolower(gsub("[^[:alpha:]]", "", words)),
    "indet", "indeterminate", "indetermined", "unknown", "sp", "spp", "cf",
    "aff", "nd"
  ))
  ph <- ph[nchar(ph) > 0]
  vapply(strsplit(tolower(x), " ", fixed = TRUE), function(w) {
    w <- gsub("[^[:alpha:]]", "", w)
    w <- w[nchar(w) > 0]
    length(w) > 0 && all(w %in% ph)
  }, logical(1))
}

# Morphospecies codes at the end of a name: " sp.1", " sp.1_ECOSUR1", " sp9",
# " sp. 2", " spp.3". They are removed before the other cleaning steps, so that
# the genus remains ("Aegiphila sp.1_ECOSUR1" -> "Aegiphila"); WorldFlora
# removed " sp." and kept the rest glued to the genus ("Aegiphila1_ECOSUR").
# A code followed by other words ("Palma sp1 colorada") is left to the number
# rule (spec.name.nonumber), which keeps the first word.
.MORPHOSPECIES <- "\\s+spp?[.]?\\s*[0-9][^ ]*$"
.drop.morphospecies <- function(x) gsub(.MORPHOSPECIES, "", x, perl = TRUE)

# Names with "aff." (affinis: near, but not, this species)
.has.aff <- function(x) grepl("(^|\\s)aff[.]?(\\s|$)", x, ignore.case = TRUE)
