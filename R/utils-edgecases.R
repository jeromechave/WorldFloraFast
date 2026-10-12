## --------------------------------------------------------------------------------------
## utils-edgecases.R: matching steps for names that exact and agrep() matching do not find
##
## Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
##   Inherited:
##     - none
##   Changed:
##     - The genus-only fall-back of Fuzzy.one (WorldFlora) is restricted by
##       .genus.rows.strict() when Fuzzy.one.strict = TRUE.
##   New in WorldFloraFast:
##     - The whole file: genus then epithet, genus transfer, strict genus fall-back, the
##       epithet check of agrep() candidates (.epithet.check(); it also rejects fuzzy
##       matches in unrelated genera and other families), the family of a genus from its
##       accepted genus record (.genus.families()), and the alternatives listed in
##       Fuzzy.alternatives.
##   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
## --------------------------------------------------------------------------------------

##
## * .genus.epithet(): truncated or misspelled genus with a recognisable epithet
##   ("Reinwardtiod cinerum" -> Reinwardtiodendron cinereum): candidate genera first,
##   then the epithet within these genera.
## * .genus.transfer(): epithet moved to another genus of the same family
##   ("Chrysophyllum madagascariensis" -> Gambeya madagascariensis, a synonym of Gambeya
##   boiviniana, which also has the synonym Chrysophyllum boivinianum).
## * .genus.rows.strict(): genus-only fall-back limited to accepted genus names, so that
##   local names whose first word is an old synonym genus ("Palma colorada", Palma Mill. =
##   Phoenix) are not given a scientific name.

## Epithet in a form that ignores Latin gender endings, genitive -i/-ii and a hybrid sign
## (-us/-a/-um, -is/-e, -ensis/-ense, bancrofti/bancroftii)
.norm.epithet <- function(e) {
  e <- sub(paste0("^", .HYBRID, " ?"), "", tolower(e))
  e <- sub("ii$", "i", e)
  sub("(ensis|ense)$", "ens", sub("(us|um|a|is|e)$", "", e))
}

## Context built once per WFO.match() call: binomial names of the backbone with their
## genus, normalised epithet and family; standard ranks and statuses; synonyms by
## accepted name. Normalisation is done on distinct values only (fast on 1.6M names).
.match.context <- function(WFO.dt) {
  chr <- function(v) { x <- as.character(WFO.dt[[v]]); x[is.na(x)] <- ""; x }
  by.unique <- function(x, f) { u <- unique(x); f(u)[match(x, u)] }
  sci <- chr("scientificName")
  if (all(c("genus", "specificEpithet", "infraspecificEpithet") %in% names(WFO.dt))) {
    ## WFO layout: species-level names from the split columns
    gen <- chr("genus"); ep <- chr("specificEpithet"); infra <- chr("infraspecificEpithet")
    rows <- which(gen != "" & ep != "" & infra == "")
    genus <- gen[rows]; epithet <- ep[rows]
  } else {
    ## other backbones (new.backbone): names of exactly two words
    rows <- which(grepl("^[^ ]+ [^ ]+$", sci, perl = TRUE))
    genus <- sub(" .*$", "", sci[rows]); epithet <- sub("^[^ ]+ ", "", sci[rows])
  }
  family <- if ("family" %in% names(WFO.dt)) chr("family")[rows] else rep("", length(rows))
  rank <- if ("taxonRank" %in% names(WFO.dt)) by.unique(chr("taxonRank"), .rank.std) else rep("", length(sci))
  status <- if ("taxonomicStatus" %in% names(WFO.dt)) by.unique(chr("taxonomicStatus"), tolower) else rep("accepted", length(sci))
  acc <- if ("acceptedNameUsageID" %in% names(WFO.dt)) chr("acceptedNameUsageID") else NULL
  ep.norm <- by.unique(epithet, .norm.epithet)
  ## number of accepted species per (normalised) epithet, in the whole backbone
  ep.freq <- table(ep.norm[status[rows] == "accepted"])
  ## genus records: accepted genus name and its family (homonyms: accepted record first)
  fam.all <- if ("family" %in% names(WFO.dt)) chr("family") else rep("", length(sci))
  g.rows <- which(rank == "genus")
  g.rows <- g.rows[order(status[g.rows] != "accepted")]
  g.rows <- g.rows[!duplicated(sci[g.rows])]
  acc.all <- if (!is.null(acc)) acc else rep("", length(sci))
  g.acc <- ifelse(acc.all[g.rows] == "", NA_integer_, match(acc.all[g.rows], chr("taxonID")))
  genus.info <- data.frame(name = sci[g.rows], status = status[g.rows],
                           accepted = ifelse(is.na(g.acc), sci[g.rows], sci[g.acc]),
                           family = ifelse(is.na(g.acc), fam.all[g.rows], fam.all[g.acc]),
                           stringsAsFactors = FALSE)
  list(binom = list(row = rows, genus = genus, epithet.norm = ep.norm, family = family),
       genus.info = genus.info,
       epithet.freq = ep.freq,
       genera = unique(genus),
       sci = sci, rank = rank, status = status,
       family = if ("family" %in% names(WFO.dt)) chr("family") else rep("", length(sci)),
       taxonID = chr("taxonID"), accepted = acc,
       syn.index = if (!is.null(acc)) .build.index(acc) else NULL)
}

