# ----------------------------------------------------------------------------
# utils-clean.R: cleaning of submitted names
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - The cleaning steps, their order, and the columns <spec.name>.ORIG,
#       Squished, Brackets.detected and Number.detected (from WFO.match() and
#       WFO.match.fuzzyjoin(), where they were duplicated).
#   Changed:
#     - Vectorised: all records at once instead of a loop per record.
#     - tolower is applied to the squished name (NEWS 4).
#   New in WorldFloraFast:
#     - .is.placeholder(): names made only of placeholder words (1.0.2).
#     - Morphospecies codes removed before cleaning (.drop.morphospecies());
#       names with aff. reduced to the genus on request (.has.aff()) (1.0.6).
#     - Repair of garbled text and look-alike letters (.fix.encoding());
#       "sp", "spp", "indet" without a full stop at the end (1.0.7).
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

# Clean submitted names before matching (squish, tolower, sub.pattern, brackets,
# numbers, hybrid notation), in the order of WorldFlora, for all records at
# once. Adds the columns <spec.name>.ORIG, Squished, Brackets.detected and
# Number.detected.
.clean.spec.names <- function(spec.data, spec.name,
                              squish = TRUE,
                              spec.name.tolower = FALSE,
                              spec.name.sub = TRUE,
                              sub.pattern,
                              spec.name.nobrackets = TRUE,
                              spec.name.nonumber = TRUE,
                              spec.name.aff.genus = FALSE,
                              spec.name.fix.encoding = TRUE) {
  x <- as.character(spec.data[[spec.name]])
  x[is.na(x)] <- ""
  orig.name <- paste0(spec.name, ".ORIG")
  any.step <- squish || spec.name.tolower || spec.name.sub ||
    spec.name.nobrackets || spec.name.nonumber
  if (any.step) spec.data[[orig.name]] <- x
  orig <- x

  if (spec.name.fix.encoding) x <- .fix.encoding(x)
  if (squish) {
    x <- .squish(x)
    spec.data$Squished <- nchar(orig) > 0 & orig != x
  }
  if (spec.name.tolower) {
    # NOTE: previous versions lower-cased the ORIGINAL name, silently undoing
    # squish
    x <- tolower(x)
    substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  }
  if (spec.name.aff.genus) {
    af <- .has.aff(x)
    if (any(af)) x[af] <- sub(" .*$", "", x[af])
  }
  if (spec.name.nonumber) {
    # names with a morphospecies code still count as containing a number
    morpho <- grepl(.MORPHOSPECIES, x, perl = TRUE)
    x <- .drop.morphospecies(x)
  }
  if (spec.name.sub) {
    for (p in sub.pattern) x <- gsub(pattern = p, replacement = "", x = x)
    x <- .drop.trailing.placeholder(x)
  }
  if (spec.name.nobrackets) {
    br <- grepl("(", x, fixed = TRUE)
    spec.data$Brackets.detected <- br
    if (any(br)) x[br] <- .squish(sub("[(].*$", "", x[br]))
  }
  if (spec.name.nonumber) {
    nb <- grepl("[[:digit:]]", x)
    spec.data$Number.detected <- nb | morpho
    if (any(nb)) x[nb] <- sub("[[:digit:]]+$", "", sub(" .*$", "", x[nb]))
  }
  hy <- grepl(" x ", x, fixed = TRUE)
  if (any(hy)) {
    message(
      "pattern ' x ' was interpreted as hybrid notation and replaced by ' ",
      .HYBRID,
      "'"
    )
    if (!any.step) spec.data[[orig.name]] <- x
    x[hy] <- gsub(" x ", paste0(" ", .HYBRID), x[hy], fixed = TRUE)
  }
  spec.data[[spec.name]] <- x
  spec.data
}

# TRUE for names made only of placeholder words ("indet.", "sp.", "cf.", "spp.",
# "indet", "unknown"): the words of sub.pattern without punctuation, and a few
# others. Such names are not fuzzy-matched (Fuzzy.skip.placeholder), because
# they are not plant names: WorldFlora matched "indet." with "Opuntia
# coindetti", found within that name.
.is.placeholder <- function(x, sub.pattern) {
  words <- unlist(strsplit(sub.pattern, " ", fixed = TRUE))
  ph <- unique(c(
    tolower(gsub("[^[:alpha:]]", "", words)),
    "indet", "indeterminate", "indetermined", "unknown", "sp", "spp", "cf",
    "aff", "nd"
  ))
  ph <- ph[nchar(ph) > 0]
  vapply(strsplit(tolower(x), " ", fixed = TRUE), function(w) {
    w <- gsub("[^[:alpha:]]", "", w)
    w <- w[nchar(w) > 0]
    length(w) > 0 && all(w %in% ph)
  }, logical(1))
}

