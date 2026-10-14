# Split full plant names into name and authorship

`WFO.prepare()` splits full botanical names that include naming
authorities (for example
`"Acacia nilotica subsp. kraussiana (Benth.) Brenan"`) into the plant
name and its authorship, ready for
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md).
It also flags names that probably need checking. `WFO.preprepare()`
splits names around a first and a second infraspecific rank, for names
that contain two of them.

## Usage

``` r
WFO.prepare(
  spec.data = NULL,
  spec.full = "spec.full",
  squish = TRUE,
  spec.name.nonumber = TRUE,
  spec.name.sub = TRUE,
  sub.pattern = c(" sp[.] A", " sp[.] B", " sp[.] C", " sp[.]", " spp[.]", " pl[.]",
    " indet[.]", " ind[.]", " gen[.]", " g[.]", " fam[.]", " nov[.]", " prox[.]",
    " cf[.]", " aff[.]", " s[.]s[.]", " s[.]l[.]", " p[.]p[.]", " p[.] p[.]", "[?]",
    " inc[.]", " stet[.]", "Ca[.]", "nom[.] cons[.]", "nom[.] dub[.]", " nom[.] err[.]",
    " nom[.] illeg[.]", " nom[.] inval[.]", " nom[.] nov[.]", " nom[.] nud[.]",
    " nom[.] obl[.]", " nom[.] prot[.]", " nom[.] rej[.]", " nom[.] supp[.]",
    " sensu auct[.]"),
  genus.2.flag = TRUE,
  species.2.flag = TRUE,
  punctuation.flag = TRUE,
  pointless.flag = TRUE,
  trinomial = c("cultivar.", "f.", "sect.", "subf.", "subg.", "subsp.", "subvar.",
    "var.", "CULTIVAR.", "SECT.", "SUBF.", "SUBG.", "SUBSP.", "SUBVAR.", "VAR."),
  authors.ending.f = c("Aiton f.", "Baker f.", "Bak. f.", "Burm. f.", "Cheng f.",
    "Chrtek f.", "De Marco f.", "Fang f.", "Ferry f.", "Forsyth f.", "Forster f.",
    "Fraser f.", "G.Don f.", "Haller f.", "Hallier f.", "Hook. f.", "Hooker f.",
    "Hsueh f.", "J.Kickx f.", "J. Kickx f.", "Keng f.", "Kickx f.", "Klokov f.",
    "Koster f.", "Liou f.", "L. f.", "Ma f.", "Mikan f.", "Occhioni f.", "Rchb. f.",
    "Schultes f.", "Schult. f.", "Stapf f."),
  verbose = TRUE,
  counter = 1000
)

WFO.preprepare(
  spec.data = NULL,
  spec.full = "spec.full",
  trinomial.first = "subsp.",
  trinomial.second = "var."
)
```

## Arguments

- spec.data:

  A data.frame with a column of full names, or a character vector (or
  factor) of full names.

- spec.full:

  Name of the column with the full names.

- squish:

  If `TRUE`, remove repeated white space, and white space at the start
  and end of names
  ([`stringr::str_squish()`](https://stringr.tidyverse.org/reference/str_trim.html)).

- spec.name.nonumber:

  If `TRUE`, names that contain numbers are interpreted as genera (only
  the first word is kept, without trailing digits).

- spec.name.sub:

  If `TRUE`, delete sections of names that match `sub.pattern`.

- sub.pattern:

  Regular expressions of sections to delete, such as `" sp[.]"` or
  `" cf[.]"`.

- genus.2.flag:

  Flag names of which the first word has fewer than 3 characters.

- species.2.flag:

  Flag names of which the second word has fewer than 3 characters.

- punctuation.flag:

  Flag names that still contain punctuation marks (other than those of
  the infraspecific ranks in `trinomial`).

- pointless.flag:

  Flag names that contain one of the `sub.pattern` sections written
  without punctuation (for example `"cf"` instead of `"cf."`).

- trinomial:

  Infraspecific ranks; the word after the rank is kept as part of the
  name.

- authors.ending.f:

  Author abbreviations ending in `" f."` (filius), which would otherwise
  be mistaken for the rank `"f."` (forma).

- verbose:

  If `TRUE`, report the changes made to names.

- counter:

  Progress is reported every `counter` distinct names.

- trinomial.first, trinomial.second:

  First and second infraspecific rank used by `WFO.preprepare()` to
  split names.

## Value

`WFO.prepare()`: `spec.data` (a data.frame) with the added columns
`spec.name` and `Authorship` (omitted when no authorship was found) and
the requested flag columns. Existing columns `spec.name` and
`Authorship` are renamed with suffix `.ORIG`.

`WFO.preprepare()`: `spec.data` with logical columns `first` (first rank
found), `only.second` (only the second rank found), `also.second`
(second rank found after the first), and the split sections
`split.before`, `split.after` and, when needed, `second.split.before`
and `second.split.after`.

## Details

For each distinct full name, `WFO.prepare()` successively squishes white
space, removes `sub.pattern` sections, reduces names with numbers to
their first word, and then keeps the first two words, plus an
infraspecific rank from `trinomial` and the word after it. The remaining
words form the authorship. A second set of brackets in the authorship
(as in `"(Benth.) Brenan (1950)"`) and everything after it is removed.

Flag columns are character columns, as in WorldFlora: `"TRUE"` or `""`
for `punctuation` and `pointless`; the number of characters, and the
short word itself, for `genus.nchar`, `genus.2`, `species.nchar` and
`species.2`.

Each distinct name is processed once, so messages and warnings are given
once per distinct name.

## See also

[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
which accepts the prepared names, with `Authorship` used to calculate
`Auth.dist`.

## Examples

``` r
x <- c(
  "Acacia nilotica subsp. kraussiana (Benth.) Brenan",
  "Ficus sycomorus L.", "Prunus africana (Hook. f.) Kalkman",
  "Coffea sp. 3"
)
WFO.prepare(x, verbose = FALSE)
#>                                           spec.full
#> 1 Acacia nilotica subsp. kraussiana (Benth.) Brenan
#> 2                                Ficus sycomorus L.
#> 3                Prunus africana (Hook. f.) Kalkman
#> 4                                      Coffea sp. 3
#>                           spec.name         Authorship genus.nchar genus.2
#> 1 Acacia nilotica subsp. kraussiana    (Benth.) Brenan           6        
#> 2                   Ficus sycomorus                 L.           5        
#> 3                   Prunus africana (Hook. f.) Kalkman           6        
#> 4                            Coffea                              6        
#>   species.nchar species.2 punctuation pointless
#> 1             8                                
#> 2             9                                
#> 3             8                                
#> 4                                              

WFO.preprepare(c(
  "Acacia nilotica subsp. kraussiana var. major L.",
  "Ficus sycomorus L."
))
#>                                         spec.full first       split.before
#> 1 Acacia nilotica subsp. kraussiana var. major L.  TRUE    Acacia nilotica
#> 2                              Ficus sycomorus L. FALSE Ficus sycomorus L.
#>                       split.after only.second also.second second.split.before
#> 1 subsp. kraussiana var. major L.       FALSE        TRUE   subsp. kraussiana
#> 2                            <NA>       FALSE       FALSE                    
#>   second.split.after
#> 1      var. major L.
#> 2                   
```
