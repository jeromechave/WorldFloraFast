# Example subset of the World Flora Online taxonomic backbone (Plant List 2026-06)

A small extract of the WFO Plant List 2026-06, used in the examples. It
contains the names of the examples, the edge cases discussed in
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
(a truncated genus, a species transferred to another genus, a local
name) and every accepted name that these names refer to. For real work,
download the complete backbone with
[`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md).

## Usage

``` r
WFO.example2026
```

## Format

A data.frame with 48 rows and the 12 columns read by
`WFO.read(core.only = TRUE)`: `taxonID`, `scientificName`,
`scientificNameAuthorship`, `taxonRank`, `taxonomicStatus`,
`nomenclaturalStatus`, `acceptedNameUsageID`, `family`, `genus`,
`specificEpithet`, `verbatimTaxonRank` and `infraspecificEpithet`. As in
the 2026-06 release, ranks are written in full and in lower case
("species", "variety"), and hybrids as "Mentha × piperita".

## Source

The World Flora Online Consortium et al. (2026). World Flora Online
Plant List June 2026. Zenodo.
[doi:10.5281/zenodo.20782718](https://doi.org/10.5281/zenodo.20782718)

## Examples

``` r
data(WFO.example2026)
WFO.example2026[, c(
  "scientificName", "taxonomicStatus",
  "acceptedNameUsageID"
)]
#>                            scientificName taxonomicStatus acceptedNameUsageID
#> 1                                  Palmae         Synonym      wfo-7000000046
#> 2                             Reinwardtia         Synonym      wfo-4000034168
#> 3                                Saurauia        Accepted                    
#> 4                               Arecaceae        Accepted                    
#> 5                                   Palma         Synonym      wfo-4000029298
#> 6                                 Phoenix        Accepted                    
#> 7                     Phoenix dactylifera        Accepted                    
#> 8                         Alchornea sicca        Accepted                    
#> 9                  Homalanthus caloneurus        Accepted                    
#> 10                  Homalanthus populneus        Accepted                    
#> 11                  Homalanthus populneus       Unchecked                    
#> 12 Homalanthus populneus var. cordifolius         Synonym      wfo-0000982976
#> 13    Homalanthus populneus var. genuinus         Synonym      wfo-0000983012
#> 14      Homalanthus populneus var. laevis         Synonym      wfo-0000983012
#> 15       Homalanthus populneus var. minor         Synonym      wfo-0000983012
#> 16      Homalanthus populneus var. siccus         Synonym      wfo-0000939875
#> 17                          Acacia albida         Synonym      wfo-0000186081
#> 18                          Acacia albida         Synonym      wfo-0001277461
#> 19                          Acacia albida        Accepted                    
#> 20                               Fabaceae        Accepted                    
#> 21                      Faidherbia albida        Accepted                    
#> 22                     Vachellia tortuosa        Accepted                    
#> 23                              Lamiaceae        Accepted                    
#> 24                                 Mentha        Accepted                    
#> 25                      Mentha × piperita        Accepted                    
#> 26                            Reinwardtia        Accepted                    
#> 27                     Reinwardtia indica        Accepted                    
#> 28                                  Ceiba        Accepted                    
#> 29                        Ceiba pentandra        Accepted                    
#> 30                              Meliaceae        Accepted                    
#> 31                     Reinwardtiodendron        Accepted                    
#> 32            Reinwardtiodendron cinereum        Accepted                    
#> 33                            Reinwardtia         Synonym      wfo-4000037813
#> 34                           Ternstroemia        Accepted                    
#> 35                                 Prunus        Accepted                    
#> 36                        Prunus africana        Accepted                    
#> 37                       Pygeum africanum         Synonym      wfo-0000995790
#> 38          Capurodendron madagascariense        Accepted                    
#> 39                          Chrysophyllum        Accepted                    
#> 40              Chrysophyllum boivinianum         Synonym      wfo-0000970694
#> 41                  Chrysophyllum cainito        Accepted                    
#> 42                                Gambeya        Accepted                    
#> 43                     Gambeya boiviniana        Accepted                    
#> 44    Gambeya boiviniana var. lavanchiana         Synonym      wfo-0000970694
#> 45               Gambeya madagascariensis         Synonym      wfo-0000970694
#> 46       Labourdonnaisia madagascariensis        Accepted                    
#> 47                             Sapotaceae        Accepted                    
#> 48            Sideroxylon madagascariense         Synonym      wfo-0000802134
```
