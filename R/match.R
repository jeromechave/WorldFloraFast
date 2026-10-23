# ----------------------------------------------------------------------------
# match.R: WFO.match() and the fuzzy matching of one name
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - WFO.match(): arguments, cleaning steps, exact matching, conserved family
#       names, and the decision sequence of fuzzy matching (agrep(), Fuzzy.two,
#       Fuzzy.one, Fuzzy.max, Fuzzy.within, Fuzzy.min, Fuzzy.shortest); result
#       columns and their order; matching via Genus/Species/Infraspecific
#       columns.
#   Changed:
#     - Reimplemented: backbone index built once (utils-index.R), fuzzy matching
#       once per distinct name (.fuzzy.one.name(), a pure function), agrep()
#       preceded by an exact prefilter (utils-distance.R), vectorised assembly
#       of results instead of rbind() in loops.
#     - Corrections NEWS 1-8: Fuzzy.force, stale matches from earlier records,
#       missing Infraspecific, tolower undoing squish, Unique for exact
#       homonyms, replacement by column name, Fuzzy.within returning the whole
#       backbone, dropped conserved family names.
#     - Ranks and hybrid notation of WFO 2026-06 (utils-rank.R).
#     - The argument no.dates is deprecated (it had no effect).
#   New in WorldFloraFast:
#     - Arguments spec.name.aff.genus (1.0.6), spec.name.fix.encoding (1.0.7).
#     - Arguments Fuzzy.keep.genus (1.0.1), Fuzzy.skip.placeholder and default
#       TRUE of Fuzzy.epithet.check (1.0.2): corrections, on by default; failed
#       parallel processes are recomputed (.parallel.lapply(), 1.0.2).
#     - Arguments cores and (optional, FALSE by default) Fuzzy.genus,
#       Fuzzy.transfer, Fuzzy.one.strict; columns Fuzzy.genus, Fuzzy.transfer,
#       Fuzzy.alternatives (steps in utils-edgecases.R); index and matching
#       context cached between calls (utils-index.R).
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

