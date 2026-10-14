# WorldFloraFast: fast standardization of plant names against the World Flora Online

Matches plant names against a static copy of the World Flora Online
(WFO) taxonomic backbone, exactly or with fuzzy matching, and finds the
currently accepted names. WorldFloraFast is a faster, refactored
derivative of the WorldFlora package (Kindt 2020); functions and
arguments are the same.

## Workflow

1.  Obtain the backbone with
    [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
    (later sessions:
    [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
    or
    [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)).

2.  Optionally split full names with authors via
    [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md).

3.  Match names with
    [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md).

4.  Keep one match per submitted name with
    [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md).

5.  Explore with
    [`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md),
    [`WFO.synonyms()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md),
    [`WFO.family()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
    and
    [`WFO.url()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md);
    check whether fuzzy matches are explained by misspellings with
    [`WFO.spelling.check()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.spelling.check.md).

Other taxonomic lists can be used as backbone via
[`WFO.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md).

## Speed

The backbone is indexed once per call, so that exact matches, accepted
names and genera are found with hash lookups. Fuzzy matching is done
once per distinct name, optionally in parallel (argument `cores`), and
each [`agrep()`](https://rdrr.io/r/base/agrep.html) search is preceded
by an exact prefilter (see
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)).
Results are those of WorldFlora 1.14-5, apart from the corrections
listed in the NEWS file (`news(package = "WorldFloraFast")`).

## Compatibility with WorldFlora

By default, functions behave as in WorldFlora 1.14-5: same arguments,
defaults, result columns (names, order, types) and example data set.
Only errors of WorldFlora are corrected (listed in the NEWS file); in
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
three of these corrections can be switched off (`Fuzzy.keep.genus`,
`Fuzzy.epithet.check`, `Fuzzy.skip.placeholder`). The matching steps
added by WorldFloraFast (`Fuzzy.genus`, `Fuzzy.transfer`,
`Fuzzy.one.strict`) are optional and switched off by default.

## Cache

The index of the backbone and the context used by the matching steps
(about 5 s to build for the 1.6 million names of the WFO Plant List
2026-06) are kept for the last backbone used, so that further calls with
the same `WFO.data` take a fraction of a second. This works when
`WFO.data` is a data.table, as returned by
[`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
(a data.frame is copied at each call). A changed backbone is detected.
Set `options(WorldFloraFast.cache = FALSE)` to switch the cache off.

## Deprecated

[`WFO.match.fuzzyjoin()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.fuzzyjoin.md),
[`WFO.acceptable.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.acceptable.match.md)
(replaced by
[`WFO.spelling.check()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.spelling.check.md))
and the argument `no.dates` of
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
still work, with a warning, and will be removed in a later version.

## Provenance

WorldFloraFast is derived from WorldFlora 1.14-5 (Roeland Kindt, GPL-3).
Each R source file of the package starts with a caption that lists what
it inherits from WorldFlora, what was changed, and what is new; the NEWS
file lists all changes of results.

## References

Kindt, R. (2020). WorldFlora: An R package for exact and fuzzy matching
of plant names against the World Flora Online taxonomic backbone data.
Applications in Plant Sciences 8(9): e11388.
[doi:10.1002/aps3.11388](https://doi.org/10.1002/aps3.11388)

World Flora Online. An Online Flora of All Known Plants.
<https://www.worldfloraonline.org>

## See also

Useful links:

- <https://jeromechave.github.io/WorldFloraFast/>

- <https://github.com/jeromechave/WorldFloraFast>

- Report bugs at <https://github.com/jeromechave/WorldFloraFast/issues>

## Author

**Maintainer**: Jérôme Chave <jerome.chave@cnrs.fr>

Authors:

- Roeland Kindt ([ORCID](https://orcid.org/0000-0002-7672-0712)) (author
  of the WorldFlora package from which this package is derived)
  \[copyright holder\]
