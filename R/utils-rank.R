## --------------------------------------------------------------------------------------
## utils-rank.R: taxonomic ranks and hybrid notation in both WFO conventions
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - none
##   Changed:
##     - none
##   New in WorldFloraFast:
##     - The whole file: standard form of ranks (.rank.std(), .rank.key()) and of hybrid
##       notation (.hybrid.key()) for WFO releases up to 2025 and from 2026-06.
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

##
## Up to 2025, WFO wrote verbatimTaxonRank as abbreviations ("var.", "subsp.", "f.") and
## left it empty for species; taxonRank was in capitals ("SPECIES"). From the WFO Plant List
## 2026-06 on, both columns hold full lower-case words ("species", "variety",
## "subspecies", "form"). .rank.std() maps both conventions (and users' own spellings)
## to one standard form, so that comparisons work with any release.

.rank.map <- c(
  "species" = "species", "sp." = "species", "nothospecies" = "species",
  "subspecies" = "subsp.", "subsp." = "subsp.", "ssp." = "subsp.", "subsp" = "subsp.",
  "variety" = "var.", "var." = "var.", "var" = "var.", "varietas" = "var.",
  "form" = "f.", "forma" = "f.", "f." = "f.", "fo." = "f.",
  "subvariety" = "subvar.", "subvar." = "subvar.",
  "subform" = "subf.", "subforma" = "subf.",
  "cultivar" = "cultivar.", "cultivar." = "cultivar.", "cv." = "cultivar.",
  "section" = "sect.", "sect." = "sect.",
  "subsection" = "subsect.", "subsect." = "subsect.",
  "series" = "ser.", "ser." = "ser.",
  "subgenus" = "subg.", "subg." = "subg.",
  "genus" = "genus", "family" = "family", "subfamily" = "subfam.", "tribe" = "tribe",
  "nothosubspecies" = "nothosubsp.", "nothosubsp." = "nothosubsp.",
  "nothovariety" = "nothovar.", "nothovar." = "nothovar.",
  "unranked" = "[infraspec.]", "[infraspec.]" = "[infraspec.]",
  "prole" = "prole", "lusus" = "lusus")

## Standard form of ranks: lower case, known names mapped to abbreviations; NA becomes "".
## Unknown values are returned in lower case.
.rank.std <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x[is.na(x)] <- ""
  hit <- match(x, names(.rank.map))
  x[!is.na(hit)] <- unname(.rank.map[hit[!is.na(hit)]])
  x
}

## Rank as written in verbatimTaxonRank for matching by separate columns: "" for species
## (old convention), so that "species" (2026 convention), "" and NA are equivalent.
.rank.key <- function(x) {
  x <- .rank.std(x)
  x[x == "species"] <- ""
  x
}

## Hybrid notation in matching keys: WFO <= 2025 wrote "Mentha ×piperita", WFO 2026-06
## writes "Mentha × piperita". Removing a space after the sign makes both forms (and the
## submitted "Mentha x piperita", cleaned to "Mentha ×piperita") match exactly.
.hybrid.key <- function(x) gsub(paste0(.HYBRID, " "), .HYBRID, x, fixed = TRUE)
