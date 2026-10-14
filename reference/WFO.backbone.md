# Use another taxonomic backbone

Converts a taxonomic list (for example the World Checklist of Vascular
Plants, or a list for another group of organisms) into a backbone that
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
and the other functions of this package can use instead of the World
Flora Online.

## Usage

``` r
WFO.backbone(
  x,
  taxonID = "taxonID",
  scientificName = "scientificName",
  scientificNameAuthorship = "scientificNameAuthorship",
  acceptedNameUsageID = NULL,
  taxonomicStatus = NULL
)

new.backbone(
  x,
  taxonID = "taxonID",
  scientificName = "scientificName",
  scientificNameAuthorship = "scientificNameAuthorship",
  acceptedNameUsageID = NULL,
  taxonomicStatus = NULL
)
```

## Arguments

- x:

  A data.frame with the taxonomic list.

- taxonID:

  Name of the column with the identifiers of the names.

- scientificName:

  Name of the column with the full names (without authors).

- scientificNameAuthorship:

  Name of the column with the naming authors.

- acceptedNameUsageID:

  Name of the column with, for synonyms, the identifier (`taxonID`) of
  the accepted name; empty for accepted names. If `NULL`, all names are
  treated as accepted.

- taxonomicStatus:

  Name of the column with the status of the name (such as "Accepted" or
  "Synonym"). If `NULL`, names with an `acceptedNameUsageID` become
  "Synonym" and the others "Accepted".

## Value

A data.table with the columns `taxonID`, `scientificName`,
`scientificNameAuthorship`, `acceptedNameUsageID` and `taxonomicStatus`,
followed by the other columns of `x`.

## Details

All columns are converted to character. Other columns of `x` are kept.
An `acceptedNameUsageID` that refers to the record itself is emptied
(with a message), as is a missing one.

## Names

`WFO.backbone()` is the name of this function from WorldFloraFast 1.0.3
on, in line with the other functions of the package. `new.backbone()`,
its name in WorldFlora, remains available and gives the same results;
its name resembles an S3 method `new()` for objects of class "backbone",
which it is not.

## References

Kindt, R. (2021). Standardizing mammal species names with the Mammal
Diversity Database via WorldFlora. <https://rpubs.com/Roeland-KINDT>

## Examples

``` r
x <- data.frame(
  id = c("A1", "A2", "A3"),
  name = c("Felis catus", "Felis domesticus", "Panthera leo"),
  author = c("Linnaeus, 1758", "Erxleben, 1777", "(Linnaeus, 1758)"),
  accepted = c("", "A1", "")
)
bb <- WFO.backbone(x,
  taxonID = "id", scientificName = "name",
  scientificNameAuthorship = "author", acceptedNameUsageID = "accepted"
)
m <- WFO.match("Felis domestica", WFO.data = bb, verbose = FALSE)
#> Checking for fuzzy matches for 1 records
#> 
#> Checking new accepted IDs
m[, c("spec.name", "scientificName", "Old.name")]
#>         spec.name scientificName         Old.name
#> 1 Felis domestica    Felis catus Felis domesticus
```