#' Match plant names against the World Flora Online taxonomic backbone
#'
#' Matches plant names, exactly or with fuzzy matching, against a static copy of
#' the World Flora Online (WFO) taxonomic backbone, and replaces synonyms by
#' their accepted names. Names are given either as full names (column
#' `spec.name`) or as separate genus, species and infraspecific columns.
#'
#' @param spec.data A data.frame with the names to match, or a character vector
#'   (or factor) of names, which becomes column `spec.name`.
#' @param WFO.file Path to the backbone file (`classification.csv`), read with
#'   [WFO.read()]. Ignored if `WFO.data` is given. If both are `NULL`, the
#'   backbone at the location remembered by [WFO.remember()] or [WFO.download()]
#'   is read.
#' @param WFO.data The backbone as a data.frame or data.table (from
#'   [WFO.read()], [WFO.remember()] or [WFO.backbone()]).
#' @param no.dates Deprecated and ignored (columns `created` and `modified` of
#'   the backbone are always left out of the results); giving it produces a
#'   warning.
#' @param spec.name Name of the column with full plant names (without authors).
#'   If this column is absent, names are matched via `Genus`, `Species`,
#'   `Infraspecific.rank` and `Infraspecific`.
#' @param Genus,Species,Infraspecific.rank,Infraspecific Names of the columns
#'   with the genus, the specific epithet, the infraspecific rank (such as
#'   `"subsp."` or `"var."`, as in column `verbatimTaxonRank` of the backbone)
#'   and the infraspecific epithet. Only used without `spec.name`; only exact
#'   matches are possible.
#' @param Authorship Name of the column with the naming authors. If present,
#'   column `Auth.dist` gives the Levenshtein distance between the submitted and
#'   matched authors. As in WorldFlora, an empty author ("") gives the number of
#'   characters of the matched authors; use `NA` for unknown authors (distance
#'   `Inf`).
#' @param First.dist If `TRUE`, column `First.dist` gives the Levenshtein
#'   distance between the first words (usually the genera) of submitted and
#'   fuzzy-matched names.
#' @param acceptedNameUsageID.match If `TRUE`, replace matched synonyms by their
#'   accepted names (via `acceptedNameUsageID`), keeping the synonym in columns
#'   `Old.*`.
#' @param Fuzzy Maximum distance for fuzzy matching, as argument `max.distance`
#'   of [agrep()]: a fraction of the length of the name (default 0.1), or a
#'   number of edits (1 or more). With 0, only exact matching is done.
#' @param Fuzzy.force If `TRUE`, use fuzzy matching also for names that have
#'   exact matches.
#' @param Fuzzy.max Maximum number of fuzzy matches; names with more are left
#'   unmatched, with their number in column `Fuzzy.toomany`.
#' @param Fuzzy.min If `TRUE`, keep only the fuzzy matches with the smallest
#'   Levenshtein distance ([utils::adist()]) to the submitted name.
#' @param Fuzzy.shortest If `TRUE` (and `Fuzzy.min = FALSE`), keep only the
#'   fuzzy matches with the most similar number of characters; this tends to
#'   remove infraspecific matches.
#' @param Fuzzy.within If `TRUE`, keep only fuzzy matches that contain the
#'   submitted name (useful for names given as their first characters only);
#'   disables `Fuzzy.min` and `Fuzzy.shortest`.
#' @param Fuzzy.two If `TRUE` and there were no fuzzy matches, try the first two
#'   words (genus and species) only.
#' @param Fuzzy.one If `TRUE` and there were still no matches, fall back to the
#'   first word (genus) only. A genus found this way is reported as a fuzzy
#'   match. See `Fuzzy.one.strict`.
#' @param squish If `TRUE`, remove repeated white space and white space at the
#'   start and end of names (as [stringr::str_squish()]).
#' @param spec.name.tolower If `TRUE`, convert names to lower case, with a
#'   capital first letter.
#' @param spec.name.nonumber If `TRUE`, names that contain numbers are
#'   interpreted as genera (only the first word is kept, without trailing
#'   digits). A morphospecies code at the end of a name (" sp.1",
#'   " sp.1_ECOSUR1", " sp9", " sp. 2") is removed first, so that
#'   "Aegiphila sp.1_ECOSUR1" gives *Aegiphila* (WorldFlora gave
#'   "Aegiphila1_ECOSUR").
#' @param spec.name.nobrackets If `TRUE`, remove the part of names from the
#'   first `"("` onwards (such as authors in brackets).
#' @param exclude.infraspecific If `TRUE`, remove matches with an infraspecific
#'   rank listed in `infraspecific.excluded` (after replacement by accepted
#'   names).
#' @param infraspecific.excluded Infraspecific ranks (column
#'   `verbatimTaxonRank`) removed by `exclude.infraspecific`.
#' @param spec.name.sub If `TRUE`, delete sections of names that match
#'   `sub.pattern`, and "sp", "spp" or "indet" without a full stop at the end of
#'   a name ("Albizia sp" gives *Albizia*, not a species whose epithet starts
#'   with "sp").
#' @param sub.pattern Regular expressions of sections to delete, such as `"
#'   sp[.]"`, `" cf[.]"` or `" nom[.] illeg[.]"`.
#' @param verbose If `TRUE`, report details of fuzzy matching.
#' @param counter Progress is reported every `counter` distinct names checked
#'   for fuzzy matches.
#' @param cores Number of cores for fuzzy matching ([parallel::mclapply()]; not
#'   on Windows).
#' @param Fuzzy.keep.genus If `TRUE` (default), a correctly spelled genus is
#'   kept: when the first word of a name of two or more words is a genus with
#'   species names in the backbone, fuzzy matches in other genera are not
#'   accepted. (A genus name without species, such as "Hyeronima", a variant
#'   of *Hieronyma*, does not keep its genus.) Matches in that
#'   genus are kept; if there are none, the genus-only fall-back (`Fuzzy.one`)
#'   gives the genus. "Ulmus parviflora" is matched with the genus *Ulmus*, not
#'   with *Tamus parviflora* (Dioscoreaceae); "Neea gigante" with the genus
#'   *Neea*, not with *Leea gigantea* (Vitaceae). This corrects matches of
#'   WorldFlora that replaced a correct genus by an unrelated one; `FALSE` gives
#'   the results of WorldFlora. The names that were not kept are listed in
#'   `Fuzzy.alternatives` when one of the optional steps below is used.
#' @param Fuzzy.epithet.check If `TRUE` (default), fuzzy matches found by
#'   [agrep()] for names of two or more words are kept only if (1) the epithet
#'   is within the `Fuzzy` distance of the submitted epithet, computed on the
#'   epithet alone (at least 1 edit, and 2 for epithets of 8 or more letters; a
#'   swap of two adjacent letters counts as one edit; gender endings ignored),
#'   or the submitted
#'   epithet is the beginning of it ("Quercus cornelius" -> *Quercus
#'   cornelius-mulleri*); and (2) its genus is the submitted genus, or a genus
#'   with a similar name in the same family. [agrep()] allows a distance
#'   relative to the whole name, so that without this check a short epithet can
#'   be replaced ("Ocotea luis" -> *Ocotea lucida*), and a name can be found
#'   within an unrelated longer name ("Inga ferrea" within "Coumarouna ferrea").
#'   Rejected names are listed in `Fuzzy.alternatives`. This corrects matches of
#'   WorldFlora such as "Endlicheria dori" -> *Endlicheria coriacea* (now the
#'   genus *Endlicheria*); `FALSE` gives the results of WorldFlora. Names whose
#'   second word is a rank (genus and epithet written together,
#'   "Dichondramrepens var. sericea") are not checked, and an epithet written
#'   together with the next word ("australissubsp.") is accepted.
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
#'   [WFO.match()]: [WFO.prepare()] already removes "aff." from the names it
#'   returns.
#' @param Fuzzy.skip.placeholder If `TRUE` (default), names made only of
#'   placeholder words ("indet.", "sp.", "spp.", "cf.", "aff.", "unknown", and
#'   the words of `sub.pattern`) are not fuzzy-matched and remain unmatched.
#'   WorldFlora matched "indet." with *Opuntia coindetti*, in which "indet"
#'   occurs; `FALSE` gives the results of WorldFlora. With `WFO.one(...,
#'   spec.name = "spec.name")`, such names keep the submitted text.
#' @param Fuzzy.genus,Fuzzy.transfer,Fuzzy.one.strict Optional matching steps of
#'   WorldFloraFast for difficult names, described below. All are `FALSE` by
#'   default, which keeps the matching steps and the result columns of
#'   WorldFlora; they can be used together or separately. When one of them is
#'   used, the result has the columns `Fuzzy.genus`, `Fuzzy.transfer` and
#'   `Fuzzy.alternatives`.
#'
#'   `Fuzzy.genus`: if `TRUE` and the name was not found, match the genus first
#'   (genera that start with the submitted genus, or within the `Fuzzy`
#'   distance), then the epithet within these genera, ignoring Latin gender
#'   endings. Finds names with truncated or misspelled genera, such as
#'   "Reinwardtiod cinerum" (*Reinwardtiodendron cinereum*). Genera with similar
#'   names that are synonyms lead to their accepted genus, if the other genera
#'   give no match ("Parainarium excelsa" -> *Parinari excelsa*, via the synonym
#'   *Parinarium*). For a submitted genus that exists in the backbone, only
#'   genera of its family are considered. Also used, and preferred, when
#'   [agrep()] found the name only within names of unrelated genera (none
#'   starting with, or close to, the submitted genus): "Scab paphlagonica" is
#'   matched with *Scabiosa paphlagonica* rather than *Festuca paphlagonica*.
#'   Flagged in column `Fuzzy.genus`.
#'
#'   `Fuzzy.transfer`: if `TRUE` and the name was still not found, look for the
#'   same epithet (ignoring gender endings and -i/-ii) in other genera of the
#'   family of the submitted genus (the family of its accepted genus record).
#'   Candidates whose accepted taxon is in another family are ignored. A
#'   candidate is accepted (1) if exactly one accepted taxon among the
#'   candidates is, or has a synonym, in the submitted genus: the backbone shows
#'   that the species moved ("Chrysophyllum madagascariensis" is matched with
#'   *Gambeya madagascariensis*, a synonym of *Gambeya boiviniana*, which also
#'   has the synonym *Chrysophyllum boivinianum*); or (2) if all candidates lead
#'   to one accepted taxon and the epithet is distinctive, used by at most 50
#'   accepted species in the backbone ("Lithocarpus acutissima" -> *Quercus
#'   acutissima*; "Endiandra bancroftii" -> *Beilschmiedia bancroftii*).
#'   Otherwise the candidates are listed in `Fuzzy.alternatives`. Flagged in
#'   column `Fuzzy.transfer`; please check such matches.
#'
#'   `Fuzzy.one.strict`: if `TRUE`, the genus-only fall-back of `Fuzzy.one`
#'   requires the first word to be, exactly, an accepted (not synonym) genus
#'   name. This prevents local names from being given a scientific genus, such
#'   as "Palma colorada" (*Palma* Mill. is a synonym of *Phoenix*) or "Cedro
#'   rosado" (fuzzy match with *Cedrus*). With `FALSE`, the fall-back of
#'   WorldFlora is used (any exact or fuzzy match of the first word). When the
#'   first word is a synonym genus and nothing is matched, its accepted genus is
#'   listed in `Fuzzy.alternatives` ("Altingia fargesii": *Liquidambar*).
#' @details \strong{Preparation of names.} When `spec.name` is used, names are
#' first cleaned in this order: `squish`, `spec.name.tolower`, `spec.name.sub`,
#' `spec.name.nobrackets`, `spec.name.nonumber`; finally `" x "` is read as
#' hybrid notation and replaced by `" ×"`. The submitted names are kept
#' in column `spec.name.ORIG`, and columns `Squished`, `Brackets.detected` and
#' `Number.detected` show what was changed.
#'
#' \strong{Matching.} Names are matched in this order, each step only for names
#' that the previous steps did not match:
#' \enumerate{
#'   \item exact matches (hybrid notation does not matter: "Mentha x piperita",
#'     "Mentha ×piperita" and "Mentha × piperita" are the same
#'     name);
#'   \item conserved alternative family names (Compositae, Leguminosae,
#'     Umbelliferae, Palmae, Cruciferae, Guttiferae, Labiatae, Gramineae) not in
#'     the backbone, matched with their standard names (Asteraceae, Fabaceae,
#'     ...);
#'   \item fuzzy matches of the full name with [agrep()], then of its first two
#'     words (`Fuzzy.two`), restricted to a correctly spelled genus
#'     (`Fuzzy.keep.genus`) and checked by `Fuzzy.epithet.check`; names that are
#'     only placeholders are skipped (`Fuzzy.skip.placeholder`);
#'   \item genus then epithet (`Fuzzy.genus`, optional), also when the fuzzy
#'     matches of the previous step all belong to unrelated genera; if the
#'     submitted genus exists in the backbone and these matches are all in other
#'     families, they are not accepted ("Schizolobium robustum" is not matched
#'     with *Schizoglossum robustum*, Apocynaceae) but listed in
#'     `Fuzzy.alternatives`;
#'   \item same epithet in another genus of the family (`Fuzzy.transfer`,
#'   optional);
#'   \item the genus only (`Fuzzy.one`; restricted by the optional
#'   `Fuzzy.one.strict`).
#' } Fuzzy candidates are reduced by `Fuzzy.within`, `Fuzzy.min` or
#' `Fuzzy.shortest`. Submitted names with several matches get several rows,
#' numbered by `Subseq`; [WFO.one()] then keeps one row per submitted name.
#'
#' \strong{What fuzzy matching cannot do.} [agrep()] finds the submitted name
#' \emph{within} longer names, which is how incomplete names such as "Pygeum
#' afric" are found, but it can also produce matches for local names ("Palo
#' blanco" is within two edits of part of "Tribulago blancoi"); such matches
#' have a large `Fuzzy.dist` compared with the length of the name. Local names
#' that are themselves names in the backbone (such as the genus *Guayaba*) are
#' matched like any other name. Review fuzzy matches, and remove local names
#' before matching where possible.
#'
#' \strong{WFO releases.} Both the conventions of WFO releases up to 2025 (ranks
#' "SPECIES" and "var.", hybrids written "Mentha ×piperita") and those of
#' the WFO Plant List 2026-06 onwards (ranks "species" and "variety", hybrids
#' written "Mentha × piperita") are understood, for example in
#' `exclude.infraspecific` and when matching by
#' `Genus`/`Species`/`Infraspecific.rank` columns.
#'
#' \strong{Speed.} The backbone is indexed once per call, and fuzzy matching is
#' done once per distinct name. Before each [agrep()] search, an exact prefilter
#' removes names that cannot match: with at most \emph{k} edits, at least one of
#' \emph{k} + 1 pieces of the submitted name occurs unchanged in every match
#' (pigeonhole principle), so a fast fixed-string search for the pieces leaves
#' few candidates. Results are identical to searching the whole backbone.
#'
#' \strong{Differences with WorldFlora 1.14-5} are listed in the NEWS file:
#' notably, `Unique` is `FALSE` for names with several exact matches, and
#' conserved family names and unmatched names are no longer replaced by other
#' records, and a correctly spelled genus is not replaced by another genus
#' (`Fuzzy.keep.genus`), short epithets are not replaced (`Fuzzy.epithet.check`)
#' and placeholders are not matched (`Fuzzy.skip.placeholder`); each of these
#' corrections can be switched off. Results are unchanged otherwise: by default
#' the result columns and their formats are those of WorldFlora, and the
#' optional steps `Fuzzy.genus`, `Fuzzy.transfer` and `Fuzzy.one.strict` are
#' switched off.
#'
#' @return A data.frame with the columns of `spec.data`, followed by:
#' \describe{
#'   \item{spec.name.ORIG, Squished, Brackets.detected,
#'     Number.detected}{Original names and the cleaning steps applied (with
#'     `spec.name` only).}
#'   \item{Unique}{`TRUE` if there was one match (or none).}
#'   \item{Matched}{`TRUE` if a match was found.}
#'   \item{Fuzzy}{`TRUE` if the match was found by fuzzy matching.}
#'   \item{Fuzzy.toomany}{Number of fuzzy matches if more than `Fuzzy.max` (else
#'   `FALSE`).}
#'   \item{Fuzzy.two, Fuzzy.one}{`TRUE` if matching was tried with the first two
#'     words or the first word.}
#'   \item{Fuzzy.genus, Fuzzy.transfer}{`TRUE` if the match was found by the
#'     genus-then-epithet step or the genus-transfer step. Only when one of the
#'     optional steps is used.}
#'   \item{Fuzzy.alternatives}{Names that were not accepted but may have been
#'     meant (at most five species, with the total in brackets): fuzzy matches
#'     in another family than the submitted genus, and the candidates of an
#'     ambiguous genus transfer. Empty otherwise. Only when one of the optional
#'     steps is used.}
#'   \item{Fuzzy.dist}{Levenshtein distance between the submitted name and the
#'     name that was matched (for replaced synonyms, `Old.name`).}
#'   \item{Auth.dist}{Levenshtein distance between submitted and matched authors
#'     (with `Authorship`; `Inf` when it cannot be calculated).}
#'   \item{First.dist}{Distance between the first words (with `First.dist =
#'   TRUE`).}
#'   \item{OriSeq}{Row number of the submitted name in `spec.data`.}
#'   \item{Subseq}{Number of the candidate for the submitted name.}
#'   \item{taxonID ... }{The columns of the backbone for the match (empty or
#'     `NA` when unmatched).}
#'   \item{Hybrid}{`"×"` if the matched name is a hybrid.}
#'   \item{New.accepted}{`TRUE` if the match was a synonym that was replaced by
#'     its accepted name.}
#'   \item{Old.status, Old.ID, Old.name, Old.author}{Status, ID, name and
#'     authors of the replaced synonym.}
#'   \item{Old.author.dist}{Distance between submitted authors and those of the
#'     synonym, as text ("" where no synonym was replaced), as in WorldFlora.}
#' } Existing columns of `spec.data` with these names are renamed with suffix
#' `.ORIG`.
#'
#' @references Kindt, R. (2020). WorldFlora: An R package for exact and fuzzy
#'   matching of plant names against the World Flora Online taxonomic backbone
#'   data. Applications in Plant Sciences 8(9): e11388. \doi{10.1002/aps3.11388}
#' @seealso [WFO.one()] to keep one match per name, [WFO.prepare()] to separate
#'   names and authors, [WFO.spelling.check()] to check fuzzy matches.
#' @export
#' @examples
#' ## ---- default settings (those of WorldFlora) ----
#' # WFO.example2026 is a small extract of the WFO Plant List 2026-06
#' data(WFO.example2026)
#' m <- WFO.match(c(
#'   "Faidherbia albida", "Acacia albida", "Pygeum afric", "Mentha x piperita",
#'   "Prunus sp."
#' ), WFO.data = WFO.example2026)
#' m[, c(
#'   "spec.name", "Subseq", "Fuzzy", "Fuzzy.dist", "scientificName",
#'   "scientificNameAuthorship", "Old.name"
#' )]
#' # one match per name, with the default criteria of WFO.one()
#' WFO.one(m)[, c(
#'   "spec.name", "scientificName", "scientificNameAuthorship",
#'   "One.Reason"
#' )]
#'
#' # names in separate columns
#' WFO.match(data.frame(
#'   Genus = "Gambeya", Species = "boiviniana", Infraspecific.rank = "",
#'   Infraspecific = ""
#' ), WFO.data = WFO.example2026)$scientificName
#'
#' ## ---- non-default settings, marked "non-default" ----
#' # homonyms of "Acacia albida": the authors decide which one was meant
#' aa <- data.frame(
#'   spec.name = "Acacia albida",
#'   Authorship = c("Delile", "Lindl.", "")
#' )
#' m <- WFO.match(aa,
#'   WFO.data = WFO.example2026,
#'   verbose = FALSE
#' ) # non-default: no messages
#' WFO.one(m,
#'   Auth.dist = "Auth.dist", Old.author.dist = "Old.author.dist", # non-default
#'   verbose = FALSE
#' )[, c("Authorship", "scientificName", "Old.name", "One.Reason")]
#'
#' # matching steps of WorldFloraFast for difficult names
#' x <- c(
#'   "Reinwardtiod cinerum", # truncated genus
#'   "Chrysophyllum madagascariensis", # species transferred to another genus
#'   "Palma colorada"
#' ) # local name
#' m <- WFO.match(x,
#'   WFO.data = WFO.example2026, verbose = FALSE,
#'   Fuzzy.genus = TRUE, Fuzzy.transfer = TRUE, # non-default
#'   Fuzzy.one.strict = TRUE
#' ) # non-default
#' m[, c(
#'   "spec.name", "Matched", "Fuzzy.genus", "Fuzzy.transfer",
#'   "scientificName", "Old.name"
#' )]
#' # with the default settings, these names are matched with genera only
#' m0 <- WFO.match(x, WFO.data = WFO.example2026, verbose = FALSE)
#' WFO.one(m0)$scientificName
#'
#' # all fuzzy candidates, then one match per name
#' e1 <- WFO.match("Omalanthus populneus",
#'   WFO.data = WFO.example2026,
#'   Fuzzy.min = FALSE, verbose = FALSE
#' ) # non-default
#' e1[, c(
#'   "Subseq", "Fuzzy.dist", "scientificName", "taxonomicStatus",
#'   "Old.name"
#' )]
#' o1 <- WFO.one(e1, verbose = FALSE)
#' o1[, c("spec.name", "scientificName", "One.Reason")]
#'
#' # names in capitals
#' WFO.match("FAIDHERBIA ALBIDA",
#'   WFO.data = WFO.example2026,
#'   spec.name.tolower = TRUE, verbose = FALSE
#' )$scientificName # non-default
#'
#' # exclusion of infraspecific matches: 0 rows, the variety is excluded
#' nrow(WFO.match("Gambeya boiviniana var. lavanchiana",
#'   WFO.data = WFO.example2026,
#'   acceptedNameUsageID.match = FALSE, # non-default
#'   exclude.infraspecific = TRUE, # non-default
#'   verbose = FALSE
#' ))
#' \dontrun{
#' WFO.download() # complete backbone, available as WFO.data
#' WFO.match(c("Acacia nilotica", "Coffea arabika"),
#'   WFO.data = WFO.data,
#'   cores = 4
#' ) # non-default
#' }
WFO.match <- function(
  spec.data = NULL, WFO.file = NULL, WFO.data = NULL,
  no.dates = TRUE,
  spec.name = "spec.name", Genus = "Genus", Species = "Species",
  Infraspecific.rank = "Infraspecific.rank", Infraspecific = "Infraspecific",
  Authorship = "Authorship", First.dist = FALSE,
  acceptedNameUsageID.match = TRUE,
  Fuzzy = 0.1,
  Fuzzy.force = FALSE,
  Fuzzy.max = 250,
  Fuzzy.min = TRUE,
  Fuzzy.shortest = FALSE,
  Fuzzy.within = FALSE,
  Fuzzy.two = TRUE, Fuzzy.one = TRUE,
  squish = TRUE,
  spec.name.tolower = FALSE,
  spec.name.nonumber = TRUE,
  spec.name.nobrackets = TRUE,
  exclude.infraspecific = FALSE,
  infraspecific.excluded = c(
    "cultivar.", "f.", "sect.", "subf.", "subg.", "subsp.", "subvar.", "var",
    "var.",
    "[infraspec.]", "fo.", "forma", "nothosubsp.", "nothovar.", "sect."
  ),
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
  verbose = TRUE, counter = 1000,
  cores = 1,
  Fuzzy.genus = FALSE, Fuzzy.transfer = FALSE, Fuzzy.one.strict = FALSE,
  Fuzzy.epithet.check = TRUE,
  Fuzzy.keep.genus = TRUE,
  Fuzzy.skip.placeholder = TRUE,
  spec.name.aff.genus = FALSE,
  spec.name.fix.encoding = TRUE
) {
  if (!missing(no.dates)) .no.dates.deprecated()
  spec.data <- .as.spec.data(spec.data)
  if (nrow(spec.data) == 0) stop("No names were submitted")
  WFO.data <- .read.WFO(WFO.file, WFO.data)
  WFO.cols <- .WFO.columns(WFO.data)
  has.auth <- Authorship %in% names(spec.data)
  spec.data <- .rename.conflicts(
    spec.data,
    WFO.cols,
    Authorship,
    acceptedNameUsageID.match
  )

  by.name <- spec.name %in% names(spec.data)
  if (by.name) {
    spec.data <- .clean.spec.names(spec.data, spec.name,
      squish = squish,
      spec.name.tolower = spec.name.tolower,
      spec.name.sub = spec.name.sub,
      sub.pattern = sub.pattern,
      spec.name.nobrackets = spec.name.nobrackets,
      spec.name.nonumber = spec.name.nonumber,
      spec.name.aff.genus = spec.name.aff.genus,
      spec.name.fix.encoding = spec.name.fix.encoding
    )
  }
  for (v in intersect(
    c(Genus, Species, Infraspecific.rank, Infraspecific),
    names(spec.data)
  )) {
    spec.data[[v]] <- as.character(spec.data[[v]])
    if (v %in% c(
      Infraspecific.rank,
      Infraspecific
    )) {
      spec.data[[v]][is.na(spec.data[[v]])] <- ""
    }
  }

  n <- nrow(spec.data)
  spec.data$Unique <- rep(TRUE, n)
  spec.data$Matched <- rep(TRUE, n)
  spec.data$Fuzzy <- rep(FALSE, n)
  spec.data$Fuzzy.toomany <- rep(FALSE, n)
  spec.data$Fuzzy.two <- rep(FALSE, n)
  spec.data$Fuzzy.one <- rep(FALSE, n)
  # columns of the matching steps of WorldFloraFast, only when one of them is
  # used, so that the result has the columns of WorldFlora by default
  extended <- Fuzzy.genus || Fuzzy.transfer || Fuzzy.one.strict
  if (extended) {
    spec.data$Fuzzy.genus <- rep(FALSE, n)
    spec.data$Fuzzy.transfer <- rep(FALSE, n)
    spec.data$Fuzzy.alternatives <- rep("", n)
  }
  spec.data$Fuzzy.dist <- rep(
    NA,
    n
  ) # logical, numeric once a distance is set (WorldFlora)
  if (has.auth) spec.data$Auth.dist <- rep(Inf, n)
  if (First.dist) spec.data$First.dist <- rep(Inf, n)
  spec.data$OriSeq <- seq_len(n)
  spec.data$Subseq <- rep(1, n)

  WFO.dt <- .as.dt(WFO.data)

  if (by.name) {
    index <- .cached(
      WFO.dt,
      "index.name",
      function() .build.index(.hybrid.key(WFO.dt$scientificName))
    )
    if (Fuzzy.keep.genus) {
      # genera with species names in the backbone (Fuzzy.keep.genus)
      index$sp.genera <- .cached(WFO.dt, "sp.genera", function() {
        multi <- index$u[grepl(" ", index$u, fixed = TRUE)]
        unique(sub(" .*$", "", sub(paste0("^", .HYBRID, " ?"), "", multi)))
      })
    }
    nm <- .hybrid.key(spec.data[[spec.name]])

    # 1. exact matches (one hash lookup for all records)
    if (!Fuzzy.force) {
      rows <- .lookup(index, nm)
      remain <- which(lengths(rows) == 0)
    } else {
      rows <- vector("list", n)
      remain <- seq_len(n)
    }

    # 2. conserved alternative family names (Compositae, Leguminosae, ...)
    cons <- remain[nm[remain] %in% names(.conserved.families)]
    if (length(cons) > 0) {
      rows[cons] <- .lookup(
        index,
        unname(.conserved.families[nm[cons]])
      )
    }

    # 3. fuzzy matching, once per unique name
    if (length(remain) > 0) {
      message(
        "Checking for fuzzy matches for ",
        length(remain),
        " records"
      )
    }
    fz.rec <- setdiff(remain, cons)
    fz.rec <- fz.rec[nchar(nm[fz.rec]) > 0 & Fuzzy > 0]
    # names that are only placeholders ("indet.", "sp.", "cf.") are not
    # fuzzy-matched
    if (Fuzzy.skip.placeholder) {
      fz.rec <- fz.rec[!.is.placeholder(
        nm[fz.rec],
        sub.pattern
      )]
    }
    fz <- NULL
    if (length(fz.rec) > 0) {
      todo <- unique(nm[fz.rec])
      needs.context <- Fuzzy.genus || Fuzzy.transfer || Fuzzy.one.strict ||
        Fuzzy.epithet.check
      ctx <- if (needs.context) {
        .cached(WFO.dt, "context", function() .match.context(WFO.dt))
      } else {
        NULL
      }
      one <- function(j) {
        if (verbose && j %% counter == 0) {
          message(
            "Reached unique name # ",
            j,
            " of ",
            length(todo)
          )
        }
        .fuzzy.one.name(todo[j], index,
          Fuzzy = Fuzzy, Fuzzy.force = Fuzzy.force,
          Fuzzy.max = Fuzzy.max,
          Fuzzy.min = Fuzzy.min,
          Fuzzy.shortest = Fuzzy.shortest,
          Fuzzy.within = Fuzzy.within,
          Fuzzy.two = Fuzzy.two,
          Fuzzy.one = Fuzzy.one,
          verbose = verbose,
          Fuzzy.genus = Fuzzy.genus,
          Fuzzy.transfer = Fuzzy.transfer,
          Fuzzy.one.strict = Fuzzy.one.strict,
          Fuzzy.epithet.check = Fuzzy.epithet.check,
          Fuzzy.keep.genus = Fuzzy.keep.genus, ctx = ctx
        )
      }
      fz <- .parallel.lapply(seq_along(todo), one, cores = cores)
      k <- match(nm[fz.rec], todo)
      pick <- function(f) {
        vapply(
          fz,
          function(z) z[[f]],
          FUN.VALUE = fz[[1]][[f]]
        )[k]
      }
      rows[fz.rec] <- lapply(fz, `[[`, "rows")[k]
      fz.fuzzy <- pick("fuzzy")
      fz.s <- pick("s")
      spec.data$Fuzzy[fz.rec] <- fz.fuzzy
      spec.data$Fuzzy.two[fz.rec] <- pick("Fuzzy.two")
      spec.data$Fuzzy.one[fz.rec] <- pick("Fuzzy.one")
      if (extended) {
        spec.data$Fuzzy.genus[fz.rec] <- pick("Fuzzy.genus")
        spec.data$Fuzzy.transfer[fz.rec] <- pick("Fuzzy.transfer")
        spec.data$Fuzzy.alternatives[fz.rec] <- pick("Fuzzy.alternatives")
      }
      toomany <- pick("Fuzzy.toomany")
      if (any(toomany > 0)) {
        # as in WorldFlora
        spec.data$Fuzzy.toomany <- as.integer(spec.data$Fuzzy.toomany)
        spec.data$Fuzzy.toomany[fz.rec] <- toomany
      }
    }

    # 4. one output row per candidate
    ex <- .expand.matches(spec.data, rows)
    out <- ex$out
    rec <- ex$rec
    WFO.row <- ex$WFO.row
    out$taxonID <- as.character(WFO.dt$taxonID[WFO.row])
    out$taxonID[is.na(WFO.row)] <- ""

    # Levenshtein distances of fuzzy matches to the submitted name
    if (!is.null(fz)) {
      r <- which(rec %in% fz.rec[fz.fuzzy] & !is.na(WFO.row))
      matched.name <- as.character(WFO.dt$scientificName[WFO.row[r]])
      out$Fuzzy.dist[r] <- .pair.adist(
        .hybrid.key(matched.name),
        .hybrid.key(out[[spec.name]][r]),
        na = NA_real_
      )
      if (First.dist) {
        s.used <- fz.s[match(rec[r], fz.rec)]
        out$First.dist[r] <- .pair.adist(
          sub(" .*$", "", s.used),
          sub(" .*$", "", matched.name)
        )
      }
    }
    WFO.part <- WFO.dt[WFO.row, setdiff(WFO.cols, "taxonID"), with = FALSE]
  } else {
    # matching via separate Genus / Species / Infraspecific.rank / Infraspecific
    # columns
    if (!Genus %in% names(spec.data)) {
      stop(
        "Neither '",
        spec.name,
        "' nor '",
        Genus,
        "' were found in spec.data"
      )
    }
    spec.cols <- c(Genus, Species, Infraspecific.rank, Infraspecific)
    WFO.key.cols <- c(
      "genus",
      "specificEpithet",
      "verbatimTaxonRank",
      "infraspecificEpithet"
    )
    use <- if (Infraspecific.rank %in% names(spec.data)) {
      1:4
    } else if (Infraspecific %in% names(spec.data)) {
      c(1, 2, 4)
    } else if (Species %in% names(spec.data)) {
      1:2
    } else {
      1
    }
    make.key <- function(d, cols) {
      vals <- lapply(cols, function(v) as.character(d[[v]]))
      # ranks in standard form, so "var."/"variety" and ""/"species" are
      # equivalent
      is.rank <- cols %in% c(Infraspecific.rank, "verbatimTaxonRank")
      vals[is.rank] <- lapply(vals[is.rank], .rank.key)
      k <- do.call(paste, c(vals, sep = "\r"))
      k[Reduce(`|`, lapply(cols, function(v) is.na(d[[v]])))] <- NA
      k
    }
    index <- .build.index(make.key(WFO.dt, WFO.key.cols[use]))
    q <- make.key(spec.data, spec.cols[use])
    rows <- .lookup(index, q)
    rows[is.na(q)] <- list(integer(0))
    ex <- .expand.matches(spec.data, rows)
    out <- ex$out
    WFO.row <- ex$WFO.row
    WFO.part <- WFO.dt[WFO.row, WFO.cols, with = FALSE]
    if (anyNA(WFO.row)) {
      for (v in WFO.cols) {
        data.table::set(WFO.part,
          i = which(is.na(WFO.row)), j = v,
          value = if (is.character(WFO.part[[v]])) "" else NA
        )
      }
    }
  }
  out <- cbind(out, as.data.frame(WFO.part, stringsAsFactors = FALSE))
  rownames(out) <- NULL

  .finish.match(
    out, WFO.data, WFO.cols, Authorship, has.auth, acceptedNameUsageID.match,
    exclude.infraspecific, infraspecific.excluded
  )
}

