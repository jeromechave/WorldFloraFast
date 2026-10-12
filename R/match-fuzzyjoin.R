## --------------------------------------------------------------------------------------
## match-fuzzyjoin.R: WFO.match.fuzzyjoin(), matching with other string distances
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - WFO.match.fuzzyjoin(): arguments, steps (exact matches, then all names within
##       fuzzydist.max, then Fuzzy.min) and result columns.
##   Changed:
##     - Distances computed with stringdist::stringdist() once per distinct name, with an
##       exact length window for edit distances, instead of
##       fuzzyjoin::stringdist_left_join() (same matches; fuzzyjoin and dplyr no longer
##       needed).
##     - Name cleaning and post-processing shared with WFO.match() (utils-clean.R,
##       utils-postprocess.R).
##     - Subseq numbered 1, 2, ... after Fuzzy.min (WorldFlora kept gaps); hybrid
##       notation ignored in exact matching.
##   New in WorldFloraFast:
##     - Argument cores.
##     - Deprecated in 1.0.0 (slower and less accurate than WFO.match(); see its help page).
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

#' Match plant names with other string distances (deprecated)
#'
#' **Deprecated**: use [WFO.match()]. On a test of 100 misspelled names against the WFO
#' Plant List 2026-06, `WFO.match.fuzzyjoin()` took 2.7 times longer than [WFO.match()] and
#' matched fewer names with a truncated genus correctly (33 against 38 of 40); it has none
#' of the matching steps added in WorldFloraFast (`Fuzzy.genus`, `Fuzzy.transfer`,
#' `Fuzzy.one.strict`, `Fuzzy.epithet.check`). It will be removed in a later version.
#'
#' An alternative to [WFO.match()] that finds fuzzy matches by a string distance of
#' package \pkg{stringdist} (Levenshtein by default) within a maximum distance, rather than
#' by [agrep()]. In WorldFlora this function used `fuzzyjoin::stringdist_left_join()`;
#' WorldFloraFast computes the same matches with [stringdist::stringdist()] directly.
#'
#' @inheritParams WFO.match
#' @param stringdist.method Distance method of [stringdist::stringdist()], such as `"lv"`
#'   (Levenshtein), `"osa"`, `"dl"`, `"jw"` or `"qgram"`.
#' @param fuzzydist.max Maximum distance of fuzzy matches.
#' @param Fuzzy.min If `TRUE`, keep only the fuzzy matches with the smallest distance.
#'
#' @details Names are cleaned as in [WFO.match()]. Names without an exact match are compared
#' with all backbone names, once per distinct name; for the edit distances `"lv"`, `"osa"`,
#' `"dl"` and `"hamming"`, names whose number of characters differs by more than
#' `fuzzydist.max` are skipped, which does not change the results. Requires the
#' \pkg{stringdist} package.
#'
#' @return As [WFO.match()], without columns `Fuzzy.toomany`, `Fuzzy.two`, `Fuzzy.one` and
#'   `First.dist`. `Fuzzy.dist` is the distance of `stringdist.method`. Candidates are
#'   numbered 1, 2, ... in `Subseq` (WorldFlora kept the numbers from before `Fuzzy.min`).
#' @seealso [WFO.match()], [WFO.one()]
#' @keywords internal
#' @export
#' @examplesIf requireNamespace("stringdist", quietly = TRUE)
#' data(WFO.example2026)
#' m <- suppressWarnings(WFO.match.fuzzyjoin(
#'   c("Faidherbia albida", "Omalanthus populneus", "Pygeum africanum"), WFO.data = WFO.example2026))
#' m[, c("spec.name", "Fuzzy.dist", "scientificName")]
WFO.match.fuzzyjoin <- function(
    spec.data=NULL, WFO.file=NULL, WFO.data=NULL,
    no.dates=TRUE,
    spec.name="spec.name",
    Authorship="Authorship",
    stringdist.method="lv", fuzzydist.max=4,
    Fuzzy.min=TRUE,
    acceptedNameUsageID.match=TRUE,
    squish=TRUE,
    spec.name.tolower=FALSE, spec.name.nonumber=TRUE, spec.name.nobrackets=TRUE,
    spec.name.sub=TRUE,
    sub.pattern=c(" sp[.] A", " sp[.] B", " sp[.] C", " sp[.]", " spp[.]", " pl[.]", " indet[.]", " ind[.]", " gen[.]", " g[.]", " fam[.]",
        " nov[.]", " prox[.]", " cf[.]", " aff[.]", " s[.]s[.]", " s[.]l[.]", " p[.]p[.]", " p[.] p[.]", "[?]", " inc[.]", " stet[.]",
        "Ca[.]", "nom[.] cons[.]", "nom[.] dub[.]", " nom[.] err[.]", " nom[.] illeg[.]", " nom[.] inval[.]", " nom[.] nov[.]",
        " nom[.] nud[.]", " nom[.] obl[.]", " nom[.] prot[.]", " nom[.] rej[.]", " nom[.] supp[.]", " sensu auct[.]"),
    cores=1
)
{
    .Deprecated("WFO.match", package = "WorldFloraFast",
                msg = "WFO.match.fuzzyjoin() is deprecated and will be removed; use WFO.match().")
    if (!missing(no.dates)) .no.dates.deprecated()
    if (!requireNamespace("stringdist", quietly = TRUE)) stop("Please install the stringdist package")
    spec.data <- .as.spec.data(spec.data)
    if (nrow(spec.data) == 0) stop("No names were submitted")
    if (!spec.name %in% names(spec.data)) stop("Variable '", spec.name, "' not found in spec.data")
    WFO.data <- .read.WFO(WFO.file, WFO.data)
    WFO.cols <- .WFO.columns(WFO.data)
    has.auth <- Authorship %in% names(spec.data)
    spec.data <- .rename.conflicts(spec.data, WFO.cols, Authorship, acceptedNameUsageID.match)
    spec.data <- .clean.spec.names(spec.data, spec.name, squish = squish,
        spec.name.tolower = spec.name.tolower, spec.name.sub = spec.name.sub, sub.pattern = sub.pattern,
        spec.name.nobrackets = spec.name.nobrackets, spec.name.nonumber = spec.name.nonumber)

    n <- nrow(spec.data)
    spec.data$Unique <- rep(TRUE, n)
    spec.data$Matched <- rep(TRUE, n)
    spec.data$Fuzzy <- rep(FALSE, n)
    spec.data$Fuzzy.dist <- rep(NA_real_, n)
    if (has.auth) spec.data$Auth.dist <- rep(Inf, n)
    spec.data$OriSeq <- seq_len(n)
    spec.data$Subseq <- rep(1, n)

    WFO.dt <- .as.dt(WFO.data)
    index <- .cached(WFO.dt, "index.name", function() .build.index(.hybrid.key(WFO.dt$scientificName)))
    nm <- .hybrid.key(spec.data[[spec.name]])

    ## exact matches
    rows <- .lookup(index, nm)
    dists <- vector("list", n)
    subseq <- vector("list", n)
    remain <- which(lengths(rows) == 0)

    ## fuzzy matches, once per unique name
    if (length(remain) > 0) {
        message("Checking for fuzzy matches for ", length(remain), " records")
        todo <- unique(nm[remain])
        len.u <- nchar(index$u)
        one <- function(q) {
            h <- .stringdist.hits(q, index, stringdist.method, fuzzydist.max, len.u)
            if (length(h$ids) == 0) return(list(rows = integer(0), dist = numeric(0)))
            r <- .rows.of(index, h$ids)
            list(rows = r, dist = rep(h$dist, index$cnt[h$ids]))
        }
        fz <- if (cores > 1 && .Platform$OS.type == "unix") parallel::mclapply(todo, one, mc.cores = cores)
              else lapply(todo, one)
        k <- match(nm[remain], todo)
        for (j in seq_along(remain)) {
            z <- fz[[k[j]]]
            if (length(z$rows) == 0) next
            ## backbone order within a submitted name, as fuzzyjoin returns them
            o <- order(z$rows)
            r <- z$rows[o]; d <- z$dist[o]
            ## as in WorldFlora, candidates keep the number they had before Fuzzy.min
            pos <- seq_along(r)
            if (Fuzzy.min) { keep <- d == min(d); r <- r[keep]; d <- d[keep]; pos <- pos[keep] }
            rows[[remain[j]]] <- r
            dists[[remain[j]]] <- d
            subseq[[remain[j]]] <- pos
        }
        spec.data$Fuzzy[remain] <- lengths(rows[remain]) > 0
    }

    ex <- .expand.matches(spec.data, rows)
    has.pos <- lengths(subseq) > 0
    if (any(has.pos)) {
        r.fz <- ex$rec %in% which(has.pos) & !is.na(ex$WFO.row)
        ex$out$Subseq[r.fz] <- unlist(subseq[has.pos], use.names = FALSE)
    }
    out <- ex$out; rec <- ex$rec; WFO.row <- ex$WFO.row
    is.fz <- rec %in% remain & !is.na(WFO.row)
    out$Fuzzy.dist[is.fz] <- unlist(dists, use.names = FALSE)
    out$taxonID <- as.character(WFO.dt$taxonID[WFO.row])
    WFO.part <- WFO.dt[WFO.row, setdiff(WFO.cols, "taxonID"), with = FALSE]
    out <- cbind(out, as.data.frame(WFO.part, stringsAsFactors = FALSE))
    rownames(out) <- NULL

    .finish.match(out, WFO.data, WFO.cols, Authorship, has.auth, acceptedNameUsageID.match)
}
