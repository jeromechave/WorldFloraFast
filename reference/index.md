# Package index

## Matching plant names

Match names against the World Flora Online backbone, keep one match per
name, and check fuzzy matches.

- [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  : Match plant names against the World Flora Online taxonomic backbone
- [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
  : Keep one match per submitted name
- [`WFO.spelling.check()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.spelling.check.md)
  : Check whether fuzzy matches are explained by misspellings

## Preparing names

Separate names and authors before matching.

- [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
  [`WFO.preprepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
  : Split full plant names into name and authorship

## Getting the backbone

Download, read and remember the World Flora Online Plant List.

- [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  [`download_classification()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  : Download the World Flora Online taxonomic backbone
- [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  [`read_classification()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  : Read and remember the taxonomic backbone

## Other backbones

- [`WFO.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)
  [`new.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)
  : Use another taxonomic backbone

## Exploring the backbone

- [`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  [`WFO.synonyms()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  [`WFO.family()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  [`WFO.url()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  : Browse the taxonomic backbone: lower taxa, synonyms, family and
  order, web links

## Data

- [`WFO.example2026`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.example2026.md)
  : Example subset of the World Flora Online taxonomic backbone (Plant
  List 2026-06)
- [`WFO.example`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.example.md)
  : Example subset of the World Flora Online taxonomic backbone
  (WorldFlora)
- [`vascular.families`](https://jeromechave.github.io/WorldFloraFast/reference/vascular.families.md)
  : Orders and higher classification of vascular plant families

## Deprecated

These functions still work, with a warning, and will be removed in a
later version.

- [`WFO.match.fuzzyjoin()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.fuzzyjoin.md)
  : Match plant names with other string distances (deprecated)
- [`WFO.acceptable.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.acceptable.match.md)
  : Deprecated: use WFO.spelling.check()

## Package

- [`WorldFloraFast`](https://jeromechave.github.io/WorldFloraFast/reference/WorldFloraFast-package.md)
  [`WorldFloraFast-package`](https://jeromechave.github.io/WorldFloraFast/reference/WorldFloraFast-package.md)
  : WorldFloraFast: fast standardization of plant names against the
  World Flora Online
