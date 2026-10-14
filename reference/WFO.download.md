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
  save.dir = getwd(),
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

  Directory for the backbone (created if needed).

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

[`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md),
[`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# download (or find) the backbone, remember it and load it as WFO.data
WFO.download(save.dir = "wfo_data")

# later: look for a newer release
WFO.download(save.dir = "wfo_data", update = TRUE)

# a specific release: the WFO Plant List 2026-06
WFO.download(save.dir = "wfo_2026_06", record.id = "20782718", pinned = TRUE)
} # }
```