## Rows of an exact genus match that are accepted genus names (not synonyms)
.genus.rows.strict <- function(rows, ctx) {
  rows[ctx$rank[rows] %in% c("genus", "") & !(ctx$status[rows] %in% "synonym")]
}

## Step "genus, then epithet". Returns backbone rows (possibly none).
## Candidate genera: those that start with the submitted genus (at least 4 letters), or that
## are within the agrep() distance of `Fuzzy`. Epithets are compared without gender endings,
## within the same distance (at least 1 edit); the closest epithets are kept.
.genus.epithet <- function(s, ctx, Fuzzy) {
  w <- strsplit(s, " ", fixed = TRUE)[[1]]
  if (length(w) < 2 || nchar(w[1]) < 4 || nchar(w[2]) < 3) return(integer(0))
  g <- w[1]
  kg <- .agrep.k(g, Fuzzy)
  g.direct <- ctx$genera[startsWith(ctx$genera, g) |
                         as.numeric(utils::adist(g, ctx$genera)) <= kg]
  ## close genus names that are synonyms lead to their accepted genus ("Parainarium" ->
  ## Parinarium, a synonym of Parinari); used only when the genera found directly give no
  ## match ("Triquetr californica" is Triquetrella californica, not an Astragalus)
  close.records <- ctx$genus.info$name[startsWith(ctx$genus.info$name, g) |
                                       as.numeric(utils::adist(g, ctx$genus.info$name)) <= kg]
  g.synonym <- setdiff(stats::na.omit(.accepted.genus(close.records, ctx)), g.direct)
  ## an existing genus keeps its family ("Neea gigante" is not Leea gigantea, Vitaceae)
  fam <- if (!is.na(match(g, ctx$genus.info$name))) .genus.families(g, ctx) else character(0)
  same.family <- function(x) if (length(fam) == 0) x else x[vapply(x, function(y) {
    y == g || { f <- .genus.families(y, ctx); length(f) > 0 && f %in% fam } }, logical(1))]
  e <- .norm.epithet(w[2])
  ke <- max(1, .agrep.k(e, Fuzzy))
  for (g.cand in list(same.family(g.direct), same.family(g.synonym))) {
    if (length(g.cand) == 0) next
    sel <- which(ctx$binom$genus %in% g.cand)
    b <- lapply(ctx$binom, `[`, sel)
    d <- as.numeric(utils::adist(e, b$epithet.norm))
    keep <- which(d <= ke)
    if (length(keep) > 0) {
      keep <- keep[d[keep] == min(d[keep])]
      return(sort(b$row[keep]))
    }
  }
  integer(0)
}

## Largest number of accepted species with an epithet for the "unique in the family" rule of
## the genus transfer (99% of epithets of the WFO Plant List 2026-06 are used by fewer)
.transfer.max.epithet <- 50

## At most 5 distinct species (first two words of names), for column Fuzzy.alternatives
.alternatives <- function(x) {
  x <- unique(sub("^([^ ]+ [^ ]+).*$", "\\1", x))
  paste0(paste(utils::head(x, 5), collapse = "; "), if (length(x) > 5) paste0("; ... (", length(x), ")") else "")
}

## Family of the submitted genus: that of its accepted genus record; without a genus record,
## the most frequent family of its accepted species. (Names of a genus can be filed under
## many families in WFO, e.g. Cassine under 7, so "all families of its names" is too wide.)
.genus.families <- function(g, ctx) {
  i <- match(g, ctx$genus.info$name)
  if (!is.na(i) && ctx$genus.info$family[i] != "") return(ctx$genus.info$family[i])
  sel <- ctx$binom$genus == g & ctx$status[ctx$binom$row] == "accepted" & ctx$binom$family != ""
  if (!any(sel)) return(character(0))
  names(which.max(table(ctx$binom$family[sel])))
}

## Accepted genus name of a genus record (itself if accepted, NA if not a genus record)
.accepted.genus <- function(g, ctx) ctx$genus.info$accepted[match(g, ctx$genus.info$name)]

