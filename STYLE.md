# Code style of WorldFloraFast

WorldFloraFast follows the [tidyverse style
guide](https://style.tidyverse.org/), checked with
[lintr](https://lintr.r-lib.org/) (configuration in `.lintr`) and
formatted with [styler](https://styler.r-lib.org/):

``` r

styler::style_pkg()      # format the code
lintr::lint_package()    # check it; should report no lints
```

## Recorded decisions

`.lintr` cannot contain comments, so the decisions it encodes are
explained here.

1.  **Names of the WorldFlora API are kept.** WorldFloraFast keeps the
    functions and arguments of WorldFlora so that existing scripts keep
    working. 15 of the 17 exported functions use dots (`WFO.match`,
    `new.backbone`), as do 52 of the 80 argument names, 34 of them with
    capitals (`Fuzzy.min`, `WFO.data`, `Genus`). These names are not
    changed. In `.lintr`, these names match the pattern
    `worldflora_api`: names starting with `WFO.` (exported functions,
    their arguments such as `WFO.data`, and internal objects that refer
    to the backbone, such as `WFO.dt`), argument names with capitals
    (`Authorship`, `Genus`, `Species`, `Infraspecific`,
    `Infraspecific.rank`, `First.dist`, `Auth.dist`, `Old.author.dist`,
    `acceptedNameUsageID.match`, `Fuzzy` and `Fuzzy.*`), and the Darwin
    Core column names used as arguments of
    [`WFO.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)
    (`taxonID`, `scientificName`, `scientificNameAuthorship`,
    `acceptedNameUsageID`, `taxonomicStatus`).
2.  **Dotted lower-case names are accepted** (`dotted.case`), the
    convention of WorldFlora used throughout the code (`spec.data`,
    `n.found`). New code may use `snake_case`.
3.  **Internal functions and constants start with a dot**
    (`.fuzzy.one.name()`, `.HYBRID`), so that they are not mistaken for
    exported functions; and `X` and `FUN`, the arguments of
    `.parallel.lapply()`, follow the convention of base R’s
    [`lapply()`](https://rdrr.io/r/base/lapply.html). Both match the
    pattern `internal` in `.lintr`. (The patterns use non-capturing
    groups, `(?:...)`: lintr 3.1 fails on capturing groups in these
    patterns.)
4.  **Line length: 80 characters**, as in the style guide, for code,
    comments and documentation.
5.  **Cyclomatic complexity: at most 75** instead of 15. Eight functions
    are above 15 (`.fuzzy.one.name()` 73,
    [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md),
    [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
    `.prepare.one()`,
    [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md),
    `.clean.spec.names()`, `.genus.epithet()`,
    [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md));
    the limit records the current maximum so that complexity does not
    grow, and should be lowered as these functions are split.

## Names chosen in 1.0.3

- [`WFO.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)
  is the name of
  [`new.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md),
  consistent with the other functions;
  [`new.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md),
  the name in WorldFlora, remains an alias with the same arguments and
  results (it reads like an S3 method `new()` for a class “backbone”,
  which it is not).
- [`download_classification()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  and
  [`read_classification()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md),
  the only snake_case exported functions (names of the original
  stand-alone download script), are deprecated in favour of
  [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  and
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md);
  they still work, with a warning.
