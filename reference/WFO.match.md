# Match plant names against the World Flora Online taxonomic backbone

Matches plant names, exactly or with fuzzy matching, against a static
copy of the World Flora Online (WFO) taxonomic backbone, and replaces
synonyms by their accepted names. Names are given either as full names
(column `spec.name`) or as separate genus, species and infraspecific
columns.

## Usage

``` r
WFO.match(
  spec.data = NULL,
  WFO.file = NULL,
  WFO.data = NULL,
  no.dates = TRUE,
  spec.name = "spec.name",
  Genus = "Genus",
  Species = "Species",
  Infraspecific.rank = "Infraspecific.rank",
  Infraspecific = "Infraspecific",
  Authorship = "Authorship",
  First.dist = FALSE,
  acceptedNameUsageID.match = TRUE,
  Fuzzy = 0.1,
  Fuzzy.force = FALSE,
  Fuzzy.max = 250,
  Fuzzy.min = TRUE,
  Fuzzy.shortest = FALSE,
  Fuzzy.within = FALSE,
  Fuzzy.two = TRUE,
  Fuzzy.one = TRUE,
  squish = TRUE,
  spec.name.tolower = FALSE,
  spec.name.nonumber = TRUE,
  spec.name.nobrackets = TRUE,
  exclude.infraspecific = FALSE,
  infraspecific.excluded = c("cultivar.", "f.", "sect.", "subf.", "subg.", "subsp.",
    "subvar.", "var", "var.", "[infraspec.]", "fo.", "forma", "nothosubsp.", "nothovar.",
    "sect."),
  spec.name.sub = TRUE,
  sub.pattern = c(" sp[.] A", " sp[.] B", " sp[.] C", " sp[.]", " spp[.]", " pl[.]",
    " indet[.]", " ind[.]", " gen[.]", " g[.]", " fam[.]", " nov[.]", " prox[.]",
    " cf[.]", " aff[.]", " s[.]s[.]", " s[.]l[.]", " p[.]p[.]", " p[.] p[.]", "[?]",
    " inc[.]", " stet[.]", "Ca[.]", "nom[.] cons[.]", "nom[.] dub[.]", " nom[.] err[.]",
    " nom[.] illeg[.]", " nom[.] inval[.]", " nom[.] nov[.]", " nom[.] nud[.]",
    " nom[.] obl[.]", " nom[.] prot[.]", " nom[.] rej[.]", " nom[.] supp[.]",
    " sensu auct[.]"),
  verbose = TRUE,
  counter = 1000,
  cores = 1,
  Fuzzy.genus = FALSE,
  Fuzzy.transfer = FALSE,
  Fuzzy.one.strict = FALSE,
  Fuzzy.epithet.check = TRUE,
  Fuzzy.keep.genus = TRUE,
  Fuzzy.skip.placeholder = TRUE,
  spec.name.aff.genus = FALSE,
  spec.name.fix.encoding = TRUE
)
```

## Arguments

- spec.data:

  A data.frame with the names to match, or a character vector (or
  factor) of names, which becomes column `spec.name`.