## Step "genus transfer". Same-epithet names (ignoring gender endings) in other genera of the
## family of the submitted genus are accepted:
## 1. if exactly one accepted taxon among them is, or has a synonym, in the submitted genus
##    (evidence that the species moved: Chrysophyllum madagascariensis -> Gambeya);
## 2. otherwise, if they all lead to one accepted taxon and the epithet is distinctive (used by
##    at most .transfer.max.epithet accepted species in the backbone): Lithocarpus acutissima
##    -> Quercus acutissima, Endiandra bancroftii -> Beilschmiedia bancroftii.
## Returns backbone rows, or none when the candidates are ambiguous.
.genus.transfer <- function(s, ctx) {
  if (is.null(ctx$accepted)) return(integer(0))
  w <- strsplit(s, " ", fixed = TRUE)[[1]]
  if (length(w) < 2) return(integer(0))
  g <- w[1]
  fam <- .genus.families(g, ctx)
  if (length(fam) == 0) return(integer(0))
  e <- .norm.epithet(w[2])
  sel <- which(ctx$binom$family %in% fam & ctx$binom$genus != g & ctx$binom$epithet.norm == e)
  if (length(sel) == 0) return(integer(0))
  b <- lapply(ctx$binom, `[`, sel)
  acc.id <- ifelse(ctx$accepted[b$row] == "", ctx$taxonID[b$row], ctx$accepted[b$row])
  ## the accepted taxon must be in the family too (a name filed under Fagaceae can be a
  ## synonym of a species of another family: "Quercus dives" is not Meliosma idiopoda)
  in.fam <- ctx$family[match(acc.id, ctx$taxonID)] %in% fam
  if (!any(in.fam)) return(integer(0))
  b <- lapply(b, `[`, in.fam); acc.id <- acc.id[in.fam]
  ## evidence: the accepted taxon has a synonym whose genus is the submitted genus
  evidence <- vapply(acc.id, function(id) {
    if (sub(" .*$", "", ctx$sci[match(id, ctx$taxonID)]) %in% g) return(TRUE)
    i <- match(id, ctx$syn.index$u)
    !is.na(i) && any(sub(" .*$", "", ctx$sci[.rows.of(ctx$syn.index, i)]) == g)
  }, logical(1))
  if (length(unique(acc.id[evidence])) == 1) return(sort(b$row[evidence]))
  n.ep <- ctx$epithet.freq[e]
  if (length(unique(acc.id)) == 1 && !is.na(n.ep) && n.ep <= .transfer.max.epithet) return(sort(b$row))
  ## ambiguous: no match, but the candidates are reported
  structure(integer(0), alternatives = .alternatives(ctx$sci[b$row]))
}


## Epithet check of agrep() candidates for names of two or more words. agrep() allows a
## distance relative to the whole name, so a long genus "pays" for several edits in a short
## epithet ("Ocotea luis" -> Ocotea lucida). A candidate is kept if its epithet (ignoring
## gender endings and hybrid signs) is within the agrep() distance of the submitted epithet
## (at least 1 edit), or the submitted epithet (4 or more letters) is its beginning
## ("Quercus cornelius" -> Quercus cornelius-mulleri); and, when the submitted genus exists
## in the backbone, if the candidate is in the same genus, or in a genus with a related name
## of the same family ("Neea gigante" is not Leea gigantea, Vitaceae). Returns the indices
## of the candidates to keep.
.epithet.check <- function(s, cand, ctx, Fuzzy) {
  w <- strsplit(s, " ", fixed = TRUE)[[1]]
  ## one- or two-letter second words (a mistyped hybrid sign, "Dryopteris e asturiensis")
  ## are not judged
  if (length(w) < 2 || nchar(w[2]) < 3) return(seq_along(cand))
  e <- .norm.epithet(w[2])
  e.raw <- tolower(w[2])
  ke <- max(1, .agrep.k(e.raw, Fuzzy))
  g <- w[1]
  fam <- if (!is.na(match(g, ctx$genus.info$name))) .genus.families(g, ctx) else character(0)
  keep <- vapply(cand, function(x) {
    cw <- strsplit(sub(paste0("^", .HYBRID, " ?"), "", x), " ", fixed = TRUE)[[1]]
    if (length(cw) < 2) return(TRUE)
    ce.raw <- tolower(sub(paste0("^", .HYBRID), "", cw[2]))
    ce <- .norm.epithet(ce.raw)
    ## raw or normalised spelling: a typo in the ending (obovatxm) prevents normalisation
    ok.ep <- min(as.numeric(utils::adist(e, ce)), as.numeric(utils::adist(e.raw, ce.raw))) <= ke ||
             (nchar(w[2]) >= 4 && startsWith(tolower(sub(paste0("^", .HYBRID), "", cw[2])), tolower(w[2])))
    ## another genus must have a related name (starting with the submitted genus, or within
    ## the agrep() distance) and, for an
    ## existing submitted genus, the same family; otherwise it is a genus transfer, which
    ## has its own rules ("Inga ferrea" is not Coumarouna ferrea, found within the name)
    ok.genus <- cw[1] == g || (
      (startsWith(cw[1], g) || as.numeric(utils::adist(g, cw[1])) <= .agrep.k(g, Fuzzy)) &&
      (length(fam) == 0 || { f <- .genus.families(cw[1], ctx); length(f) > 0 && f %in% fam }))
    ok.ep && ok.genus
  }, logical(1))
  which(keep)
}
