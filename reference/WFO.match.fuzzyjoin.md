# Match plant names with other string distances (deprecated)

**Deprecated**: use
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md).
On a test of 100 misspelled names against the WFO Plant List 2026-06,
`WFO.match.fuzzyjoin()` took 2.7 times longer than
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
and matched fewer names with a truncated genus correctly (33 against 38
of 40); it has none of the matching steps added in WorldFloraFast
(`Fuzzy.genus`, `Fuzzy.transfer`, `Fuzzy.one.strict`,
`Fuzzy.epithet.check`). It will be removed in a later version.

## Usage

``` r
WFO.match.fuzzyjoin(
  spec.data = NULL,
  WFO.file = NULL,
  WFO.data = NULL,
  no.dates = TRUE,
  spec.name = "spec.name",
  Authorship = "Authorship",
  stringdist.method = "lv",
  fuzzydist.max = 4,
  Fuzzy.min = TRUE,
  acceptedNameUsageID.match = TRUE,
  squish = TRUE,
  spec.name.tolower = FALSE,
  spec.name.nonumber = TRUE,
  spec.name.nobrackets = TRUE,
  spec.name.sub = TRUE,
  sub.pattern = c(" sp[.] A", " sp[.] B", " sp[.] C", " sp[.]", " spp[.]", " pl[.]",
    " indet[.]", " ind[.]", " gen[.]", " g[.]", " fam[.]", " nov[.]", " prox[.]",
    " cf[.]", " aff[.]", " s[.]s[.]", " s[.]l[.]", " p[.]p[.]", " p[.] p[.]", "[?]",
    " inc[.]", " stet[.]", "Ca[.]", "nom[.] cons[.]", "nom[.] dub[.]", " nom[.] err[.]",
    " nom[.] illeg[.]", " nom[.] inval[.]", " nom[.] nov[.]", " nom[.] nud[.]",
    " nom[.] obl[.]", " nom[.] prot[.]", " nom[.] rej[.]", " nom[.] supp[.]",
    " sensu auct[.]"),
  cores = 1
)
```

## Arguments

- spec.data:

  A data.frame with the names to match, or a character vector (or
  factor) of names, which becomes column `spec.name`.

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

- no.dates:

  Deprecated and ignored (columns `created` and `modified` of the
  backbone are always left out of the results); giving it produces a
  warning.

- spec.name:

  Name of the column with full plant names (without authors). If this
  column is absent, names are matched via `Genus`, `Species`,
  `Infraspecific.rank` and `Infraspecific`.

- Authorship:

  Name of the column with the naming authors. If present, column
  `Auth.dist` gives the Levenshtein distance between the submitted and
  matched authors. As in WorldFlora, an empty author ("") gives the
  number of characters of the matched authors; use `NA` for unknown
  authors (distance `Inf`).

- stringdist.method:

  Distance method of
  [`stringdist::stringdist()`](https://rdrr.io/pkg/stringdist/man/stringdist.html),
  such as `"lv"` (Levenshtein), `"osa"`, `"dl"`, `"jw"` or `"qgram"`.

- fuzzydist.max:

  Maximum distance of fuzzy matches.

- Fuzzy.min:

  If `TRUE`, keep only the fuzzy matches with the smallest distance.

- acceptedNameUsageID.match:

  If `TRUE`, replace matched synonyms by their accepted names (via
  `acceptedNameUsageID`), keeping the synonym in columns `Old.*`.

- squish:

  If `TRUE`, remove repeated white space and white space at the start
  and end of names (as
  [`stringr::str_squish()`](https://stringr.tidyverse.org/reference/str_trim.html)).

- spec.name.tolower:

  If `TRUE`, convert names to lower case, with a capital first letter.

- spec.name.nonumber:

  If `TRUE`, names that contain numbers are interpreted as genera (only
  the first word is kept, without trailing digits).

- spec.name.nobrackets:

  If `TRUE`, remove the part of names from the first `"("` onwards (such
  as authors in brackets).

- spec.name.sub:

  If `TRUE`, delete sections of names that match `sub.pattern`.

- sub.pattern:

  Regular expressions of sections to delete, such as `" sp[.]"`,
  `" cf[.]"` or `" nom[.] illeg[.]"`.

- cores:

  Number of cores for fuzzy matching
  ([`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html);
  not on Windows).

## Value

As
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
without columns `Fuzzy.toomany`, `Fuzzy.two`, `Fuzzy.one` and
`First.dist`. `Fuzzy.dist` is the distance of `stringdist.method`.
Candidates are numbered 1, 2, ... in `Subseq` (WorldFlora kept the
numbers from before `Fuzzy.min`).

## Details

An alternative to
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
that finds fuzzy matches by a string distance of package stringdist
(Levenshtein by default) within a maximum distance, rather than by
[`agrep()`](https://rdrr.io/r/base/agrep.html). In WorldFlora this
function used `fuzzyjoin::stringdist_left_join()`; WorldFloraFast
computes the same matches with
[`stringdist::stringdist()`](https://rdrr.io/pkg/stringdist/man/stringdist.html)
directly.

Names are cleaned as in
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md).
Names without an exact match are compared with all backbone names, once
per distinct name; for the edit distances `"lv"`, `"osa"`, `"dl"` and
`"hamming"`, names whose number of characters differs by more than
`fuzzydist.max` are skipped, which does not change the results. Requires
the stringdist package.

## See also

[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)

## Examples

``` r
data(WFO.example2026)
m <- suppressWarnings(WFO.match.fuzzyjoin(
  c("Faidherbia albida", "Omalanthus populneus", "Pygeum africanum"),
  WFO.data = WFO.example2026
))
#> Checking for fuzzy matches for 1 records
#> 
#> Checking new accepted IDs
m[, c("spec.name", "Fuzzy.dist", "scientificName")]
#>              spec.name Fuzzy.dist        scientificName
#> 1    Faidherbia albida         NA     Faidherbia albida
#> 2 Omalanthus populneus          2 Homalanthus populneus
#> 3 Omalanthus populneus          2 Homalanthus populneus
#> 4     Pygeum africanum         NA       Prunus africana
```
