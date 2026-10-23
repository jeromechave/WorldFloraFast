# ----------------------------------------------------------------------------
# prepare.R: WFO.prepare() and WFO.preprepare(), splitting names and authors
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - Both functions: arguments, steps (protection of authors ending in " f.",
#       squish, sub.pattern, numbers, trinomials, authorship, second brackets,
#       flags), result columns and their types.
#   Changed:
#     - Each distinct name is parsed once by .prepare.one(); messages and
#       warnings once per distinct name.
#     - Empty or missing names no longer cause an error (NEWS 10); spec.full is
#       used throughout and data.tables are accepted (NEWS 11).
#     - WFO.preprepare() no longer fails when a name lacks trinomial.first (NEWS
#       12).
#   New in WorldFloraFast:
#     - Morphospecies codes removed before parsing; argument spec.name.aff.genus
#       (1.0.6).
#     - Argument spec.name.fix.encoding; "sp" without a full stop (1.0.7).
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

#' Split full plant names into name and authorship
#'
#' `WFO.prepare()` splits full botanical names that include naming authorities
#' (for example `"Acacia nilotica subsp. kraussiana (Benth.) Brenan"`) into the
#' plant name and its authorship, ready for [WFO.match()]. It also flags names
#' that probably need checking. `WFO.preprepare()` splits names around a first
#' and a second infraspecific rank, for names that contain two of them.
#'
#' @param spec.data A data.frame with a column of full names, or a character
#'   vector (or factor) of full names.
#' @param spec.full Name of the column with the full names.
#' @param squish If `TRUE`, remove repeated white space, and white space at the
#'   start and end of names ([stringr::str_squish()]).
#' @param spec.name.nonumber If `TRUE`, names that contain numbers are
#'   interpreted as genera (only the first word is kept, without trailing
#'   digits). A morphospecies code at the end of a name (" sp.1",
#'   " sp.1_ECOSUR1", " sp9", " sp. 2") is removed first, so that
#'   "Aegiphila sp.1_ECOSUR1" gives *Aegiphila* (WorldFlora gave
#'   "Aegiphila1_ECOSUR").
#' @param spec.name.sub If `TRUE`, delete sections of names that match
#'   `sub.pattern`, and "sp", "spp" or "indet" without a full stop at the end of
#'   a name ("Albizia sp" gives *Albizia*, not a species whose epithet starts
#'   with "sp").
#' @param sub.pattern Regular expressions of sections to delete, such as `"
#'   sp[.]"` or `" cf[.]"`.
#' @param genus.2.flag Flag names of which the first word has fewer than 3
#'   characters.
#' @param species.2.flag Flag names of which the second word has fewer than 3
#'   characters.
#' @param punctuation.flag Flag names that still contain punctuation marks
#'   (other than those of the infraspecific ranks in `trinomial`).
#' @param pointless.flag Flag names that contain one of the `sub.pattern`
#'   sections written without punctuation (for example `"cf"` instead of
#'   `"cf."`).
#' @param trinomial Infraspecific ranks; the word after the rank is kept as part
#'   of the name.
#' @param authors.ending.f Author abbreviations ending in `" f."` (filius),
#'   which would otherwise be mistaken for the rank `"f."` (forma).
#' @param spec.name.fix.encoding If `TRUE` (default), repair names garbled by
#'   a wrong character encoding (UTF-8 text read as Mac Roman or Windows-1252,
#'   up to four times: "Abies holoph‚Äö√..." gives "Abies
#'   holophylla", "Citrus √ó aurantium" gives "Citrus × aurantium"), and
#'   replace Cyrillic letters that look like Latin ones in names that also
#'   contain Latin letters. Accented text
#'   ("Allemão") is not changed. `FALSE` gives the results of WorldFlora.
#' @param spec.name.aff.genus If `TRUE`, names with "aff." (*affinis*, near
#'   but not this species, as in "Drypetes aff. amazonica") are reduced to the
#'   genus. `FALSE` (default) removes "aff." with `sub.pattern` and matches the
#'   species, as in WorldFlora. Give the same value to [WFO.prepare()] and
#'   [WFO.match()]: this function already removes "aff." from the names it
#'   returns.
#' @param verbose If `TRUE`, report the changes made to names.
#' @param counter Progress is reported every `counter` distinct names.
#' @param trinomial.first,trinomial.second First and second infraspecific rank
#'   used by `WFO.preprepare()` to split names.
#'
#' @details For each distinct full name, `WFO.prepare()` successively squishes
#' white space, removes `sub.pattern` sections, reduces names with numbers to
#' their first word, and then keeps the first two words, plus an infraspecific
#' rank from `trinomial` and the word after it. The remaining words form the
#' authorship. A second set of brackets in the authorship (as in `"(Benth.)
#' Brenan (1950)"`) and everything after it is removed.
#'
#' Flag columns are character columns, as in WorldFlora: `"TRUE"` or `""` for
#' `punctuation` and `pointless`; the number of characters, and the short word
#' itself, for `genus.nchar`, `genus.2`, `species.nchar` and `species.2`.
#'
#' Each distinct name is processed once, so messages and warnings are given once
#' per distinct name.
#'
#' @return `WFO.prepare()`: `spec.data` (a data.frame) with the added columns
#'   `spec.name` and `Authorship` (omitted when no authorship was found) and the
#'   requested flag columns. Existing columns `spec.name` and `Authorship` are
#'   renamed with suffix `.ORIG`.
#'
#'   `WFO.preprepare()`: `spec.data` with logical columns `first` (first rank
#'   found), `only.second` (only the second rank found), `also.second` (second
#'   rank found after the first), and the split sections `split.before`,
#'   `split.after` and, when needed, `second.split.before` and
#'   `second.split.after`.
#'
#' @seealso [WFO.match()], which accepts the prepared names, with `Authorship`
#'   used to calculate `Auth.dist`.
#' @export
#' @examples
#' x <- c(
#'   "Acacia nilotica subsp. kraussiana (Benth.) Brenan",
#'   "Ficus sycomorus L.", "Prunus africana (Hook. f.) Kalkman",
#'   "Coffea sp. 3"
#' )
#' WFO.prepare(x, verbose = FALSE)
#'
#' WFO.preprepare(c(
#'   "Acacia nilotica subsp. kraussiana var. major L.",
#'   "Ficus sycomorus L."
#' ))
WFO.prepare <- function(
  spec.data = NULL, spec.full = "spec.full",
  squish = TRUE, spec.name.nonumber = TRUE,
  spec.name.sub = TRUE,
  sub.pattern = c(
    " sp[.] A", " sp[.] B", " sp[.] C", " sp[.]", " spp[.]", " pl[.]",
    " indet[.]", " ind[.]", " gen[.]", " g[.]", " fam[.]",
    " nov[.]", " prox[.]", " cf[.]", " aff[.]", " s[.]s[.]", " s[.]l[.]",
    " p[.]p[.]", " p[.] p[.]", "[?]", " inc[.]", " stet[.]",
    "Ca[.]", "nom[.] cons[.]", "nom[.] dub[.]", " nom[.] err[.]",
    " nom[.] illeg[.]", " nom[.] inval[.]", " nom[.] nov[.]",
    " nom[.] nud[.]", " nom[.] obl[.]", " nom[.] prot[.]", " nom[.] rej[.]",
    " nom[.] supp[.]", " sensu auct[.]"
  ),
  genus.2.flag = TRUE,
  species.2.flag = TRUE,
  punctuation.flag = TRUE,
  pointless.flag = TRUE,
  trinomial = c(
    "cultivar.", "f.", "sect.", "subf.", "subg.", "subsp.", "subvar.", "var.",
    "CULTIVAR.", "SECT.", "SUBF.", "SUBG.", "SUBSP.", "SUBVAR.", "VAR."
  ),
  authors.ending.f = c(
    "Aiton f.", "Baker f.", "Bak. f.", "Burm. f.",
    "Cheng f.", "Chrtek f.",
    "De Marco f.", "Fang f.", "Ferry f.", "Forsyth f.",
    "Forster f.", "Fraser f.", "G.Don f.", "Haller f.",
    "Hallier f.", "Hook. f.", "Hooker f.", "Hsueh f.",
    "J.Kickx f.", "J. Kickx f.", "Keng f.",
    "Kickx f.", "Klokov f.", "Koster f.",
    "Liou f.", "L. f.", "Ma f.", "Mikan f.",
    "Occhioni f.", "Rchb. f.", "Schultes f.",
    "Schult. f.", "Stapf f."
  ),
  verbose = TRUE, counter = 1000,
  spec.name.aff.genus = FALSE,
  spec.name.fix.encoding = TRUE
) {
  spec.data <- .as.spec.data(spec.data, default.name = spec.full)
  if (!spec.full %in% names(spec.data)) {
    stop(
      "Variable '",
      spec.full,
      "' not found in spec.data"
    )
  }
  for (v in intersect(c("spec.name", "Authorship"), names(spec.data))) {
    message(
      "Original data set variable '",
      v,
      "' replaced by variable '",
      v,
      ".ORIG'"
    )
    names(spec.data)[names(spec.data) == v] <- paste0(v, ".ORIG")
  }

  # Protect author abbreviations ending in " f." from being read as the rank
  # "f." (patterns are regular expressions, as in WorldFlora)
  protected <- gsub(" f.", " f_author", authors.ending.f, fixed = TRUE)
  full <- as.character(spec.data[[spec.full]])
  if (spec.name.fix.encoding) full <- .fix.encoding(full)
  for (i in seq_along(authors.ending.f)) {
    full <- gsub(
      authors.ending.f[i],
      protected[i],
      full
    )
  }

  # parse each distinct name once
  todo <- unique(full)
  parsed <- vapply(seq_along(todo), function(j) {
    if (j %% counter == 0) message("Reached record # ", j)
    .prepare.one(todo[j],
      squish = squish, spec.name.sub = spec.name.sub, sub.pattern = sub.pattern,
      spec.name.nonumber = spec.name.nonumber,
      spec.name.aff.genus = spec.name.aff.genus, genus.2.flag = genus.2.flag,
      species.2.flag = species.2.flag, punctuation.flag = punctuation.flag,
      pointless.flag = pointless.flag, trinomial = trinomial, verbose = verbose
    )
  }, FUN.VALUE = character(8))
  parsed <- parsed[, match(full, todo), drop = FALSE]

  keep <- c(
    "spec.name", "Authorship",
    if (genus.2.flag) c("genus.nchar", "genus.2"),
    if (species.2.flag) c("species.nchar", "species.2"),
    if (punctuation.flag) "punctuation",
    if (pointless.flag) "pointless"
  )
  for (v in keep) spec.data[[v]] <- parsed[v, ]

  # undo the protection of authors ending in " f."
  restore <- function(x) {
    for (i in seq_along(authors.ending.f)) {
      x <- gsub(
        protected[i],
        authors.ending.f[i],
        x
      )
    }
    x
  }
  spec.data[[spec.full]] <- restore(full)
  spec.data$spec.name <- restore(spec.data$spec.name)
  if (spec.name.sub) {
    spec.data$spec.name <- .drop.trailing.placeholder(spec.data$spec.name)
  }
  spec.data$Authorship <- restore(spec.data$Authorship)
  # keep NA (not "NA") for missing full names
  spec.data[[spec.full]][is.na(spec.data[[spec.full]]) & is.na(full)] <- NA

  if (all(spec.data$Authorship == "")) spec.data$Authorship <- NULL
  spec.data
}

# Parse one full name. Returns a named character vector with the name, the
# authorship and the flags. Follows the steps of WorldFlora::WFO.prepare() for a
# single record.
.prepare.one <- function(
  spfull,
  squish,
  spec.name.sub,
  sub.pattern,
  spec.name.nonumber,
  genus.2.flag, species.2.flag, punctuation.flag, pointless.flag,
  trinomial, verbose, spec.name.aff.genus = FALSE
) {
  msg <- function(...) if (verbose) message(...)
  out <- c(
    spec.name = "", Authorship = "", genus.nchar = "", genus.2 = "",
    species.nchar = "", species.2 = "", punctuation = "", pointless = ""
  )
  if (is.na(spfull)) spfull <- "" # WorldFlora stopped with an error

  if (squish) {
    s1 <- stringr::str_squish(spfull)
    if (s1 != spfull) msg(spfull, " was squished")
    spfull <- s1
  }
  if (spec.name.aff.genus && .has.aff(spfull)) {
    msg(spfull, " contains aff.: reduced to the genus")
    spfull <- sub(" .*$", "", spfull)
  }
  if (spec.name.nonumber) {
    s1 <- .drop.morphospecies(spfull)
    if (s1 != spfull) msg("Removed a morphospecies code from ", spfull)
    spfull <- s1
  }
  if (spec.name.sub) {
    s1 <- spfull
    for (p in sub.pattern) s1 <- gsub(pattern = p, replacement = "", x = s1)
    if (s1 != spfull) {
      msg(
        "Removed sub.patterns from ",
        spfull,
        " resulting in: ",
        s1
      )
    }
    spfull <- s1
  }
  if (spec.name.nonumber && grepl("[[:digit:]]", spfull)) {
    s1 <- sub(
      "[[:digit:]]+$",
      "",
      strsplit(spfull, split = " ", fixed = TRUE)[[1]][1]
    )
    if (s1 != spfull) {
      msg(
        "Numbers detected in ",
        spfull,
        " and replaced by: ",
        s1
      )
    }
    spfull <- s1
  }

  # name: first two words, plus a rank from `trinomial` and the word after it
  words <- strsplit(spfull, split = " ", fixed = TRUE)[[1]]
  auth.add <- 3
  if (length(words) < 3) {
    sp.final <- spfull
  } else {
    sp.final <- paste(words[1], words[2])
    rank.at <- which(words %in% trinomial)
    if (length(rank.at) > 1) {
      warning("Two trinomial epithets provided for ", spfull, call. = FALSE)
      auth.add <- max(rank.at) + 2
      sp.final <- paste(sp.final, words[min(rank.at)], words[min(rank.at) + 1])
    } else if (length(rank.at) == 1) {
      auth.add <- rank.at + 2
      if (length(words) < rank.at + 1) {
        warning("No trinomial epithet provided for ", spfull, call. = FALSE)
        auth.add <- rank.at + 1
      } else {
        sp.final <- paste(sp.final, words[rank.at], words[rank.at + 1])
      }
    }
  }

  # authorship: the remaining words
  auth <- if (auth.add <= length(words)) {
    paste0(
      " ",
      words[auth.add:length(words)],
      collapse = ""
    )
  } else {
    ""
  }
  if (nchar(auth) > 1) auth <- substr(auth, 2, nchar(auth))
  # drop a second set of brackets (and what follows)
  if (nchar(auth) > 1) {
    br <- regexpr("(", substr(auth, 2, nchar(auth)), fixed = TRUE)
    if (br > 0) {
      msg("Second bracket detected for ", auth)
      auth <- stringr::str_squish(substr(auth, 1, br))
    }
  }
  out["spec.name"] <- sp.final
  out["Authorship"] <- auth

  w <- strsplit(sp.final, split = " ", fixed = TRUE)[[1]]
  if (genus.2.flag && length(w) > 0) { # empty names were an error in WorldFlora
    out["genus.nchar"] <- nchar(w[1])
    if (nchar(w[1]) < 3) {
      out["genus.2"] <- w[1]
      msg("Short first part of name detected for: ", sp.final)
    }
  }
  if (species.2.flag && length(w) > 1) {
    out["species.nchar"] <- nchar(w[2])
    if (nchar(w[2]) < 3) {
      out["species.2"] <- w[2]
      msg("Short second part of name detected for: ", sp.final)
    }
  }
  if (punctuation.flag) {
    s1 <- tolower(sp.final)
    for (p in trinomial) s1 <- gsub(pattern = p, replacement = "", x = s1)
    if (grepl("[[:punct:]]", s1)) {
      out["punctuation"] <- "TRUE"
      msg("Punctuation mark detected for: ", sp.final)
    }
  }
  if (pointless.flag) {
    s1 <- tolower(sp.final)
    for (p in setdiff(
      trinomial,
      "f."
    )) {
      s1 <- gsub(pattern = p, replacement = "", x = s1)
    }
    for (p in sub.pattern) {
      p1 <- gsub("[[:punct:]]", "", p)
      if (nchar(p1) > 2 && grepl(tolower(p1), s1)) {
        out["pointless"] <- "TRUE"
        msg(
          "Subpattern without punctuation mark ('",
          p1,
          "') detected for: ",
          sp.final
        )
      }
    }
  }
  out
}

#' @rdname WFO.prepare
#' @export
WFO.preprepare <- function(
  spec.data = NULL, spec.full = "spec.full",
  trinomial.first = "subsp.",
  trinomial.second = "var."
) {
  spec.data <- .as.spec.data(spec.data, default.name = spec.full)
  if (!spec.full %in% names(spec.data)) {
    stop(
      "Variable '",
      spec.full,
      "' not found in spec.data"
    )
  }
  for (v in intersect(c("spec.name", "Authorship"), names(spec.data))) {
    message(
      "Original data set variable '",
      v,
      "' replaced by variable '",
      v,
      ".ORIG'"
    )
    names(spec.data)[names(spec.data) == v] <- paste0(v, ".ORIG")
  }
  full <- as.character(spec.data[[spec.full]])
  r1 <- trinomial.first
  r2 <- trinomial.second
  before <- function(x, r) {
    stringr::str_match(x, paste0("(.*)\\s", r, "\\s"))[, 2]
  }
  after <- function(x, r) {
    stringr::str_match(x, paste0("\\s", r, "\\s(.*)"))[, 2]
  }
  # %in% TRUE: names without the rank gave NA and an error in WorldFlora
  has <- function(x, r) stringr::str_detect(x, paste0(" ", r, " ")) %in% TRUE

  # split around the first rank
  first <- has(full, r1)
  split.before <- full
  split.before[first] <- before(full[first], r1)
  split.after <- after(full, r1)
  split.after[first] <- paste0(r1, " ", split.after[first])

  # second rank before the first (or without the first)
  only.second <- has(split.before, r2)
  split.before[only.second] <- before(full[only.second], r2)
  split.after[only.second] <- paste0(r2, " ", after(full[only.second], r2))

  # second rank after the first
  also.second <- has(split.after, r2)

  spec.data$first <- first
  spec.data$split.before <- split.before
  spec.data$split.after <- split.after
  spec.data$only.second <- only.second
  spec.data$also.second <- also.second
  if (any(also.second)) {
    spec.data$second.split.before <- rep("", nrow(spec.data))
    spec.data$second.split.after <- rep("", nrow(spec.data))
    spec.data$second.split.before[also.second] <- before(
      split.after[also.second],
      r2
    )
    spec.data$second.split.after[also.second] <- paste0(
      r2,
      " ",
      after(split.after[also.second], r2)
    )
  }
  spec.data
}
