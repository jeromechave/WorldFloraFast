# ----------------------------------------------------------------------------
# utils-index.R: backbone index and expansion of matches to output rows
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - none
#   Changed:
#     - none
#   New in WorldFloraFast:
#     - The whole file: index of the backbone (distinct names -> rows), lookups,
#       Subseq numbering, expansion of matches to one row per candidate, and
#       (1.0.0) the cache of index and matching context for the last backbone
#       used.
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Backbone index: unique scientific names and, for each, the backbone rows that
# carry the name (in backbone order). Built once per call in O(N); lookups are
# O(1).
# ----------------------------------------------------------------------------
.build.index <- function(names) {
  names <- as.character(names)
  u <- unique(names)
  # byte-level scans need UTF-8 (see .agrep.ids())
  if (any(Encoding(u) == "latin1")) {
    u.utf8 <- enc2utf8(u)
    names <- u.utf8[match(names, u)]
    u <- u.utf8
  }
  grp <- match(names, u)
  cnt <- tabulate(grp, nbins = length(u))
  ord <- order(
    grp,
    method = "radix"
  ) # stable: keeps backbone order within names
  start <- cumsum(c(1L, cnt))[seq_along(u)]
  list(
    u = u, cnt = cnt, ord = ord, start = start, n = length(names),
    u.nchar = nchar(u, type = "chars", allowNA = TRUE, keepNA = FALSE)
  )
}

# backbone rows for unique-name ids (vector), concatenated in the order of ids
.rows.of <- function(index, ids) {
  ids <- ids[!is.na(ids)]
  if (length(ids) == 0) {
    return(integer(0))
  }
  len <- index$cnt[ids]
  pos <- rep(index$start[ids], len) + sequence(len) - 1L
  index$ord[pos]
}

# backbone rows for every query string: list (one element per query)
.lookup <- function(index, queries) {
  id <- match(queries, index$u)
  lapply(id, function(i) if (is.na(i)) integer(0) else .rows.of(index, i))
}

# Subseq numbering within OriSeq groups (rows already ordered by OriSeq)
.subseq <- function(oriseq) {
  r <- rle(oriseq)
  sequence(r$lengths)
}

# Expand records to one row per matched backbone row. rows: list with backbone
# rows per record. Returns out (records repeated) + WFO.row.
.expand.matches <- function(spec.data, rows) {
  n <- nrow(spec.data)
  len <- lengths(rows)
  rec <- rep(seq_len(n), pmax(len, 1L))
  out <- spec.data[rec, , drop = FALSE]
  out$Subseq <- as.numeric(.subseq(rec)) # double, as in WorldFlora
  out$Unique[rec %in% which(len > 1)] <- FALSE
  out$Matched[rec %in% which(len == 0)] <- FALSE
  WFO.row <- rep(NA_integer_, length(rec))
  WFO.row[out$Subseq <= len[rec]] <- unlist(rows, use.names = FALSE)
  list(out = out, rec = rec, WFO.row = WFO.row)
}

# ----------------------------------------------------------------------------
# Cache of the index and matching context of the last backbone used, so that
# repeated calls (and WFO.browse(), WFO.synonyms(), WFO.family(), which call
# WFO.match()) do not rebuild them (about 5 s for the 1.6 million names of WFO
# 2026-06). The key combines the memory addresses of the key columns, the number
# of rows and a checksum of a sample of rows, so that a changed backbone is
# noticed. options(WorldFloraFast.cache = FALSE) switches the cache off.
# ----------------------------------------------------------------------------
.cache <- new.env(parent = emptyenv())

.backbone.key <- function(WFO.dt) {
  cols <- intersect(
    c(
      "taxonID",
      "scientificName",
      "acceptedNameUsageID",
      "taxonomicStatus",
      "family",
      "genus"
    ),
    names(WFO.dt)
  )
  n <- nrow(WFO.dt)
  i <- unique(round(seq(1, max(n, 1), length.out = min(n, 2000))))
  sample.txt <- unlist(
    lapply(cols, function(v) as.character(WFO.dt[[v]][i])),
    use.names = FALSE
  )
  paste(
    n,
    paste(
      vapply(cols, function(v) data.table::address(WFO.dt[[v]]), ""),
      collapse = ","
    ),
    sum(as.numeric(nchar(
      sample.txt,
      type = "bytes",
      keepNA = FALSE
    )) * seq_along(sample.txt)),
    sep = "|"
  )
}

# value of `build()` for this backbone and `what`, from the cache when possible
.cached <- function(WFO.dt, what, build) {
  if (!isTRUE(getOption("WorldFloraFast.cache", TRUE))) {
    return(build())
  }
  key <- .backbone.key(WFO.dt)
  if (!identical(.cache$key, key)) {
    rm(list = ls(.cache), envir = .cache)
    .cache$key <- key
  }
  if (is.null(.cache[[what]])) .cache[[what]] <- build()
  .cache[[what]]
}
