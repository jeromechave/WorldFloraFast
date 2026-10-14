# Standardizing plant names with WorldFloraFast

WorldFloraFast matches plant names against the taxonomic backbone of the
[World Flora Online](https://www.worldfloraonline.org) (WFO): it
corrects spelling mistakes, recognises synonyms and returns the
currently accepted names. It is a faster, refactored derivative of the
WorldFlora package (Kindt 2020), with the same functions and arguments.

## 1. Obtain the backbone

The backbone (`classification.csv`, about 1.6 million names) is
published on Zenodo.
[`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
downloads the latest release, verifies its checksum, remembers where it
is and loads it as `WFO.data`:

``` r

WFO.download(save.dir = "wfo_data")              # first time: about 1 GB
WFO.download(save.dir = "wfo_data", update = TRUE)  # later: newer release?
# new session: load WFO.data again
WFO.remember()
WFO.data <- WFO.read("wfo_data", core.only = TRUE)  # or read fewer columns
```

This vignette uses `WFO.example2026`, a small extract of the WFO Plant
List 2026-06 that is included in the package.

``` r

data(WFO.example2026)
head(WFO.example2026[, c(
  "taxonID", "scientificName", "taxonRank", "taxonomicStatus"
)])
#>          taxonID scientificName taxonRank taxonomicStatus
#> 1 wfo-4100000110         Palmae    family         Synonym
#> 2 wfo-1200070526    Reinwardtia     genus         Synonym
#> 3 wfo-4000034168       Saurauia     genus        Accepted
#> 4 wfo-7000000046      Arecaceae    family        Accepted
#> 5 wfo-4000027807          Palma     genus         Synonym
#> 6 wfo-4000029298        Phoenix     genus        Accepted
```

## 2. Prepare names that include authors

Names in field data or literature often include authors.
[`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
separates them; the `Authorship` column then helps to choose between
homonyms.

``` r

x <- c(
  "Faidherbia albida (Delile) A.Chev.", "Acacia albida Delile",
  "Pygeum afric Hook. f."
)
prep <- WFO.prepare(x, verbose = FALSE)
prep[, c("spec.full", "spec.name", "Authorship")]
#>                            spec.full         spec.name       Authorship
#> 1 Faidherbia albida (Delile) A.Chev. Faidherbia albida (Delile) A.Chev.
#> 2               Acacia albida Delile     Acacia albida           Delile
#> 3              Pygeum afric Hook. f.      Pygeum afric         Hook. f.
```

## 3. Match the names

``` r

m <- WFO.match(prep, WFO.data = WFO.example2026, verbose = FALSE)
m[, c(
  "spec.name", "Subseq", "Fuzzy", "scientificName",
  "scientificNameAuthorship", "Old.name", "Old.author"
)]
#>           spec.name Subseq Fuzzy     scientificName scientificNameAuthorship
#> 1 Faidherbia albida      1 FALSE  Faidherbia albida         (Delile) A.Chev.
#> 2     Acacia albida      1 FALSE  Faidherbia albida         (Delile) A.Chev.
#> 3     Acacia albida      2 FALSE Vachellia tortuosa   (L.) Seigler & Ebinger
#> 4     Acacia albida      3 FALSE      Acacia albida             Rojas Acosta
#> 5      Pygeum afric      1  TRUE    Prunus africana        (Hook.f.) Kalkman
#>           Old.name Old.author
#> 1                            
#> 2    Acacia albida     Delile
#> 3    Acacia albida     Lindl.
#> 4                            
#> 5 Pygeum africanum    Hook.f.
```

- *Faidherbia albida* is matched exactly.
- *Acacia albida* has three homonyms in the WFO: *A. albida* Delile is a
  synonym of *Faidherbia albida*, *A. albida* Lindl. a synonym of
  *Vachellia tortuosa*, and *A. albida* Rojas Acosta is an accepted
  name. All three are returned, numbered by `Subseq`; synonyms are
  replaced by their accepted names and kept in `Old.name`.
- *Pygeum afric* is incomplete: fuzzy matching finds *Pygeum africanum*,
  a synonym of *Prunus africana*.

Names can also be given as a character vector, or in separate columns
`Genus`, `Species`, `Infraspecific.rank` and `Infraspecific` (exact
matching only).

## 4. Keep one match per name

[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
keeps one row per submitted name. With the distances between submitted
and matched authors, the homonym *A. albida* Delile is chosen:

``` r

one <- WFO.one(m,
  Auth.dist = "Auth.dist", Old.author.dist = "Old.author.dist",
  verbose = FALSE
)
one[, c("spec.name", "Authorship", "scientificName", "Old.name", "One.Reason")]
#>           spec.name       Authorship    scientificName         Old.name
#> 1 Faidherbia albida (Delile) A.Chev. Faidherbia albida                 
#> 2     Acacia albida           Delile Faidherbia albida    Acacia albida
#> 5      Pygeum afric         Hook. f.   Prunus africana Pygeum africanum
#>                          One.Reason
#> 1                                  
#> 2 Authorship best match for synonym
#> 5
```

Without authors,
[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
prefers accepted names, then names that were not synonyms (here *A.
albida* Rojas Acosta), then the smallest `taxonID`; `One.Reason` shows
what decided.

### Fuzzy matching options

`Fuzzy` is the maximum distance (a fraction of the name length, or a
number of edits). By default only the closest candidates are kept
(`Fuzzy.min = TRUE`); with `Fuzzy.min = FALSE`, all candidates within
the distance are returned, one row each:

``` r

all.cand <- WFO.match("Omalanthus populneus",
  WFO.data = WFO.example2026,
  Fuzzy.min = FALSE, verbose = FALSE
)
all.cand[, c(
  "Subseq", "Fuzzy.dist", "scientificName", "taxonomicStatus", "Old.name"
)]
#>   Subseq Fuzzy.dist         scientificName taxonomicStatus
#> 1      1          9 Homalanthus caloneurus        Accepted
#> 2      2          2  Homalanthus populneus        Accepted
#> 3      3          2  Homalanthus populneus       Unchecked
#> 4      4         19 Homalanthus caloneurus        Accepted
#> 5      5         16  Homalanthus populneus        Accepted
#> 6      6         14  Homalanthus populneus        Accepted
#> 7      7         13  Homalanthus populneus        Accepted
#> 8      8         14        Alchornea sicca        Accepted
#>                                 Old.name
#> 1                                       
#> 2                                       
#> 3                                       
#> 4 Homalanthus populneus var. cordifolius
#> 5    Homalanthus populneus var. genuinus
#> 6      Homalanthus populneus var. laevis
#> 7       Homalanthus populneus var. minor
#> 8      Homalanthus populneus var. siccus
```

`Fuzzy.dist` is the distance to the name that was matched, which for
replaced synonyms is `Old.name` (here, varieties replaced by their
species).

## 5. Names that need more than spelling corrections

By default,
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
uses the matching steps of WorldFlora, with three corrections that can
each be switched off: a correctly spelled genus is not replaced by
another one (`Fuzzy.keep.genus`), fuzzy matches must have a similar
epithet (`Fuzzy.epithet.check`), and placeholders such as “indet.” or
“sp.” are not matched (`Fuzzy.skip.placeholder`). When neither a name
nor its first two words are found, it falls back to the genus.
WorldFloraFast offers three optional steps for such names, switched off
by default:

- **genus, then epithet** (`Fuzzy.genus`): for truncated or misspelled
  genera;
- **genus transfer** (`Fuzzy.transfer`): the same epithet in another
  genus of the family, when the backbone shows that species moved from
  the submitted genus to that genus;
- **strict genus fall-back** (`Fuzzy.one.strict`): the genus only when
  the first word is an accepted genus name, so that local names are not
  given a scientific name.

``` r

x <- c(
  "Reinwardtiod cinerum", "Chrysophyllum madagascariensis", "Palma colorada"
)
m0 <- WFO.match(x, WFO.data = WFO.example2026, verbose = FALSE)
default <- WFO.one(m0, verbose = FALSE)
edge <- WFO.match(x,
  WFO.data = WFO.example2026, verbose = FALSE,
  Fuzzy.genus = TRUE, Fuzzy.transfer = TRUE, Fuzzy.one.strict = TRUE
)
data.frame(
  submitted = x, default = default$scientificName,
  optional.steps = ifelse(edge$Matched, edge$scientificName, "(not matched)")
)
#>                        submitted       default              optional.steps
#> 1           Reinwardtiod cinerum   Reinwardtia Reinwardtiodendron cinereum
#> 2 Chrysophyllum madagascariensis Chrysophyllum          Gambeya boiviniana
#> 3                 Palma colorada       Phoenix               (not matched)
```

- “Reinwardtiod cinerum” is *Reinwardtiodendron cinereum*: the epithet
  is found in the genus that starts with “Reinwardtiod” (and not in
  *Reinwardtia*, which is closer by spelling).
- For “Chrysophyllum madagascariensis”, Sapotaceae contain several
  species with this epithet, but only *Gambeya madagascariensis* belongs
  to an accepted species (*Gambeya boiviniana*) that also has a synonym
  in *Chrysophyllum* (*Chrysophyllum boivinianum*): *Chrysophyllum*
  species of Madagascar were moved to *Gambeya*.
- “Palma colorada” is a local name. *Palma* Mill. is a synonym of
  *Phoenix*, so the genus fall-back is not used and the name stays
  unmatched.

Matches found by these steps are flagged and should be checked. Fuzzy
matching cannot recognise every local name: names that are themselves in
the backbone (such as the genus *Guayaba*) are matched, and
[`agrep()`](https://rdrr.io/r/base/agrep.html) can find a local name
within a longer scientific name, giving a large `Fuzzy.dist`.

## 6. Explore

``` r

WFO.synonyms("Gambeya boiviniana", WFO.data = WFO.example2026, verbose = FALSE)
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
fam <- WFO.family("Gambeya boiviniana",
  WFO.data = WFO.example2026, verbose = FALSE
)
fam[, c("Family", "Order", "Node.1")]
#>         Family    Order   Node.1
#> 333 Sapotaceae Ericales Eudicots
WFO.url(edge[1, ])
#> [1] "http://worldfloraonline.org/taxon/wfo-0000404362"
```

[`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
lists the genera of a family, the species of a genus or the
infraspecific taxa of a species.

## 7. Other backbones

Any taxonomic list with identifiers, names, authors and accepted-name
identifiers can be used instead of the WFO:

``` r

mammals <- data.frame(
  id = c("M1", "M2"), name = c("Felis catus", "Felis domesticus"),
  author = c("Linnaeus, 1758", "Erxleben, 1777"), accepted = c("", "M1")
)
bb <- WFO.backbone(mammals,
  taxonID = "id", scientificName = "name",
  scientificNameAuthorship = "author", acceptedNameUsageID = "accepted"
)
m <- WFO.match("Felis domestica", WFO.data = bb, verbose = FALSE)
m[, c("spec.name", "scientificName", "Old.name")]
#>         spec.name scientificName         Old.name
#> 1 Felis domestica    Felis catus Felis domesticus
```

## Performance

With the WFO Plant List 2026-06 (1.66 million names), matching 50,000
records takes about 5 seconds, and a misspelled name about 0.3 seconds:

- the backbone is indexed once, so exact matches and accepted names are
  hash lookups;
- each distinct name is fuzzy-matched once (in parallel with `cores = n`
  on Linux and macOS);
- before each [`agrep()`](https://rdrr.io/r/base/agrep.html) search, an
  exact prefilter discards names that cannot be within the allowed
  number of edits;
- the index is kept for the next call with the same backbone, so that
  further calls take a fraction of a second. Keep the backbone as the
  data.table returned by
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  or
  [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md):
  a data.frame is copied at each call.

With `Fuzzy.keep.genus`, `Fuzzy.epithet.check` and
`Fuzzy.skip.placeholder` set to `FALSE` (the optional steps are off by
default), results are those of WorldFlora 1.14-5 apart from the
corrections listed in `news(package = "WorldFloraFast")`.

## Reference

Kindt, R. (2020). WorldFlora: An R package for exact and fuzzy matching
of plant names against the World Flora Online taxonomic backbone data.
*Applications in Plant Sciences* 8(9): e11388.
<https://doi.org/10.1002/aps3.11388>