# Morphospecies codes at the end of a name: " sp.1", " sp.1_ECOSUR1", " sp9",
# " sp. 2", " spp.3". They are removed before the other cleaning steps, so that
# the genus remains ("Aegiphila sp.1_ECOSUR1" -> "Aegiphila"); WorldFlora
# removed " sp." and kept the rest glued to the genus ("Aegiphila1_ECOSUR").
# A code followed by other words ("Palma sp1 colorada") is left to the number
# rule (spec.name.nonumber), which keeps the first word.
.MORPHOSPECIES <- "\\s+spp?[.]?\\s*[0-9][^ ]*$"
.drop.morphospecies <- function(x) gsub(.MORPHOSPECIES, "", x, perl = TRUE)

# Names with "aff." (affinis: near, but not, this species)
.has.aff <- function(x) grepl("(^|\\s)aff[.]?(\\s|$)", x, ignore.case = TRUE)

# Placeholder words at the end of a name without a full stop (" sp", " spp",
# " indet"): removed like " sp." and " spp." (sub.pattern), so that
# "Albizia sp" gives Albizia, not a species whose epithet starts with "sp".
.TRAILING.PLACEHOLDER <- "\\s+(spp?|indet)$"
.drop.trailing.placeholder <- function(x) {
  sub(.TRAILING.PLACEHOLDER, "", x, ignore.case = TRUE, perl = TRUE)
}

# Garbled text: UTF-8 read as Mac Roman or Windows-1252, possibly several
# times. "Abies holoph\u201a\u00c4\u00f6\u221a\u00c4\u00f4lla" is "Abies
# holophylla" garbled three times. Characters typical of such text: sqrt sign,
# low quotation mark, A tilde, A circumflex, a circumflex, f with hook.
.MOJIBAKE <- "[\u221a\u201a\u00c3\u00c2\u00e2\u0192]"

# Undo up to `rounds` rounds of garbling. A round is kept only if the result
# is valid UTF-8 and shorter, which never happens for ordinary accented text
# ("Allem\u00e3o"), so such text is left unchanged.
.fix.mojibake <- function(x, rounds = 4) {
  todo <- which(!is.na(x) & grepl(.MOJIBAKE, x, perl = TRUE))
  for (i in todo) {
    s <- x[i]
    for (r in seq_len(rounds)) {
      fixed <- NULL
      for (enc in c("macintosh", "CP1252")) {
        raw <- tryCatch(iconv(s, "UTF-8", enc, toRaw = TRUE)[[1]],
          error = function(e) NULL
        )
        if (is.null(raw)) next
        y <- rawToChar(raw)
        Encoding(y) <- "UTF-8"
        if (validUTF8(y) && nchar(y) < nchar(s)) {
          fixed <- y
          break
        }
      }
      if (is.null(fixed)) break
      s <- fixed
    }
    x[i] <- s
  }
  x
}

# Cyrillic letters that look like Latin letters, replaced by these in names
# that also contain Latin letters ("Abies holoph\u0443lla" with a Cyrillic u)
.HOMOGLYPH.CYRILLIC <- paste0(
  "\u0430\u0435\u043e\u0440\u0441\u0443\u0445\u0456\u0458\u0455\u04bb\u0501",
  "\u0410\u0412\u0415\u041a\u041c\u041d\u041e\u0420\u0421\u0422\u0425",
  "\u0406\u0408\u0405"
)
.HOMOGLYPH.LATIN <- "aeopcyxijshdABEKMHOPCTXIJS"
.fix.homoglyphs <- function(x) {
  mixed <- !is.na(x) & grepl("[A-Za-z]", x) & grepl("[\u0400-\u052f]", x)
  if (any(mixed)) {
    x[mixed] <- chartr(.HOMOGLYPH.CYRILLIC, .HOMOGLYPH.LATIN, x[mixed])
  }
  x
}

# Repair of garbled text and look-alike letters (spec.name.fix.encoding)
.fix.encoding <- function(x) .fix.homoglyphs(.fix.mojibake(x))
