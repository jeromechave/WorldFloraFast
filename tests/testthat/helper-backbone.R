## Small backbone in the WFO layout, covering homonyms, synonyms, infraspecific taxa,
## conserved family names and hybrids.
mini_backbone <- function() {
  d <- data.frame(
    taxonID = sprintf("wfo-%010d", 1:16),
    scientificName = c("Faidherbia albida", "Acacia albida", "Acacia nilotica", "Acacia nilotica",
                       "Acacia nilotica subsp. tomentosa", "Acacia", "Asteraceae", "Poaceae",
                       "Ficus sycomorus", "Ficus", "Eucalyptus \u00d7hybrida", "Vachellia nilotica",
                       "Coffea arabica", "Coffea", "Brachystegia spiciformis", "Fabaceae"),
    scientificNameAuthorship = c("(Delile) A.Chev.", "Delile", "(L.) Willd. ex Delile", "Auct.",
                                 "(Benth.) Brenan", "Mill.", "Bercht. & J.Presl", "Barnhart",
                                 "L.", "L.", "Maiden", "(L.) P.J.H.Hurter",
                                 "L.", "L.", "Benth.", "Lindl."),
    taxonRank = c("SPECIES", "SPECIES", "SPECIES", "SPECIES", "SUBSPECIES", "GENUS", "FAMILY", "FAMILY",
                  "SPECIES", "GENUS", "SPECIES", "SPECIES", "SPECIES", "GENUS", "SPECIES", "FAMILY"),
    family = c("Fabaceae", "Fabaceae", "Fabaceae", "Fabaceae", "Fabaceae", "Fabaceae", "Asteraceae", "Poaceae",
               "Moraceae", "Moraceae", "Myrtaceae", "Fabaceae", "Rubiaceae", "Rubiaceae", "Fabaceae", "Fabaceae"),
    genus = c("Faidherbia", "Acacia", "Acacia", "Acacia", "Acacia", "Acacia", "", "",
              "Ficus", "Ficus", "Eucalyptus", "Vachellia", "Coffea", "Coffea", "Brachystegia", ""),
    specificEpithet = c("albida", "albida", "nilotica", "nilotica", "nilotica", "", "", "",
                        "sycomorus", "", "\u00d7hybrida", "nilotica", "arabica", "", "spiciformis", ""),
    infraspecificEpithet = c(rep("", 4), "tomentosa", rep("", 11)),
    verbatimTaxonRank = c(rep("", 4), "subsp.", rep("", 11)),
    taxonomicStatus = c("Accepted", "Synonym", "Synonym", "Synonym", "Accepted", "Accepted", "Accepted", "Accepted",
                        "Accepted", "Accepted", "Accepted", "Accepted", "Accepted", "Accepted", "Accepted", "Accepted"),
    acceptedNameUsageID = c("", "wfo-0000000001", "wfo-0000000012", "wfo-0000000012", rep("", 12)),
    stringsAsFactors = FALSE)
  data.table::as.data.table(d)
}
q <- function(expr) suppressWarnings(suppressMessages(expr))

## small backbone for the transfer and cross-family rules
bb <- function(names, family, status = "Accepted", accepted = "") {
  w <- strsplit(names, " ")
  data.frame(taxonID = paste0("id", seq_along(names)), scientificName = names, scientificNameAuthorship = "",
             taxonRank = ifelse(lengths(w) == 1, "genus", "species"), taxonomicStatus = status,
             acceptedNameUsageID = accepted, family = family,
             genus = vapply(w, `[`, "", 1), specificEpithet = vapply(w, function(z) if (length(z) > 1) z[2] else "", ""),
             infraspecificEpithet = "", verbatimTaxonRank = ifelse(lengths(w) == 1, "genus", "species"),
             stringsAsFactors = FALSE)
}

## WFO.match() with the optional matching steps of WorldFloraFast switched on (each can be
## switched off again by name)
WFO.match.ff <- function(..., Fuzzy.genus = TRUE, Fuzzy.transfer = TRUE, Fuzzy.one.strict = TRUE,
                         Fuzzy.epithet.check = TRUE)
  WFO.match(..., Fuzzy.genus = Fuzzy.genus, Fuzzy.transfer = Fuzzy.transfer,
            Fuzzy.one.strict = Fuzzy.one.strict, Fuzzy.epithet.check = Fuzzy.epithet.check)
