# ----------------------------------------------------------------------------
# utils-distance.R: fast approximate matching and string distances
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - none
#   Changed:
#     - none
#   New in WorldFloraFast:
#     - The whole file: exact pigeonhole prefilter before agrep() (.agrep.k(),
#       .agrep.ids(); since 1.0.0 with byte-level scans of only the names long
#       enough to contain a match), stringdist hits with a length window
#       (.stringdist.hits()), and distances for vectors of name pairs
#       (.pair.adist(); WorldFlora called adist() per row).
#     - .keep.genus(): a correctly spelled genus is kept (Fuzzy.keep.genus; #
#       1.0.1).
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Fast, *exact* replacement of agrep(pattern, x, max.distance = d, fixed =
# TRUE).
#
# agrep() finds approximate SUBSTRING matches with at most k edits. Splitting
# the pattern into k + 1 non-overlapping pieces, at least one piece must occur
# unchanged in every match (pigeonhole principle: each edit can destroy at most
# one piece). A cheap fixed-string scan for the pieces therefore discards nearly
# all candidates without losing any true match; the expensive TRE agrep() then
# only runs on the remaining handful of names. Results are identical to a full
# agrep() scan.
# ----------------------------------------------------------------------------
# Number of edits k that agrep() allows for `pattern` (fractions are relative to
# the pattern length; rounded up, using the byte length so that k is never too
# small)
.agrep.k <- function(pattern, max.distance) {
  if (max.distance >= 1) {
    return(ceiling(max.distance))
  }
  # conservative (byte length >= character length): a larger k only weakens the
  # filter
  ceiling(max.distance * nchar(pattern, type = "bytes"))
}

# Indices of the names in `u` that agrep(pattern, u, max.distance) would return
# u.nchar: number of characters of u (from the index). A match with at most k
# edits needs a name of at least nchar(pattern) - k characters, so shorter names
# are not scanned. The scan compares bytes (useBytes = TRUE, about twice as
# fast); names and pattern are both UTF-8, so byte and character substrings are
# the same.
.agrep.ids <- function(
  pattern,
  u,
  max.distance,
  min.piece = 3L,
  u.nchar = NULL
) {
  k <- .agrep.k(pattern, max.distance)
  n <- nchar(pattern)
  cand <- NULL
  if (k >= 0 && n %/% (k + 1L) >= min.piece) {
    cuts <- round(seq(0, n, length.out = k + 2L))
    pieces <- enc2utf8(substring(pattern, cuts[-length(cuts)] + 1L, cuts[-1L]))
    pool <- if (is.null(u.nchar)) seq_along(u) else which(u.nchar >= n - k)
    x <- u[pool]
    keep <- grepl(pieces[1L], x, fixed = TRUE, useBytes = TRUE)
    for (p in pieces[-1L]) {
      keep <- keep | grepl(
        p,
        x,
        fixed = TRUE,
        useBytes = TRUE
      )
    }
    cand <- pool[keep]
    if (length(cand) == 0) {
      return(integer(0))
    }
  }
  if (is.null(cand)) {
    return(agrep(pattern, u, max.distance = max.distance))
  }
  cand[agrep(pattern, u[cand], max.distance = max.distance)]
}

# ----------------------------------------------------------------------------
# Post-processing shared by WFO.match and WFO.match.fuzzyjoin
# ----------------------------------------------------------------------------

# Backbone rows within `max.dist` string distance of each unique query, as
# fuzzyjoin::stringdist_left_join() would find them (all pairs with distance <=
# max.dist). For edit distances (lv, osa, dl, hamming) a length window is an
# exact prefilter: strings whose lengths differ by more than max.dist cannot be
# within max.dist.
.stringdist.hits <- function(q, index, method, max.dist, len.u) {
  cand <- seq_along(index$u)
  if (method %in% c("lv", "osa", "dl", "hamming")) {
    cand <- which(abs(len.u - nchar(q)) <= max.dist)
  }
  if (length(cand) == 0) {
    return(list(ids = integer(0), dist = numeric(0)))
  }
  d <- stringdist::stringdist(q, index$u[cand], method = method)
  keep <- which(d <= max.dist)
  list(ids = cand[keep], dist = d[keep])
}

# pairwise Levenshtein distance (as utils::adist) for vectors a and b.
# Missing inputs and NA results (e.g. invalid encodings) become `na`
# (Inf for Auth.dist / First.dist, NA for Fuzzy.dist, as in WorldFlora).
.pair.adist <- function(a, b, na = Inf) {
  a <- as.character(a)
  b <- as.character(b)
  out <- rep(na, length(a))
  ok <- !is.na(a) & !is.na(b)
  if (any(ok)) {
    key <- paste(a[ok], b[ok], sep = "\r")
    uk <- !duplicated(key)
    d <- mapply(
      function(x, y) as.numeric(utils::adist(x, y)),
      a[ok][uk],
      b[ok][uk],
      USE.NAMES = FALSE
    )
    d[is.na(d)] <- na
    out[ok] <- d[match(key, key[uk])]
  }
  out
}

# Correctly spelled genus (Fuzzy.keep.genus): when the first word of a name of
# two or more words is a name of the backbone (the genus is spelled correctly),
# fuzzy candidates of that genus are kept and candidates of other genera are
# dropped; without candidates of the genus, none are kept, and the genus-only
# fall-back (Fuzzy.one) gives the genus. "Neea gigante": Leea gigantea
# (Vitaceae) is not kept, and the genus Neea is the result. Returns the
# candidate ids to keep.
.keep.genus <- function(s, ids, index, msg = function(...) NULL) {
  g <- sub(" .*$", "", s)
  if (length(ids) == 0 || g == s || is.na(match(g, index$u))) {
    return(ids)
  }
  cand.genus <- sub(
    " .*$",
    "",
    sub(paste0("^", .HYBRID, " ?"), "", index$u[ids])
  )
  same <- cand.genus == g
  if (all(same)) {
    return(ids)
  }
  msg("Fuzzy matches for ", s, " in other genera than ", g, " were not kept")
  dropped <- index$u[ids[!same]]
  structure(
    ids[same],
    dropped = dropped[order(as.numeric(utils::adist(s, dropped)))]
  )
}
