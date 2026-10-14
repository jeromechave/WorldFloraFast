# Check whether fuzzy matches are explained by misspellings

A name has one correct spelling, the one in the taxonomic backbone. When
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
finds a name by fuzzy matching, the submitted spelling differs from the
correct one. `WFO.spelling.check()` tells whether the difference is
explained by common misspellings that do not change which name was meant
(so that the correction made by fuzzy matching can be trusted), or
whether the names differ in other ways (so that the match should be
checked: it may be a different name).

## Usage

``` r
WFO.spelling.check(x, spec.name = "spec.name", no.vowels = FALSE)
```

## Arguments

- x:

  Results of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  or
  [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md).

- spec.name:

  Name of the column with the submitted names.

- no.vowels:

  If `TRUE`, also treat differences in vowels as misspellings.

## Value

A character vector with one value per row of `x`:

- "identical":

  the submitted name is spelled as in the backbone;

- "spelling corrected":

  the names differ only by the misspellings listed above;

- "other difference":

  the names differ in other ways: check the match;

- NA:

  no name was matched.

## Details

The submitted name is compared with the matched name; for synonyms
replaced by their accepted names, with the synonym that was matched
(`Old.name`). Both are first put in a form where these common
misspellings disappear (examples from the WFO):

- wrong gender of the epithet: endings -um and -us become -a, and -is
  becomes -e (Decarydendron ranomafanensis for *Decarydendron
  ranomafanense*);

- a missing or extra hyphen (the first one) or hybrid sign (Sorbus
  avonensis for *Sorbus* × *avonensis*);

- i written as j, or ii as i (Syzygium naiadum for *Syzygium najadum*);

- single and double letters confused (tt, ll, rr, mm, nn, ff, hh, dd;
  Ficus scott-elliottii for *Ficus scott-elliotii*), and dt for d
  (Stadtmannia for *Stadmania*);

- with `no.vowels = TRUE`, any vowel (including y).

## See also

[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)

## Examples

``` r
x <- data.frame(
  spec.name = c(
    "Ficus scott-elliotii", "Ficus scott-elliottii",
    "Coffea arabicus", "Acacia nilotica", "Xx yy"
  ),
  scientificName = c(
    "Ficus scott-elliotii", "Ficus scott-elliotii",
    "Coffea arabica", "Acacia senegal", NA
  ),
  New.accepted = FALSE, Old.name = ""
)
WFO.spelling.check(x)
#> [1] "identical"          "spelling corrected" "spelling corrected"
#> [4] "other difference"   NA                  

data(WFO.example2026)
m <- WFO.match(c("Faidherbia albida", "Faidherbia albidum", "Pygeum afric"),
  WFO.data = WFO.example2026, verbose = FALSE
)
#> Checking for fuzzy matches for 2 records
#> 
#> Checking new accepted IDs
cbind(m[, c("spec.name", "Fuzzy", "Old.name", "scientificName")],
  spelling = WFO.spelling.check(m)
)
#>            spec.name Fuzzy         Old.name    scientificName
#> 1  Faidherbia albida FALSE                  Faidherbia albida
#> 2 Faidherbia albidum  TRUE                  Faidherbia albida
#> 3       Pygeum afric  TRUE Pygeum africanum   Prunus africana
#>             spelling
#> 1          identical
#> 2 spelling corrected
#> 3   other difference
```
