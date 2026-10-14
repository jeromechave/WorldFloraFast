# Example subset of the World Flora Online taxonomic backbone (WorldFlora)

The example data set of WorldFlora, unchanged: a small subset of an
earlier release of the World Flora Online taxonomic backbone. Kept so
that code written for WorldFlora keeps working; the examples of this
package use
[WFO.example2026](https://jeromechave.github.io/WorldFloraFast/reference/WFO.example2026.md),
an extract of the WFO Plant List 2026-06.

## Usage

``` r
WFO.example
```

## Format

A data.frame with 13 rows and the columns of the WFO backbone of that
release (`taxonID`, `scientificName`, `scientificNameAuthorship`,
`taxonRank`, `family`, `genus`, `specificEpithet`,
`infraspecificEpithet`, `verbatimTaxonRank`, `taxonomicStatus`,
`acceptedNameUsageID`, ...).

## Source

World Flora Online. <https://www.worldfloraonline.org>

## Examples

``` r
data(WFO.example)
WFO.match("Faidherbia albida", WFO.data = WFO.example)$scientificName
#> 
#> Checking new accepted IDs
#> [1] "Faidherbia albida"
```
