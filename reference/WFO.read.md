# Read and remember the taxonomic backbone

`WFO.read()` reads the backbone file. `WFO.remember()` remembers where
the file is and loads it, so that later sessions need neither the path
nor a new download.

## Usage

``` r
WFO.read(
  WFO.file = NULL,
  select = NULL,
  core.only = FALSE,
  as.data.frame = FALSE
)

read_classification(
  path = file.path("wfo_data", "classification.csv"),
  select = NULL,
  core.only = FALSE,
  as_data_frame = FALSE
)

WFO.remember(WFO.file = NULL, WFO.data = "WFO.data", WFO.pos = 1, ...)
```

## Arguments

- WFO.file, path:

  Path to the backbone (`classification.csv` or `classification.txt`),
  or a directory that contains it. For `WFO.read()` and
  `WFO.remember()`, `NULL` uses the remembered location, or, if that
  file no longer exists, the newest release in the data folder (see
  [`WFO.releases()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.releases.md)).

- select:

  Names of columns to read (saves time and memory).

- core.only:

  If `TRUE`, read only the columns used by this package: `taxonID`,
  `scientificName`, `scientificNameAuthorship`, `taxonRank`,
  `taxonomicStatus`, `nomenclaturalStatus`, `acceptedNameUsageID`,
  `family`, `genus`, `specificEpithet`, `verbatimTaxonRank` and
  `infraspecificEpithet`. Ignored if `select` is given.

- as.data.frame, as_data_frame:

  If `TRUE`, return a data.frame instead of a data.table.

- WFO.data:

  Name of the object created by `WFO.remember()`.

- WFO.pos:

  Environment position for that object, as argument `pos` of
  [`assign()`](https://rdrr.io/r/base/assign.html) (1: the global
  environment).

- ...:

  Further arguments for `WFO.read()`, such as `core.only`.

## Value

`WFO.read()`: a data.table (or data.frame). `WFO.remember()`: the path
of the backbone (invisibly); the backbone is assigned to `WFO.data`.

## Details

`WFO.read()` uses
[`data.table::fread()`](https://rdrr.io/pkg/data.table/man/fread.html).
All columns are read as character, so that identifiers such as
"wfo-0000000001" and codes such as "NA" are never changed or turned into
missing values. The separator is detected (the WFO file is tab-separated
despite its extension). Selected columns that are not in the file are
skipped with a warning.

`WFO.remember()` saves the location in the user configuration directory
([`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html)); a
location saved by WorldFlora is also found. With `WFO.file = NULL`, the
matching functions use the remembered backbone too, or, if it no longer
exists, the newest release in the data folder of
[`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md).
A message gives the file and the release used.

`read_classification()` is deprecated: use `WFO.read()`. It used the
argument names of the stand-alone download script, unlike the other
functions.

## See also

[`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md),
[`WFO.releases()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.releases.md)

## Examples

``` r
f <- tempfile(fileext = ".csv")
data(WFO.example2026)
data.table::fwrite(WFO.example2026, f, sep = "\t")
bb <- WFO.read(f, core.only = TRUE)
str(bb)
#> Classes ‘data.table’ and 'data.frame':   48 obs. of  12 variables:
#>  $ taxonID                 : chr  "wfo-4100000110" "wfo-1200070526" "wfo-4000034168" "wfo-7000000046" ...
#>  $ scientificName          : chr  "Palmae" "Reinwardtia" "Saurauia" "Arecaceae" ...
#>  $ scientificNameAuthorship: chr  "Juss." "Blume ex Nees" "Willd." "Bercht. & J.Presl" ...
#>  $ taxonRank               : chr  "family" "genus" "genus" "family" ...
#>  $ taxonomicStatus         : chr  "Synonym" "Synonym" "Accepted" "Accepted" ...
#>  $ nomenclaturalStatus     : chr  "" "" "Conserved" "Valid" ...
#>  $ acceptedNameUsageID     : chr  "wfo-7000000046" "wfo-4000034168" "" "" ...
#>  $ family                  : chr  "" "Actinidiaceae" "Actinidiaceae" "Arecaceae" ...
#>  $ genus                   : chr  "" "Reinwardtia" "Saurauia" "" ...
#>  $ specificEpithet         : chr  "" "" "" "" ...
#>  $ verbatimTaxonRank       : chr  "family" "genus" "genus" "family" ...
#>  $ infraspecificEpithet    : chr  "" "" "" "" ...
#>  - attr(*, ".internal.selfref")=<pointer: 0x564cbc138a30> 
if (FALSE) { # \dontrun{
WFO.remember("wfo_data/classification.csv") # remember and load as WFO.data
WFO.remember() # in a later session
} # }
```
