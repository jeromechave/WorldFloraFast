# Releases of the backbone in the data folder

Lists the releases of the World Flora Online Plant List downloaded by
[`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
to the per-user data folder of WorldFloraFast, and deletes the ones that
are no longer needed (each takes about 1 GB).

## Usage

``` r
WFO.releases(remove = NULL)
```

## Arguments

- remove:

  Releases to delete, as given in column `release` of the result (for
  example `"2025-12"`). `NULL` deletes nothing.

## Value

A data.frame with one row per release, newest first: `release`
(version), `record.id` and `doi` (Zenodo), `downloaded` (date),
`size.mb`, `in.use` (`TRUE` for the release that
[`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
would use) and `file`. The data folder is given as attribute `folder`.

## Details

By default,
[`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
saves each release in its own folder of the per-user data folder of
WorldFloraFast, given by
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html)
(`R_user_dir("WorldFloraFast", "data")`, subfolder `wfo`). This folder
is the same in every session and project, and is kept when the package
or R are reinstalled. Its location can be changed with the environment
variable `R_USER_DATA_DIR`.

In a new session,
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
(without `WFO.data` or `WFO.file`),
[`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
and
[`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
(without `WFO.file`) use the backbone file remembered by the last call
to
[`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
or
[`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md);
if that file no longer exists, they use the newest release in the data
folder.

Releases downloaded elsewhere with `WFO.download(save.dir = ...)` are
not listed or deleted.

## See also

[`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md),
[`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)

## Examples

``` r
if (FALSE) { # \dontrun{
WFO.releases() # releases in the data folder
WFO.releases(remove = "2025-12") # delete an old release
} # }
```
