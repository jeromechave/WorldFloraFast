## --------------------------------------------------------------------------------------
## constants.R: constants used by several functions
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - .conserved.families: the conserved family names and their standard names (from
##       WFO.match()).
##     - .browse.columns: the columns listed by WFO.browse() and WFO.synonyms().
##   Changed:
##     - .HYBRID: the hybrid sign, written as a literal in WorldFlora.
##   New in WorldFloraFast:
##     - .WFO.CORE.COLUMNS (WFO.read(core.only = TRUE)).
##     - Zenodo record, file and archive names, from the download_classification.R
##       script.
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

## Multiplication sign used by WFO for hybrids
.HYBRID <- intToUtf8(215)


## Conserved alternative family names (ICN Art. 18.5) and their standard names
.conserved.families <- c(Compositae = "Asteraceae", Leguminosae = "Fabaceae", Umbelliferae = "Apiaceae",
                         Palmae = "Arecaceae", Cruciferae = "Brassicaceae", Guttiferae = "Clusiaceae",
                         Labiatae = "Lamiaceae", Gramineae = "Poaceae")

## Columns read by WFO.read(core.only = TRUE): those used by WFO.match, WFO.one, WFO.browse, ...)
.WFO.CORE.COLUMNS <- c("taxonID", "scientificName", "scientificNameAuthorship",
                       "taxonRank", "taxonomicStatus", "nomenclaturalStatus",
                       "acceptedNameUsageID", "family", "genus", "specificEpithet",
                       "verbatimTaxonRank", "infraspecificEpithet")

## Zenodo record of the WFO Plant List; newer releases are versions of the same record
.WFO.SEED.RECORD <- "18007552"

.WFO.TARGET.FILE <- "classification.csv"

## Archives that can contain classification.csv, in order of preference
.WFO.ARCHIVES <- c("_DwC_backbone_R.zip", "_uber.zip")

## Metadata written next to the downloaded file
.WFO.SOURCE.INFO <- "classification_source.json"


## Columns returned by WFO.browse() and WFO.synonyms()
.browse.columns <- c("taxonID", "scientificName", "scientificNameAuthorship", "taxonRank",
                     "taxonomicStatus", "acceptedNameUsageID")
