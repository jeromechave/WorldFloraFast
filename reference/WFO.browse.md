# Browse the taxonomic backbone: lower taxa, synonyms, family and order, web links

`WFO.browse()` lists the genera of a family, the species of a genus or
the infraspecific taxa of a species. `WFO.synonyms()` lists the synonyms
of the accepted name of a taxon. `WFO.family()` gives the order and
higher classification of the family of a taxon. `WFO.url()` gives the
World Flora Online web pages of matched names.

## Usage

``` r
WFO.browse(
  taxon = NULL,
  WFO.file = NULL,
  WFO.data = NULL,
  accepted.only = FALSE,
  acceptedNameUsageID.match = TRUE,
  ...
)

WFO.synonyms(taxon = NULL, WFO.file = NULL, WFO.data = NULL, ...)

WFO.family(taxon = NULL, WFO.file = NULL, WFO.data = NULL, ...)

WFO.url(WFO.result = NULL, browse = FALSE, browse.rows = c(1:1), ...)
```

## Arguments

- taxon:

  Name of one taxon (matched first with
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  and
  [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)).
  For `WFO.browse()`, `NULL` lists all families.

- WFO.file:

  Path to the backbone file (`classification.csv`), read with
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md).
  Ignored if `WFO.data` is given. If both are `NULL`, the backbone at
  the location remembered by
  [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  or
  [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  is read.

- WFO.data:

  The backbone as a data.frame or data.table (from
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md),
  [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  or
  [`WFO.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)).

- accepted.only:

  If `TRUE`, list accepted names only.

- acceptedNameUsageID.match:

  If `TRUE` (and `accepted.only = FALSE`), add column `New.name` with
  the accepted name of each listed synonym.

- ...:

  Further arguments for
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  (`WFO.browse()`, `WFO.synonyms()`, `WFO.family()`) or
  [`utils::browseURL()`](https://rdrr.io/r/utils/browseURL.html)
  (`WFO.url()`).

- WFO.result:

  Results of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  or
  [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
  (or a vector of `taxonID`s).

- browse:

  If `TRUE`, open the pages of rows `browse.rows` in a web browser.

- browse.rows:

  Rows of `WFO.result` to open.

## Value

`WFO.browse()` and `WFO.synonyms()`: a data.table with columns
`taxonID`, `scientificName`, `scientificNameAuthorship`, `taxonRank`,
`taxonomicStatus`, `acceptedNameUsageID` (and `New.name`), or `NULL`
when nothing is found. For an order, `WFO.browse()` returns the matching
rows of
[vascular.families](https://jeromechave.github.io/WorldFloraFast/reference/vascular.families.md).

`WFO.family()`: the row of
[vascular.families](https://jeromechave.github.io/WorldFloraFast/reference/vascular.families.md)
for the family; an empty data.frame, with a warning, for families that
are not in this table, such as those of bryophytes (WorldFlora returned
`"bryophytes"` for families in a list kept in its code).

`WFO.url()`: a character vector of web addresses, as in WorldFlora
("http://worldfloraonline.org/taxon/"; `NA` for unmatched records).

## Details

These functions are kept from WorldFlora, so that code written for
WorldFlora (and its graphical interface, RcmdrPlugin.WorldFlora) keeps
working. With the backbone loaded as a data.table, the same results are
simple queries; what the functions add is:

- the submitted taxon is first matched with
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  and
  [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md),
  so misspelled names and synonyms are accepted;

- ranks are compared in both the WFO conventions up to 2025 and from
  2026-06 on;

- `WFO.browse()` adds the accepted name of listed synonyms (`New.name`);

- `WFO.family()` adds the order and higher classification of
  [vascular.families](https://jeromechave.github.io/WorldFloraFast/reference/vascular.families.md),
  which the backbone does not contain.

Equivalent queries, for a backbone `W` read with
[`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
and a correctly spelled accepted name:


    # WFO.synonyms("Gambeya boiviniana")
    id <- W[scientificName == "Gambeya boiviniana", taxonID]
    W[taxonID == id | acceptedNameUsageID == id]

    # WFO.browse("Gambeya"): species of a genus
    W[genus == "Gambeya" & tolower(taxonRank) == "species"]

    # WFO.browse("Gambeya boiviniana"): infraspecific taxa of a species
    W[genus == "Gambeya" & specificEpithet == "boiviniana" &
        infraspecificEpithet != ""]

    # WFO.browse("Sapotaceae"): genera of a family
    W[family == "Sapotaceae" & tolower(taxonRank) == "genus"]

    # WFO.family("Gambeya boiviniana")
    vascular.families[vascular.families$Family ==
                      W[scientificName == "Gambeya boiviniana", family], ]

    # WFO.url()
    paste0("http://worldfloraonline.org/taxon/", W$taxonID[1])

## See also

[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
[vascular.families](https://jeromechave.github.io/WorldFloraFast/reference/vascular.families.md)

## Examples

``` r
data(WFO.example2026) # small extract of the WFO Plant List 2026-06
WFO.synonyms("Gambeya boiviniana",
  WFO.data = WFO.example2026,
  verbose = FALSE
)
#> 
#> Checking new accepted IDs
#>           taxonID                      scientificName scientificNameAuthorship
#>            <char>                              <char>                   <char>
#> 1: wfo-0000970694                  Gambeya boiviniana                   Pierre
#> 2: wfo-0000854394           Chrysophyllum boivinianum          (Pierre) Baehni
#> 3: wfo-0000970695 Gambeya boiviniana var. lavanchiana                  Aubrév.
#> 4: wfo-0000970706            Gambeya madagascariensis                  Lecomte
#>    taxonRank taxonomicStatus acceptedNameUsageID
#>       <char>          <char>              <char>
#> 1:   species        Accepted                    
#> 2:   species         Synonym      wfo-0000970694
#> 3:   variety         Synonym      wfo-0000970694
#> 4:   species         Synonym      wfo-0000970694
# varieties of a species
WFO.browse("Gambeya boiviniana",
  WFO.data = WFO.example2026,
  verbose = FALSE
)
#> 
#> Checking new accepted IDs
#> Submitted name Gambeya boiviniana was matched with: Gambeya boiviniana of taxonRank: species
#>           taxonID                      scientificName scientificNameAuthorship
#>            <char>                              <char>                   <char>
#> 1: wfo-0000970695 Gambeya boiviniana var. lavanchiana                  Aubrév.
#>    taxonRank taxonomicStatus acceptedNameUsageID           New.name
#>       <char>          <char>              <char>             <char>
#> 1:   variety         Synonym      wfo-0000970694 Gambeya boiviniana
# genera of a family
WFO.browse("Sapotaceae", WFO.data = WFO.example2026, verbose = FALSE)
#> 
#> Checking new accepted IDs
#> Submitted name Sapotaceae was matched with: Sapotaceae of taxonRank: family
#>           taxonID scientificName scientificNameAuthorship taxonRank
#>            <char>         <char>                   <char>    <char>
#> 1: wfo-4000008232  Chrysophyllum                       L.     genus
#> 2: wfo-4000015269        Gambeya                   Pierre     genus
#>    taxonomicStatus acceptedNameUsageID New.name
#>             <char>              <char>   <char>
#> 1:        Accepted                             
#> 2:        Accepted                             
WFO.family("Gambeya boiviniana", WFO.data = WFO.example2026, verbose = FALSE)
#> 
#> Checking new accepted IDs
#> Submitted name Gambeya boiviniana was matched with: Gambeya boiviniana of family: Sapotaceae
#>           Group Family.ID     Family Family.taxonID    Order  Order.taxonID
#> 333 angiosperms       333 Sapotaceae wfo-7000000545 Ericales wfo-9000000193
#>       Node.1        Node.2   Node.3 Node.4
#> 333 Eudicots Superasterids Asterids       
WFO.url(WFO.match("Faidherbia albida",
  WFO.data = WFO.example2026,
  verbose = FALSE
))
#> 
#> Checking new accepted IDs
#> [1] "http://worldfloraonline.org/taxon/wfo-0000186081"
if (FALSE) { # \dontrun{
WFO.remember() # backbone downloaded with WFO.download()
WFO.browse("Fabaceae", WFO.data = WFO.data, accepted.only = TRUE)
} # }
```
