## --------------------------------------------------------------------------------------
## read.R: WFO.read() and WFO.remember()
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - WFO.remember(): arguments, and loading the backbone as WFO.data.
##   Changed:
##     - WFO.remember() saves the location in the user configuration directory
##       (tools::R_user_dir()) instead of inside the installed package; locations saved
##       by WorldFlora are still found; reports the WFO version when known.
##   New in WorldFloraFast:
##     - WFO.read(): the single reader of the backbone (all columns as character, select,
##       core.only), used by all functions; WorldFlora read with fread() in each
##       function.
##     - read_classification(): from the download_classification.R script.
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

#' Read and remember the taxonomic backbone
#'
#' `WFO.read()` reads the backbone file. `WFO.remember()` remembers where the file is and
#' loads it, so that later sessions need neither the path nor a new download.
#'
#' @param WFO.file,path Path to the backbone (`classification.csv` or
#'   `classification.txt`), or a directory that contains it. For `WFO.read()` and
#'   `WFO.remember()`, `NULL` uses the remembered location.
#' @param select Names of columns to read (saves time and memory).
#' @param core.only If `TRUE`, read only the columns used by this package: `taxonID`,
#'   `scientificName`, `scientificNameAuthorship`, `taxonRank`, `taxonomicStatus`,
#'   `nomenclaturalStatus`, `acceptedNameUsageID`, `family`, `genus`, `specificEpithet`,
#'   `verbatimTaxonRank` and `infraspecificEpithet`. Ignored if `select` is given.
#' @param as.data.frame,as_data_frame If `TRUE`, return a data.frame instead of a
#'   data.table.
#' @param WFO.data Name of the object created by `WFO.remember()`.
#' @param WFO.pos Environment position for that object, as argument `pos` of [assign()]
#'   (1: the global environment).
#' @param ... Further arguments for `WFO.read()`, such as `core.only`.
#'
#' @details `WFO.read()` uses [data.table::fread()]. All columns are read as character, so
#' that identifiers such as "wfo-0000000001" and codes such as "NA" are never changed or
#' turned into missing values. The separator is detected (the WFO file is tab-separated
#' despite its extension). Selected columns that are not in the file are skipped with a
#' warning.
#'
#' `WFO.remember()` saves the location in the user configuration directory
#' ([tools::R_user_dir()]); a location saved by WorldFlora is also found. With
#' `WFO.file = NULL`, the matching functions use the remembered backbone too.
#'
#' `read_classification()` uses the argument names of the stand-alone script from which
#' these functions were derived.
#'
#' @return `WFO.read()`: a data.table (or data.frame). `WFO.remember()`: the path of the
#'   backbone (invisibly); the backbone is assigned to `WFO.data`.
#' @seealso [WFO.download()]
#' @export
#' @examples
#' f <- tempfile(fileext = ".csv")
#' data(WFO.example2026)
#' data.table::fwrite(WFO.example2026, f, sep = "\t")
#' bb <- WFO.read(f, core.only = TRUE)
#' str(bb)
#' \dontrun{
#' WFO.remember("wfo_data/classification.csv")   # remember and load as WFO.data
#' WFO.remember()                                 # in a later session
#' }
WFO.read <- function(
    WFO.file=NULL, select=NULL, core.only=FALSE, as.data.frame=FALSE
)
{
    if (is.null(WFO.file)) {
        WFO.file <- .remembered.file()
        if (is.null(WFO.file)) {
            stop("No WFO.file given and no location remembered; use WFO.download() or WFO.remember(WFO.file=...)",
                 call. = FALSE)
        }
    }
    if (dir.exists(WFO.file)) {
        cand <- file.path(WFO.file, c(.WFO.TARGET.FILE, "classification.txt"))
        cand <- cand[file.exists(cand)]
        if (!length(cand)) stop("No classification.csv or classification.txt in directory ", WFO.file, call. = FALSE)
        WFO.file <- cand[1]
    }
    if (!.file.ok(WFO.file)) stop("File not found or empty: ", WFO.file, call. = FALSE)

    if (is.null(select) && core.only) select <- .WFO.CORE.COLUMNS
    if (!is.null(select)) {
        header <- names(data.table::fread(WFO.file, nrows = 0, encoding = "UTF-8"))
        missing <- setdiff(select, header)
        if (length(missing)) warning("Columns not in ", basename(WFO.file), ": ",
                                     paste(missing, collapse = ", "), call. = FALSE)
        select <- intersect(select, header)
    }
    ## All columns as character: IDs and codes such as "NA" are never mangled or turned
    ## into missing values. The separator is detected (WFO's .csv is tab-separated).
    args <- list(WFO.file, colClasses = "character", na.strings = NULL, encoding = "UTF-8",
                 data.table = !as.data.frame, showProgress = interactive())
    if (!is.null(select)) args$select <- select
    do.call(data.table::fread, args)
}

#' @rdname WFO.read
#' @export
read_classification <- function(path = file.path("wfo_data", "classification.csv"),
                                select = NULL, core.only = FALSE, as_data_frame = FALSE) {
    WFO.read(WFO.file = path, select = select, core.only = core.only, as.data.frame = as_data_frame)
}

#' @rdname WFO.read
#' @export
WFO.remember <- function(
    WFO.file=NULL, WFO.data="WFO.data", WFO.pos=1, ...
)
{
    if (!is.null(WFO.file)) {
        WFO.file1 <- normalizePath(WFO.file, mustWork = TRUE)
        rem <- .remember.path()
        dir.create(dirname(rem), showWarnings = FALSE, recursive = TRUE)
        data.table::fwrite(data.frame(WFO.file = WFO.file1, date = date()), file = rem, sep = "|")
    } else {
        WFO.file1 <- .remembered.file()
        if (is.null(WFO.file1)) stop("Location of WFO data was not provided earlier")
        message("Data sourced from: ", WFO.file1, " (", attr(WFO.file1, "date"), ")")
        WFO.file1 <- as.character(WFO.file1)
    }
    info <- .read.source.info(dirname(WFO.file1))
    if (!is.null(info)) message("WFO Plant List version ", info$version, " (", info$doi, ")")

    message("Reading WFO data")
    assign(WFO.data, WFO.read(WFO.file1, ...), pos = WFO.pos)
    message("The WFO data is now available from ", WFO.data)
    invisible(WFO.file1)
}

## Location of the file that remembers where the backbone is. Previous versions wrote
## into the installed package (etc/remember.txt), which fails on read-only libraries.
.remember.path <- function(pkg = "WorldFloraFast") file.path(tools::R_user_dir(pkg, which = "config"), "remember.txt")

.remembered.file <- function() {
    ## also finds a location saved by WorldFlora (>= 1.15 config dir, or older: inside the installed package)
    for (f in c(.remember.path(), .remember.path("WorldFlora"),
                system.file("etc", "remember.txt", package = "WorldFlora"))) {
        if (nzchar(f) && file.exists(f)) {
            saved <- data.table::fread(f, sep = "|", colClasses = "character")
            return(structure(as.character(saved$WFO.file[1]), date = saved$date[1]))
        }
    }
    NULL
}
