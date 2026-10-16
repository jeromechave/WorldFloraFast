# WorldFloraFast

Website: <https://jeromechave.github.io/WorldFloraFast/>

Fast matching of plant names against the World Flora Online (WFO)
taxonomic backbone. A refactored derivative of
[WorldFlora](https://CRAN.R-project.org/package=WorldFlora) (Kindt 2020,
*Applications in Plant Sciences* 8: e11388) with the same functions and
arguments, 10-15x faster fuzzy matching, and much faster exact matching
on large inputs (see below), plus the corrections listed in `NEWS.md`.

``` r

install.packages("remotes")
remotes::install_github("jeromechave/WorldFloraFast",
                        dependencies = TRUE, build_vignettes = TRUE)
library(WorldFloraFast)

WFO.download()        # latest WFO Plant List (2026-06) from Zenodo, to a per-user data folder; loads WFO.data
res <- WFO.match(c("Faidherbia albida", "Acacia nilotca", "Compositae"), WFO.data = WFO.data)
# optional matching steps for difficult names
res2 <- WFO.match(c("Reinwardtiod cinerum", "Palma colorada"), WFO.data = WFO.data,
                  Fuzzy.genus = TRUE, Fuzzy.transfer = TRUE, Fuzzy.one.strict = TRUE)
one <- WFO.one(res)                         # one row per submitted name

# later sessions
WFO.remember()                              # reload the remembered backbone as WFO.data
WFO.download(update = TRUE)   # check for a newer release
WFO.releases()                # releases downloaded, and where
```

Works with the WFO Plant List 2026-06 and earlier releases. By default
it behaves as WorldFlora (same arguments and result columns), with
errors corrected: a correctly spelled genus is kept, short epithets are
not replaced, and placeholders such as “indet.” are not matched.
Optional matching steps (`Fuzzy.genus`, `Fuzzy.transfer`,
`Fuzzy.one.strict`) handle truncated genera (“Reinwardtiod cinerum”),
species moved to another genus (“Chrysophyllum madagascariensis” -\>
*Gambeya boiviniana*), short epithets, and local names such as “Palma
colorada”, which are then not given a scientific genus.

## Functions

| Task | Functions |
|----|----|
| Get the backbone | [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md), [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md), [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md) |
| Separate names and authors | [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md), [`WFO.preprepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md) |
| Match names | [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md) |
| One match per name | [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md) |
| Explore | [`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md), [`WFO.synonyms()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md), [`WFO.family()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md), [`WFO.url()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md) |
| Check fuzzy matches | [`WFO.spelling.check()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.spelling.check.md) |
| Other backbones | [`WFO.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md) (WorldFlora name: [`new.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)) |

Start with
[`vignette("WorldFloraFast")`](https://jeromechave.github.io/WorldFloraFast/articles/WorldFloraFast.md);
`news(package = "WorldFloraFast")` lists the differences with
WorldFlora.

## Speed

On the WFO Plant List 2026-06 (1.66 million names), one core:

| Task | Time |
|----|---:|
| 50,000 records of correctly spelled names (5,000 distinct) | 5 s |
| 200 misspelled names | 59 s (0.3 s per name) |
| a further call on the same backbone, one name | under 0.5 s |

The first call of a session also builds the index of the backbone (about
5 s). Compared with WorldFlora 1.14-5 on a backbone of 1.37 million
names: 600 correctly spelled names 51 s -\> under 3 s; misspelled names
about 4 s -\> 0.3 s each. Use `cores = n` in
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
for large sets of misspelled names (Linux, macOS).

## How it is faster without changing results

- The backbone is indexed once; all lookups are hash lookups instead of
  full-table scans.
- Each distinct name is fuzzy-matched once, however often it occurs.
- Before each [`agrep()`](https://rdrr.io/r/base/agrep.html) search, an
  exact pigeonhole prefilter discards names that cannot match: with at
  most *k* edits, one of *k* + 1 pieces of the name must occur
  unchanged.
- All post-processing is vectorised.

## Validation

Outputs were compared record by record with WorldFlora 1.14-5 on the
same data under 8 option settings of
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
(with the new matching steps switched off), 5 of
[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md),
and for
[`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md),
[`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
and the other functions. With the optional steps, a sample of 1,137
names of the WFO Plant List 2026-06 with known answers is matched
correctly for all 1,000 exact names, all 60 names with a typo and 38 of
40 names with a truncated genus. Every difference is one of the
documented corrections in `NEWS.md`. Unit tests in `tests/` cover each
correction.
