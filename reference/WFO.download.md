# Download the World Flora Online taxonomic backbone

Downloads the latest `classification.csv` of the World Flora Online
(WFO) Plant List from Zenodo (<https://zenodo.org/records/18007552> and
its newer versions), unless a copy is already present. Downloads are
verified with the published MD5 checksum and retried with exponential
back-off.

## Usage

``` r
WFO.download(
  WFO.url = NULL,
  save.dir = NULL,
  WFO.remember = TRUE,
  timeout = 3600,
  force = FALSE,
  update = FALSE,
  record.id = "18007552",
  pinned = FALSE,
  ...
)

download_classification(
  out_dir = "wfo_data",
  force = FALSE,
  update = FALSE,
  record_id = "18007552",
  pinned = FALSE
)
```

## Arguments

- WFO.url:

  If given, download a zip archive from this address and extract
  `classification.csv` (or `classification.txt`) instead of using
  Zenodo.

- save.dir, out_dir:

  Directory for the backbone (created if needed). With `save.dir = NULL`
  (default), each release is saved in its own folder of the per-user
  data folder of WorldFloraFast (see Details and
  [`WFO.releases()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.releases.md));
  `save.dir = getwd()` gives the default of WorldFlora (the working
  directory).

- WFO.remember:

  If `TRUE`, remember the location of the file and load the backbone as
  `WFO.data` with
  [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md).

- timeout:

  Minimum timeout in seconds for the download.

- force:

  If `TRUE`, download again even if a copy exists.

- update:

  If `TRUE` and a copy exists, check Zenodo for a newer release and
  download it if there is one. Without it, an existing copy is used and
  Zenodo is not contacted. If Zenodo cannot be reached, the local copy
  is kept with a warning.

- record.id, record_id:

  Zenodo record to start from (any version of the WFO Plant List).

- pinned:

  If `TRUE`, use `record.id` itself instead of its newest version.

- ...:

  Further arguments for
  [`utils::download.file()`](https://rdrr.io/r/utils/download.file.html)
  (with `WFO.url` only).

## Value

The path of the backbone file (invisibly), with attributes `version`,
`record_id` and `doi` (`NA` when unknown).

## Details

By default (`save.dir = NULL`), the backbone is saved in the per-user
data folder of WorldFloraFast, given by
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html)
(`R_user_dir("WorldFloraFast", "data")`, subfolder `wfo`), in a folder
named after the release, such as `wfo/2026-06/classification.csv`. This
folder is the same in every session and project, and is kept when the
package or R are reinstalled;
[`WFO.releases()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.releases.md)
lists the releases it holds and deletes old ones. Without `update` or
`force`, an existing release is used and Zenodo is not contacted (unless
`pinned = TRUE` asks for a given release, which is downloaded to its own
folder if needed); with `update = TRUE`, a newer release is downloaded
to a new folder and the older ones are kept. With `WFO.url`, the file is
saved in the subfolder `from_url`. WorldFlora saved the backbone in the
working directory, which `save.dir = getwd()` still does.

In a new session,
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
without `WFO.data` or `WFO.file`,
[`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
and
[`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
use the backbone file of the last download, or else the newest release
in the data folder.

Next to the backbone, `classification_source.json` records the Zenodo
record, version, DOI, source file, MD5 checksum and date of the
download. A mirror can be used by setting the environment variable
`ZENODO_BASE`; `ZENODO_RETRY_WAIT` sets the first waiting time (in
seconds) between retries.

`download_classification()` is deprecated: use `WFO.download()`. It used
the argument names of the stand-alone download script, unlike the other
functions, and does not remember or load the backbone
(`WFO.remember = FALSE`).

## See also

[`WFO.releases()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.releases.md),
[`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md),
[`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# download (or find) the backbone in the data folder, remember it and load it
# as WFO.data
WFO.download()

# in a later session: nothing to download, WFO.match() finds the backbone
WFO.match("Faidherbia albida")

# look for a newer release (kept next to the older ones)
WFO.download(update = TRUE)
WFO.releases()

# a specific release: the WFO Plant List 2026-06
WFO.download(record.id = "20782718", pinned = TRUE)

# another folder, such as a shared drive or the project folder (as in
# WorldFlora)
WFO.download(save.dir = "wfo_data")
} # }
```