- WFO.file:

  Path to the backbone file (`classification.csv`), read with
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md).
  Ignored if `WFO.data` is given. If both are `NULL`, the backbone at
  the location remembered by
  [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  or
  [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  is read.

- WFO.data:

  The backbone as a data.frame or data.table (from
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md),
  [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  or
  [`WFO.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)).

- no.dates:

  Deprecated and ignored (columns `created` and `modified` of the
  backbone are always left out of the results); giving it produces a
  warning.

- spec.name:

  Name of the column with full plant names (without authors). If this
  column is absent, names are matched via `Genus`, `Species`,
  `Infraspecific.rank` and `Infraspecific`.

- Genus, Species, Infraspecific.rank, Infraspecific:

  Names of the columns with the genus, the specific epithet, the
  infraspecific rank (such as `"subsp."` or `"var."`, as in column
  `verbatimTaxonRank` of the backbone) and the infraspecific epithet.
  Only used without `spec.name`; only exact matches are possible.

- Authorship:

  Name of the column with the naming authors. If present, column
  `Auth.dist` gives the Levenshtein distance between the submitted and
  matched authors. As in WorldFlora, an empty author ("") gives the
  number of characters of the matched authors; use `NA` for unknown
  authors (distance `Inf`).

- First.dist:

  If `TRUE`, column `First.dist` gives the Levenshtein distance between
  the first words (usually the genera) of submitted and fuzzy-matched
  names.

- acceptedNameUsageID.match:

  If `TRUE`, replace matched synonyms by their accepted names (via
  `acceptedNameUsageID`), keeping the synonym in columns `Old.*`.

- Fuzzy:

  Maximum distance for fuzzy matching, as argument `max.distance` of
  [`agrep()`](https://rdrr.io/r/base/agrep.html): a fraction of the
  length of the name (default 0.1), or a number of edits (1 or more).
  With 0, only exact matching is done.

- Fuzzy.force:

  If `TRUE`, use fuzzy matching also for names that have exact matches.

- Fuzzy.max:

  Maximum number of fuzzy matches; names with more are left unmatched,
  with their number in column `Fuzzy.toomany`.

- Fuzzy.min:

  If `TRUE`, keep only the fuzzy matches with the smallest Levenshtein
  distance ([`utils::adist()`](https://rdrr.io/r/utils/adist.html)) to
  the submitted name.

- Fuzzy.shortest:

  If `TRUE` (and `Fuzzy.min = FALSE`), keep only the fuzzy matches with
  the most similar number of characters; this tends to remove
  infraspecific matches.

- Fuzzy.within:

  If `TRUE`, keep only fuzzy matches that contain the submitted name
  (useful for names given as their first characters only); disables
  `Fuzzy.min` and `Fuzzy.shortest`.

- Fuzzy.two:

  If `TRUE` and there were no fuzzy matches, try the first two words
  (genus and species) only.

- Fuzzy.one:

  If `TRUE` and there were still no matches, fall back to the first word
  (genus) only. A genus found this way is reported as a fuzzy match. See
  `Fuzzy.one.strict`.

- squish:

  If `TRUE`, remove repeated white space and white space at the start
  and end of names (as
  [`stringr::str_squish()`](https://stringr.tidyverse.org/reference/str_trim.html)).

- spec.name.tolower:

  If `TRUE`, convert names to lower case, with a capital first letter.

- spec.name.nonumber:

  If `TRUE`, names that contain numbers are interpreted as genera (only
  the first word is kept, without trailing digits). A morphospecies code
  at the end of a name (" sp.1", " sp.1_ECOSUR1", " sp9", " sp. 2") is
  removed first, so that "Aegiphila sp.1_ECOSUR1" gives *Aegiphila*
  (WorldFlora gave "Aegiphila1_ECOSUR").

- spec.name.nobrackets:

  If `TRUE`, remove the part of names from the first `"("` onwards (such
  as authors in brackets).

- exclude.infraspecific:

  If `TRUE`, remove matches with an infraspecific rank listed in
  `infraspecific.excluded` (after replacement by accepted names).

- infraspecific.excluded:

  Infraspecific ranks (column `verbatimTaxonRank`) removed by
  `exclude.infraspecific`.

- spec.name.sub:

  If `TRUE`, delete sections of names that match `sub.pattern`, and
  "sp", "spp" or "indet" without a full stop at the end of a name
  ("Albizia sp" gives *Albizia*, not a species whose epithet starts with
  "sp").

- sub.pattern:

  Regular expressions of sections to delete, such as `" sp[.]"`,
  `" cf[.]"` or `" nom[.] illeg[.]"`.

- verbose:

  If `TRUE`, report details of fuzzy matching.

- counter:

  Progress is reported every `counter` distinct names checked for fuzzy
  matches.

- cores:

  Number of cores for fuzzy matching
  ([`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html);
  not on Windows).

- Fuzzy.genus, Fuzzy.transfer, Fuzzy.one.strict:

  Optional matching steps of WorldFloraFast for difficult names,
  described below. All are `FALSE` by default, which keeps the matching
  steps and the result columns of WorldFlora; they can be used together
  or separately. When one of them is used, the result has the columns
  `Fuzzy.genus`, `Fuzzy.transfer` and `Fuzzy.alternatives`.

  `Fuzzy.genus`: if `TRUE` and the name was not found, match the genus
  first (genera that start with the submitted genus, or within the
  `Fuzzy` distance), then the epithet within these genera, ignoring
  Latin gender endings. Finds names with truncated or misspelled genera,
  such as "Reinwardtiod cinerum" (*Reinwardtiodendron cinereum*). Genera
  with similar names that are synonyms lead to their accepted genus, if
  the other genera give no match ("Parainarium excelsa" -\> *Parinari
  excelsa*, via the synonym *Parinarium*). For a submitted genus that
  exists in the backbone, only genera of its family are considered. Also
  used, and preferred, when
  [`agrep()`](https://rdrr.io/r/base/agrep.html) found the name only
  within names of unrelated genera (none starting with, or close to, the
  submitted genus): "Scab paphlagonica" is matched with *Scabiosa
  paphlagonica* rather than *Festuca paphlagonica*. Flagged in column
  `Fuzzy.genus`.

  `Fuzzy.transfer`: if `TRUE` and the name was still not found, look for
  the same epithet (ignoring gender endings and -i/-ii) in other genera
  of the family of the submitted genus (the family of its accepted genus
  record). Candidates whose accepted taxon is in another family are
  ignored. A candidate is accepted (1) if exactly one accepted taxon
  among the candidates is, or has a synonym, in the submitted genus: the
  backbone shows that the species moved ("Chrysophyllum
  madagascariensis" is matched with *Gambeya madagascariensis*, a
  synonym of *Gambeya boiviniana*, which also has the synonym
  *Chrysophyllum boivinianum*); or (2) if all candidates lead to one
  accepted taxon and the epithet is distinctive, used by at most 50
  accepted species in the backbone ("Lithocarpus acutissima" -\>
  *Quercus acutissima*; "Endiandra bancroftii" -\> *Beilschmiedia
  bancroftii*). Otherwise the candidates are listed in
  `Fuzzy.alternatives`. Flagged in column `Fuzzy.transfer`; please check
  such matches.

  `Fuzzy.one.strict`: if `TRUE`, the genus-only fall-back of `Fuzzy.one`
  requires the first word to be, exactly, an accepted (not synonym)
  genus name. This prevents local names from being given a scientific
  genus, such as "Palma colorada" (*Palma* Mill. is a synonym of
  *Phoenix*) or "Cedro rosado" (fuzzy match with *Cedrus*). With
  `FALSE`, the fall-back of WorldFlora is used (any exact or fuzzy match
  of the first word). When the first word is a synonym genus and nothing
  is matched, its accepted genus is listed in `Fuzzy.alternatives`
  ("Altingia fargesii": *Liquidambar*).

- Fuzzy.epithet.check:

  If `TRUE` (default), fuzzy matches found by
  [`agrep()`](https://rdrr.io/r/base/agrep.html) for names of two or
  more words are kept only if (1) the epithet is within the `Fuzzy`
  distance of the submitted epithet, computed on the epithet alone (at
  least 1 edit, and 2 for epithets of 8 or more letters; a swap of two
  adjacent letters counts as one edit; gender endings ignored), or the
  submitted epithet is the beginning of it ("Quercus cornelius" -\>
  *Quercus cornelius-mulleri*); and (2) its genus is the submitted
  genus, or a genus with a similar name in the same family.
  [`agrep()`](https://rdrr.io/r/base/agrep.html) allows a distance
  relative to the whole name, so that without this check a short epithet
  can be replaced ("Ocotea luis" -\> *Ocotea lucida*), and a name can be
  found within an unrelated longer name ("Inga ferrea" within
  "Coumarouna ferrea"). Rejected names are listed in
  `Fuzzy.alternatives`. This corrects matches of WorldFlora such as
  "Endlicheria dori" -\> *Endlicheria coriacea* (now the genus
  *Endlicheria*); `FALSE` gives the results of WorldFlora. Names whose
  second word is a rank (genus and epithet written together,
  "Dichondramrepens var. sericea") are not checked, and an epithet
  written together with the next word ("australissubsp.") is accepted.

- Fuzzy.keep.genus:

  If `TRUE` (default), a correctly spelled genus is kept: when the first
  word of a name of two or more words is a genus with species names in
  the backbone, fuzzy matches in other genera are not accepted. (A genus
  name without species, such as "Hyeronima", a variant of *Hieronyma*,
  does not keep its genus.) Matches in that genus are kept; if there are
  none, the genus-only fall-back (`Fuzzy.one`) gives the genus. "Ulmus
  parviflora" is matched with the genus *Ulmus*, not with *Tamus
  parviflora* (Dioscoreaceae); "Neea gigante" with the genus *Neea*, not
  with *Leea gigantea* (Vitaceae). This corrects matches of WorldFlora
  that replaced a correct genus by an unrelated one; `FALSE` gives the
  results of WorldFlora. The names that were not kept are listed in
  `Fuzzy.alternatives` when one of the optional steps below is used.

- Fuzzy.skip.placeholder:

  If `TRUE` (default), names made only of placeholder words ("indet.",
  "sp.", "spp.", "cf.", "aff.", "unknown", and the words of
  `sub.pattern`) are not fuzzy-matched and remain unmatched. WorldFlora
  matched "indet." with *Opuntia coindetti*, in which "indet" occurs;
  `FALSE` gives the results of WorldFlora. With
  `WFO.one(..., spec.name = "spec.name")`, such names keep the submitted
  text.

- spec.name.aff.genus:

  If `TRUE`, names with "aff." (*affinis*, near but not this species, as
  in "Drypetes aff. amazonica") are reduced to the genus. `FALSE`
  (default) removes "aff." with `sub.pattern` and matches the species,
  as in WorldFlora. Give the same value to
  [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
  and `WFO.match()`:
  [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
  already removes "aff." from the names it returns.

- spec.name.fix.encoding:

  If `TRUE` (default), repair names garbled by a wrong character
  encoding (UTF-8 text read as Mac Roman or Windows-1252, up to four
  times: "Abies holoph‚Äö√..." gives "Abies holophylla", "Citrus √ó
  aurantium" gives "Citrus × aurantium"), and replace Cyrillic letters
  that look like Latin ones in names that also contain Latin letters.
  Accented text ("Allemão") is not changed. `FALSE` gives the results of
  WorldFlora.

## Value

A data.frame with the columns of `spec.data`, followed by:

- spec.name.ORIG, Squished, Brackets.detected, Number.detected:

  Original names and the cleaning steps applied (with `spec.name` only).

- Unique:

  `TRUE` if there was one match (or none).

- Matched:

  `TRUE` if a match was found.

- Fuzzy:

  `TRUE` if the match was found by fuzzy matching.

- Fuzzy.toomany:

  Number of fuzzy matches if more than `Fuzzy.max` (else `FALSE`).

- Fuzzy.two, Fuzzy.one:

  `TRUE` if matching was tried with the first two words or the first
  word.

- Fuzzy.genus, Fuzzy.transfer:

  `TRUE` if the match was found by the genus-then-epithet step or the
  genus-transfer step. Only when one of the optional steps is used.

- Fuzzy.alternatives:

  Names that were not accepted but may have been meant (at most five
  species, with the total in brackets): fuzzy matches in another family
  than the submitted genus, and the candidates of an ambiguous genus
  transfer. Empty otherwise. Only when one of the optional steps is
  used.

- Fuzzy.dist:

  Levenshtein distance between the submitted name and the name that was
  matched (for replaced synonyms, `Old.name`).

- Auth.dist:

  Levenshtein distance between submitted and matched authors (with
  `Authorship`; `Inf` when it cannot be calculated).

- First.dist:

  Distance between the first words (with `First.dist = TRUE`).

- OriSeq:

  Row number of the submitted name in `spec.data`.

- Subseq:

  Number of the candidate for the submitted name.

- taxonID ... :

  The columns of the backbone for the match (empty or `NA` when
  unmatched).

- Hybrid:

  `"×"` if the matched name is a hybrid.

- New.accepted:

  `TRUE` if the match was a synonym that was replaced by its accepted
  name.

- Old.status, Old.ID, Old.name, Old.author:

  Status, ID, name and authors of the replaced synonym.

- Old.author.dist:

  Distance between submitted authors and those of the synonym, as text
  ("" where no synonym was replaced), as in WorldFlora.

Existing columns of `spec.data` with these names are renamed with suffix
`.ORIG`.

## Details

**Preparation of names.** When `spec.name` is used, names are first
cleaned in this order: `squish`, `spec.name.tolower`, `spec.name.sub`,
`spec.name.nobrackets`, `spec.name.nonumber`; finally `" x "` is read as
hybrid notation and replaced by `" ×"`. The submitted names are kept in
column `spec.name.ORIG`, and columns `Squished`, `Brackets.detected` and
`Number.detected` show what was changed.

**Matching.** Names are matched in this order, each step only for names
that the previous steps did not match:

1.  exact matches (hybrid notation does not matter: "Mentha x piperita",
    "Mentha ×piperita" and "Mentha × piperita" are the same name);

2.  conserved alternative family names (Compositae, Leguminosae,
    Umbelliferae, Palmae, Cruciferae, Guttiferae, Labiatae, Gramineae)
    not in the backbone, matched with their standard names (Asteraceae,
    Fabaceae, ...);

3.  fuzzy matches of the full name with
    [`agrep()`](https://rdrr.io/r/base/agrep.html), then of its first
    two words (`Fuzzy.two`), restricted to a correctly spelled genus
    (`Fuzzy.keep.genus`) and checked by `Fuzzy.epithet.check`; names
    that are only placeholders are skipped (`Fuzzy.skip.placeholder`);

4.  genus then epithet (`Fuzzy.genus`, optional), also when the fuzzy
    matches of the previous step all belong to unrelated genera; if the
    submitted genus exists in the backbone and these matches are all in
    other families, they are not accepted ("Schizolobium robustum" is
    not matched with *Schizoglossum robustum*, Apocynaceae) but listed
    in `Fuzzy.alternatives`;

5.  same epithet in another genus of the family (`Fuzzy.transfer`,
    optional);

6.  the genus only (`Fuzzy.one`; restricted by the optional
    `Fuzzy.one.strict`).

Fuzzy candidates are reduced by `Fuzzy.within`, `Fuzzy.min` or
`Fuzzy.shortest`. Submitted names with several matches get several rows,
numbered by `Subseq`;
[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
then keeps one row per submitted name.

**What fuzzy matching cannot do.**
[`agrep()`](https://rdrr.io/r/base/agrep.html) finds the submitted name
*within* longer names, which is how incomplete names such as "Pygeum
afric" are found, but it can also produce matches for local names ("Palo
blanco" is within two edits of part of "Tribulago blancoi"); such
matches have a large `Fuzzy.dist` compared with the length of the name.
Local names that are themselves names in the backbone (such as the genus
*Guayaba*) are matched like any other name. Review fuzzy matches, and
remove local names before matching where possible.

**WFO releases.** Both the conventions of WFO releases up to 2025 (ranks
"SPECIES" and "var.", hybrids written "Mentha ×piperita") and those of
the WFO Plant List 2026-06 onwards (ranks "species" and "variety",
hybrids written "Mentha × piperita") are understood, for example in
`exclude.infraspecific` and when matching by
`Genus`/`Species`/`Infraspecific.rank` columns.

**Speed.** The backbone is indexed once per call, and fuzzy matching is
done once per distinct name. Before each
[`agrep()`](https://rdrr.io/r/base/agrep.html) search, an exact
prefilter removes names that cannot match: with at most *k* edits, at
least one of *k* + 1 pieces of the submitted name occurs unchanged in
every match (pigeonhole principle), so a fast fixed-string search for
the pieces leaves few candidates. Results are identical to searching the
whole backbone.

**Differences with WorldFlora 1.14-5** are listed in the NEWS file:
notably, `Unique` is `FALSE` for names with several exact matches, and
conserved family names and unmatched names are no longer replaced by
other records, and a correctly spelled genus is not replaced by another
genus (`Fuzzy.keep.genus`), short epithets are not replaced
(`Fuzzy.epithet.check`) and placeholders are not matched
(`Fuzzy.skip.placeholder`); each of these corrections can be switched
off. Results are unchanged otherwise: by default the result columns and
their formats are those of WorldFlora, and the optional steps
`Fuzzy.genus`, `Fuzzy.transfer` and `Fuzzy.one.strict` are switched off.

## References

Kindt, R. (2020). WorldFlora: An R package for exact and fuzzy matching
of plant names against the World Flora Online taxonomic backbone data.
Applications in Plant Sciences 8(9): e11388.
[doi:10.1002/aps3.11388](https://doi.org/10.1002/aps3.11388)

## See also

[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
to keep one match per name,
[`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
to separate names and authors,
[`WFO.spelling.check()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.spelling.check.md)
to check fuzzy matches.

## Examples

``` r
## ---- default settings (those of WorldFlora) ----
# WFO.example2026 is a small extract of the WFO Plant List 2026-06
data(WFO.example2026)
m <- WFO.match(c(
  "Faidherbia albida", "Acacia albida", "Pygeum afric", "Mentha x piperita",
  "Prunus sp."
), WFO.data = WFO.example2026)
#> pattern ' x ' was interpreted as hybrid notation and replaced by ' ×'
#> Checking for fuzzy matches for 1 records
#> Fuzzy matches for Pygeum afric were: Pygeum africanum
#> 
#> Checking new accepted IDs
m[, c(
  "spec.name", "Subseq", "Fuzzy", "Fuzzy.dist", "scientificName",
  "scientificNameAuthorship", "Old.name"
)]
#>           spec.name Subseq Fuzzy Fuzzy.dist     scientificName
#> 1 Faidherbia albida      1 FALSE         NA  Faidherbia albida
#> 2     Acacia albida      1 FALSE         NA  Faidherbia albida
#> 3     Acacia albida      2 FALSE         NA Vachellia tortuosa
#> 4     Acacia albida      3 FALSE         NA      Acacia albida
#> 5      Pygeum afric      1  TRUE          4    Prunus africana
#> 6  Mentha ×piperita      1 FALSE         NA  Mentha × piperita
#> 7            Prunus      1 FALSE         NA             Prunus
#>   scientificNameAuthorship         Old.name
#> 1         (Delile) A.Chev.                 
#> 2         (Delile) A.Chev.    Acacia albida
#> 3   (L.) Seigler & Ebinger    Acacia albida
#> 4             Rojas Acosta                 
#> 5        (Hook.f.) Kalkman Pygeum africanum
#> 6                       L.                 
#> 7                       L.                 
# one match per name, with the default criteria of WFO.one()
WFO.one(m)[, c(
  "spec.name", "scientificName", "scientificNameAuthorship",
  "One.Reason"
)]
#> Different candidates for original record # 2, including Faidherbia albida
#> Found unique not a synonym case for record # 2
#>           spec.name    scientificName scientificNameAuthorship    One.Reason
#> 1 Faidherbia albida Faidherbia albida         (Delile) A.Chev.              
#> 4     Acacia albida     Acacia albida             Rojas Acosta Not a synonym
#> 5      Pygeum afric   Prunus africana        (Hook.f.) Kalkman              
#> 6  Mentha ×piperita Mentha × piperita                       L.              
#> 7            Prunus            Prunus                       L.              

# names in separate columns
WFO.match(data.frame(
  Genus = "Gambeya", Species = "boiviniana", Infraspecific.rank = "",
  Infraspecific = ""
), WFO.data = WFO.example2026)$scientificName
#> 
#> Checking new accepted IDs
#> [1] "Gambeya boiviniana"

## ---- non-default settings, marked "non-default" ----
# homonyms of "Acacia albida": the authors decide which one was meant
aa <- data.frame(
  spec.name = "Acacia albida",
  Authorship = c("Delile", "Lindl.", "")
)
m <- WFO.match(aa,
  WFO.data = WFO.example2026,
  verbose = FALSE
) # non-default: no messages
#> 
#> Checking new accepted IDs
WFO.one(m,
  Auth.dist = "Auth.dist", Old.author.dist = "Old.author.dist", # non-default
  verbose = FALSE
)[, c("Authorship", "scientificName", "Old.name", "One.Reason")]
#>   Authorship     scientificName      Old.name                        One.Reason
#> 1     Delile  Faidherbia albida Acacia albida Authorship best match for synonym
#> 5     Lindl. Vachellia tortuosa Acacia albida Authorship best match for synonym
#> 7             Faidherbia albida Acacia albida                       smallest ID

# matching steps of WorldFloraFast for difficult names
x <- c(
  "Reinwardtiod cinerum", # truncated genus
  "Chrysophyllum madagascariensis", # species transferred to another genus
  "Palma colorada"
) # local name
m <- WFO.match(x,
  WFO.data = WFO.example2026, verbose = FALSE,
  Fuzzy.genus = TRUE, Fuzzy.transfer = TRUE, # non-default
  Fuzzy.one.strict = TRUE
) # non-default
#> Checking for fuzzy matches for 3 records
#> 
#> Checking new accepted IDs
m[, c(
  "spec.name", "Matched", "Fuzzy.genus", "Fuzzy.transfer",
  "scientificName", "Old.name"
)]
#>                        spec.name Matched Fuzzy.genus Fuzzy.transfer
#> 1           Reinwardtiod cinerum    TRUE        TRUE          FALSE
#> 2 Chrysophyllum madagascariensis    TRUE       FALSE           TRUE
#> 3                 Palma colorada   FALSE       FALSE          FALSE
#>                scientificName                 Old.name
#> 1 Reinwardtiodendron cinereum                         
#> 2          Gambeya boiviniana Gambeya madagascariensis
#> 3                        <NA>                         
# with the default settings, these names are matched with genera only
m0 <- WFO.match(x, WFO.data = WFO.example2026, verbose = FALSE)
#> Checking for fuzzy matches for 3 records
#> 
#> Checking new accepted IDs
WFO.one(m0)$scientificName
#> Different candidates for original record # 1, including Saurauia
#> Found unique not a synonym case for record # 1
#> [1] "Reinwardtia"   "Chrysophyllum" "Phoenix"      

# all fuzzy candidates, then one match per name
e1 <- WFO.match("Omalanthus populneus",
  WFO.data = WFO.example2026,
  Fuzzy.min = FALSE, verbose = FALSE
) # non-default
#> Checking for fuzzy matches for 1 records
#> 
#> Checking new accepted IDs
e1[, c(
  "Subseq", "Fuzzy.dist", "scientificName", "taxonomicStatus",
  "Old.name"
)]
#>   Subseq Fuzzy.dist         scientificName taxonomicStatus
#> 1      1          2  Homalanthus populneus        Accepted
#> 2      2          2  Homalanthus populneus       Unchecked
#> 3      3         19 Homalanthus caloneurus        Accepted
#> 4      4         16  Homalanthus populneus        Accepted
#> 5      5         14  Homalanthus populneus        Accepted
#> 6      6         13  Homalanthus populneus        Accepted
#> 7      7         14        Alchornea sicca        Accepted
#>                                 Old.name
#> 1                                       
#> 2                                       
#> 3 Homalanthus populneus var. cordifolius
#> 4    Homalanthus populneus var. genuinus
#> 5      Homalanthus populneus var. laevis
#> 6       Homalanthus populneus var. minor
#> 7      Homalanthus populneus var. siccus
o1 <- WFO.one(e1, verbose = FALSE)
o1[, c("spec.name", "scientificName", "One.Reason")]
#>              spec.name        scientificName    One.Reason
#> 1 Omalanthus populneus Homalanthus populneus Not a synonym

# names in capitals
WFO.match("FAIDHERBIA ALBIDA",
  WFO.data = WFO.example2026,
  spec.name.tolower = TRUE, verbose = FALSE
)$scientificName # non-default
#> 
#> Checking new accepted IDs
#> [1] "Faidherbia albida"

# exclusion of infraspecific matches: 0 rows, the variety is excluded
nrow(WFO.match("Gambeya boiviniana var. lavanchiana",
  WFO.data = WFO.example2026,
  acceptedNameUsageID.match = FALSE, # non-default
  exclude.infraspecific = TRUE, # non-default
  verbose = FALSE
))
#> [1] 0
if (FALSE) { # \dontrun{
WFO.download() # complete backbone, available as WFO.data
WFO.match(c("Acacia nilotica", "Coffea arabika"),
  WFO.data = WFO.data,
  cores = 4
) # non-default
} # }
```
