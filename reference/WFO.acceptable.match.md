# Deprecated: use WFO.spelling.check()

`WFO.acceptable.match()` (from WorldFlora) returns `TRUE` when the
submitted and matched names are identical or differ only by common
misspellings, i.e. when
[`WFO.spelling.check()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.spelling.check.md)
gives "identical" or "spelling corrected". It is kept for compatibility
and will be removed in a later version.

## Usage

``` r
WFO.acceptable.match(x, spec.name = "spec.name", no.vowels = FALSE)
```

## Arguments

- x:

  Results of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  or
  [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md).

- spec.name:

  Name of the column with the submitted names.

- no.vowels:

  If `TRUE`, also treat differences in vowels as misspellings.

## Value

A logical vector (`NA` where no name was matched).