# Fuzzy matching of ONE cleaned name against the backbone index. Pure function
# (no side effects other than messages), so results can be memoised per unique
# name and computed in parallel. Reproduces the decision sequence of WorldFlora
# <= 1.14-5 (Fuzzy.two -> Fuzzy.one -> Fuzzy.max -> within/min/shortest).
.fuzzy.one.name <- function(
  s,
  index,
  Fuzzy,
  Fuzzy.force,
  Fuzzy.max,
  Fuzzy.min,
  Fuzzy.shortest,
  Fuzzy.within, Fuzzy.two, Fuzzy.one, verbose,
  Fuzzy.genus = FALSE, Fuzzy.transfer = FALSE, Fuzzy.one.strict = FALSE,
  Fuzzy.epithet.check = FALSE, Fuzzy.keep.genus = FALSE, ctx = NULL
) {
  s1 <- s
  res <- list(
    rows = integer(0), fuzzy = FALSE, Fuzzy.two = FALSE, Fuzzy.one = FALSE,
    Fuzzy.genus = FALSE, Fuzzy.transfer = FALSE, Fuzzy.toomany = 0L, s = s,
    Fuzzy.alternatives = ""
  )
  msg <- function(...) if (verbose) message(...)
  nwords <- function(ids) {
    lengths(strsplit(
      index$u[ids],
      split = " ",
      fixed = TRUE
    ))
  }
  # backbone rows, duplicated names included
  nraw <- function(ids) sum(index$cnt[ids])

  ids <- .agrep.ids(s, index$u, Fuzzy, u.nchar = index$u.nchar)
  if (Fuzzy.keep.genus) {
    ids <- .keep.genus(s, ids, index, msg)
    if (!is.null(attr(
      ids,
      "dropped"
    ))) {
      res$Fuzzy.alternatives <- .alternatives(attr(ids, "dropped"))
    }
    ids <- as.vector(ids)
  }

  if (length(ids) == 0 && Fuzzy.two) {
    terms <- strsplit(s, split = " ", fixed = TRUE)[[1]]
    if (length(terms) > 2) {
      s2 <- paste(terms[1], terms[2])
      ids <- .agrep.ids(s2, index$u, Fuzzy, u.nchar = index$u.nchar)
      if (Fuzzy.keep.genus) {
        ids <- .keep.genus(s2, ids, index, msg)
        if (!is.null(attr(ids, "dropped"))) {
          res$Fuzzy.alternatives <- paste(
            setdiff(
              c(res$Fuzzy.alternatives, .alternatives(attr(ids, "dropped"))),
              ""
            ),
            collapse = "; "
          )
        }
        ids <- as.vector(ids)
      }
      res$Fuzzy.two <- TRUE
      if (length(ids) > 0) {
        msg(
          "Fuzzy matches for ",
          s,
          " were only found for first 2 terms (",
          s2,
          ")"
        )
        s <- s2
        ids2 <- ids[nwords(ids) < 3]
        if (length(ids2) > 0) {
          msg("With Fuzzy.two, reduced matches to those of 2 words only")
          ids <- ids2
        }
      }
    }
  }

  # epithet check of the agrep() candidates; rejected names are reported
  if (Fuzzy.epithet.check && !is.null(ctx) && length(ids) > 0) {
    keep <- .epithet.check(s, index$u[ids], ctx, Fuzzy)
    if (length(keep) < length(ids)) {
      rejected <- index$u[ids[setdiff(seq_along(ids), keep)]]
      rejected <- rejected[order(as.numeric(utils::adist(
        s,
        rejected
      )))] # closest first
      msg(
        "Fuzzy matches for ",
        s,
        " rejected by the epithet check: ",
        paste(utils::head(rejected, 5), collapse = ", ")
      )
      res$Fuzzy.alternatives <- paste(
        setdiff(c(res$Fuzzy.alternatives, .alternatives(rejected)), ""),
        collapse = "; "
      )
      ids <- ids[keep]
    }
  }

  # genus, then epithet (truncated or misspelled genus with a recognisable
  # epithet), when no fuzzy candidates remain (the epithet check removes
  # candidates of unrelated genera, such as "Festuca paphlagonica" for "Scab
  # paphlagonica")
  if (Fuzzy.genus && !is.null(ctx) && length(ids) == 0) {
    r <- .genus.epithet(s, ctx, Fuzzy)
    if (length(r) > 0 && length(r) <= Fuzzy.max) {
      msg("Genus-then-epithet match for ", s, " (", length(r), " record(s))")
      res$rows <- r
      res$fuzzy <- res$Fuzzy.genus <- TRUE
      res$s <- s
      return(res)
    }
  }
  # same epithet in another genus of the family, with evidence of a genus
  # transfer
  if (length(ids) == 0 && Fuzzy.transfer && !is.null(ctx)) {
    r <- .genus.transfer(s, ctx)
    if (length(r) > 0) {
      msg("Genus-transfer match for ", s)
      res$rows <- r
      res$fuzzy <- res$Fuzzy.transfer <- TRUE
      res$s <- s
      return(res)
    }
    if (!is.null(attr(r, "alternatives"))) {
      res$Fuzzy.alternatives <- paste(
        setdiff(c(res$Fuzzy.alternatives, attr(r, "alternatives")), ""),
        collapse = "; "
      )
    }
  }

  if (length(ids) == 0 && Fuzzy.one) {
    g <- strsplit(s, split = " ", fixed = TRUE)[[1]][1]
    if (!is.na(g) && nchar(g) > 2) {
      res$Fuzzy.one <- TRUE
      g.id <- match(g, index$u)
      if (Fuzzy.one.strict && !is.null(ctx)) {
        # only an exact first word that is an accepted genus name; no fuzzy
        # genus guesses
        if (!is.na(g.id)) {
          r <- .genus.rows.strict(.rows.of(index, g.id), ctx)
          if (length(r) > 0) {
            res$rows <- r
            res$fuzzy <- TRUE
            res$s <- s
            return(res)
          }
        }
        msg("No accepted genus ", g, " for ", s, " (Fuzzy.one.strict)")
        ag <- .accepted.genus(g, ctx)
        if (!is.na(ag) && ag != g) {
          res$Fuzzy.alternatives <- paste(setdiff(c(
            res$Fuzzy.alternatives,
            paste0(ag, " (", g, " is a synonym)")
          ), ""), collapse = "; ")
        }
        res$s <- s
        return(res)
      } else if (is.na(g.id) || Fuzzy.force) {
        ids <- .agrep.ids(g, index$u, Fuzzy, u.nchar = index$u.nchar)
        if (length(ids) > 0) {
          msg(
            "Fuzzy matches for ",
            s,
            " were only found for first term (",
            g,
            ")"
          )
          s <- g
          ids2 <- ids[nwords(ids) < 2]
          if (length(ids2) > 0) {
            msg("With Fuzzy.one, reduced matches to those of 1 word only")
            ids <- ids2
          }
        }
      } else {
        # exact match of the first word (genus); reported as a fuzzy match
        res$rows <- .rows.of(index, g.id)
        res$fuzzy <- TRUE
        res$s <- s
        return(res)
      }
    }
  }

  if (length(ids) > 0 && nraw(ids) > Fuzzy.max) {
    res$Fuzzy.toomany <- nraw(ids)
    msg(
      "Too many (",
      nraw(ids),
      ") fuzzy matches for ",
      s,
      ", including ",
      index$u[ids[1]]
    )
    res$s <- s
    return(res)
  }

  if (length(ids) > 0) {
    res$fuzzy <- TRUE
    cand <- index$u[ids]
    msg("Fuzzy matches for ", s1, " were: ", paste(cand, collapse = ", "))
    if (Fuzzy.within) {
      Fuzzy.shortest <- Fuzzy.min <- FALSE
      keep <- grepl(s, x = cand)
      ids <- ids[keep]
      cand <- cand[keep]
      if (length(ids) > 0) {
        msg("Matches within for ", s1, " were: ", paste(cand, collapse = ", "))
      } else {
        msg("No matches within for ", s1)
      }
    }
    if (Fuzzy.min && length(ids) > 1) {
      Fuzzy.shortest <- FALSE
      d <- as.numeric(utils::adist(cand, y = s))
      keep <- d == min(d)
      ids <- ids[keep]
      cand <- cand[keep]
      msg(
        "Best fuzzy matches for ",
        s1,
        " were: ",
        paste(cand, collapse = ", ")
      )
    }
    if (Fuzzy.shortest && length(ids) > 1) {
      dl <- abs(nchar(cand) - nchar(s))
      keep <- dl == min(dl)
      ids <- ids[keep]
      cand <- cand[keep]
      msg(
        "Shortest fuzzy matches for ",
        s1,
        " were: ",
        paste(cand, collapse = ", ")
      )
    }
    res$rows <- .rows.of(index, ids)
  }
  res$s <- s
  res
}
