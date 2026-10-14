# Keep one match per submitted name

Reduces the results of
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
to one row per submitted name, choosing among several candidates with a
fixed sequence of criteria.

## Usage

``` r
WFO.one(
  WFO.result = NULL,
  priority = "Accepted",
  spec.name = NULL,
  Auth.dist = NULL,
  Old.author.dist = NULL,
  First.dist = NULL,
  verbose = TRUE,
  counter = 1000
)
```

## Arguments

- WFO.result:

  Results of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md).

- priority:

  `"Accepted"`: prefer accepted names, then names that are not synonyms.
  `"Synonym"`: prefer names that were not synonyms, then accepted names.

- spec.name:

  Name of the column with the submitted names. If given, submitted names
  without a match are copied to `scientificName` (with `One.Reason` "no
  match found").

- Auth.dist:

  Name of the column with the distance between submitted and matched
  authors (usually `"Auth.dist"`); if given, candidates with the closest
  authors are preferred.

- Old.author.dist:

  Name of the column with the distance between submitted authors and
  those of replaced synonyms (usually `"Old.author.dist"`); if given,
  synonym candidates with closer authors than any current-name candidate
  are preferred first.

- First.dist:

  Name of the column with the distance between first words (usually
  `"First.dist"`); if given, candidates with the closest genus are
  preferred.

- verbose:

  If `TRUE`, report the choices made.

- counter:

  Progress is reported every `counter` submitted names with several
  candidates.

## Value

`WFO.result` with one row per submitted name, and column `One.Reason`.

## Details

For each submitted name with several candidates, the criteria are
applied in this order, each only while several candidates remain:
authorship of synonyms (`Old.author.dist`), authorship of current names
(`Auth.dist`), genus distance (`First.dist`), `priority`, and finally
the smallest numeric part of `taxonID`. Column `One.Reason` gives the
criterion that decided.

Unlike WorldFlora 1.14-5, the authorship step compares the candidates
that were not replaced by accepted names, rather than a recycled
selection of all candidates; the chosen records were the same in our
comparisons, but `One.Reason` can differ.

## See also

[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)

## Examples

``` r
data(WFO.example2026)
m <- WFO.match(c("Omalanthus populneus", "World agroforestry"),
  WFO.data = WFO.example2026,
  Fuzzy.min = FALSE
) # non-default (of WFO.match): all fuzzy candidates
#> Checking for fuzzy matches for 2 records
#> Fuzzy matches for Omalanthus populneus rejected by the epithet check: Homalanthus populneus, Homalanthus populneus var. minor, Homalanthus populneus var. laevis, Homalanthus populneus var. siccus, Homalanthus populneus var. genuinus
#> Fuzzy matches for Omalanthus populneus were only found for first term (Omalanthus)
#> Fuzzy matches for Omalanthus populneus were: Homalanthus caloneurus, Homalanthus populneus, Homalanthus populneus var. cordifolius, Homalanthus populneus var. genuinus, Homalanthus populneus var. laevis, Homalanthus populneus var. minor, Homalanthus populneus var. siccus
#> 
#> Checking new accepted IDs
nrow(m) # several candidates for the first name
#> [1] 9

## ---- default settings (those of WorldFlora) ----
WFO.one(m)[, c("spec.name", "scientificName", "One.Reason")]
#> Different candidates for original record # 1, including Homalanthus caloneurus
#> Smallest ID candidates for 1 were: Homalanthus caloneurus, Homalanthus populneus
#> Selected record with smallest ID for record # 1
#>              spec.name         scientificName  One.Reason
#> 1 Omalanthus populneus Homalanthus caloneurus smallest ID
#> 9   World agroforestry                   <NA>            

# homonyms of "Acacia albida": with the default settings, authors are not
# used
aa <- data.frame(
  spec.name = "Acacia albida",
  Authorship = c("Delile", "Lindl.")
)
m2 <- WFO.match(aa, WFO.data = WFO.example2026)
#> 
#> Checking new accepted IDs
WFO.one(m2)[, c(
  "Authorship", "scientificName", "scientificNameAuthorship",
  "One.Reason"
)]
#> Different candidates for original record # 1, including Faidherbia albida
#> Found unique not a synonym case for record # 1
#> Different candidates for original record # 2, including Faidherbia albida
#> Found unique not a synonym case for record # 2
#>   Authorship scientificName scientificNameAuthorship    One.Reason
#> 3     Delile  Acacia albida             Rojas Acosta Not a synonym
#> 6     Lindl.  Acacia albida             Rojas Acosta Not a synonym

## ---- non-default settings, marked "non-default" ----
# the authors decide between homonyms
o <- WFO.one(m2, Old.author.dist = "Old.author.dist") # non-default
#> Different candidates for original record # 1, including Faidherbia albida
#> Found unique best Authorship match case for record # 1
#> Different candidates for original record # 2, including Faidherbia albida
#> Found unique best Authorship match case for record # 2
o[, c("Authorship", "scientificName")]
#>   Authorship     scientificName
#> 1     Delile  Faidherbia albida
#> 5     Lindl. Vachellia tortuosa

# unmatched names keep the submitted name
o <- WFO.one(m, spec.name = "spec.name") # non-default
#> Different candidates for original record # 1, including Homalanthus caloneurus
#> Smallest ID candidates for 1 were: Homalanthus caloneurus, Homalanthus populneus
#> Selected record with smallest ID for record # 1
o[, c("spec.name", "scientificName", "One.Reason")]
#>              spec.name         scientificName     One.Reason
#> 1 Omalanthus populneus Homalanthus caloneurus    smallest ID
#> 9   World agroforestry     World agroforestry no match found
```
