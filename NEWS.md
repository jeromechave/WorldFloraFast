# WorldFloraFast 1.0.1 (pre-release)

* New argument `Fuzzy.keep.genus` of `WFO.match()`, `TRUE` by default: when the genus of a
  submitted name is spelled correctly (it is a name in the backbone), fuzzy matches in other
  genera are not accepted; matches in that genus are kept, and without them the genus-only
  fall-back gives the genus. This corrects matches of WorldFlora that replaced a correct
  genus: "Trema tomentosa" was matched with *Premna tomentosa* (equally close as *Trema
  tomentosum*, 2 edits), "Ulmus parviflora" with *Dioscorea communis* (via *Tamus
  parviflora*), "Brenania nitida" with *Stellaria congesta*, "Sindora assamica" with *Lindera
  assamica*. On the WFO Plant List 2026-06, this changes 15 of the 70 names of the benchmark
  (all to the submitted genus or one of its species) and none of a sample of 1,137 names
  with known answers. `Fuzzy.keep.genus = FALSE` gives the results of WorldFlora. Names that
  were not kept are listed in `Fuzzy.alternatives` when the optional steps are used.

# WorldFloraFast 1.0.0 (pre-release)

First version intended for general use. Compared with WorldFlora 1.14-5, WorldFloraFast:

* matches names much faster (on the WFO Plant List 2026-06: 50,000 records in 5 s,
  misspelled names in about 0.3 s each, repeated calls on the same backbone in under a
  second);
* downloads and reads the backbone from Zenodo (`WFO.download()`, `WFO.read()`), and
  understands the conventions of the WFO Plant List 2026-06 and of earlier releases;
* offers optional matching steps for difficult names (truncated or misspelled genera,
  species transferred to another genus, short epithets, local names);
* corrects 16 errors of WorldFlora 1.14-5 (see version 0.9.0 below);
* is documented with roxygen2, a vignette, and a provenance caption in each R file.

## Backward compatibility with WorldFlora

By default, WorldFloraFast behaves as WorldFlora 1.14-5 (see 1.0.1 for one further
correction, `Fuzzy.keep.genus`): same functions, arguments,
defaults, result columns (names, order and types) and data set `WFO.example`. Only errors
of WorldFlora are corrected; everything else that WorldFloraFast adds is optional.
Compared with 0.12.0, this restores:

* the defaults of `WFO.match()`: the optional steps `Fuzzy.genus`, `Fuzzy.transfer`,
  `Fuzzy.one.strict` and `Fuzzy.epithet.check` are `FALSE`, and their result columns
  (`Fuzzy.genus`, `Fuzzy.transfer`, `Fuzzy.alternatives`) are only added when one of them is
  used;
* the types of `Subseq` (double), `Fuzzy.toomany` (integer when counts are given) and
  `Fuzzy.dist` (logical when no distance was calculated), and `Old.author.dist` as text
  ("" where no synonym was replaced);
* author distances for an empty `Authorship` (the number of characters of the matched
  authors; `NA` gives `Inf`);
* the links of `WFO.url()` ("http://worldfloraonline.org/taxon/..."), and the output of
  `WFO.browse()` with `cat()`;
* the numbering of `Subseq` after `Fuzzy.min` in `WFO.match.fuzzyjoin()`;
* the data set `WFO.example` of WorldFlora; the extract of the WFO Plant List 2026-06 used by
  the examples is the new data set `WFO.example2026`.

Differences that remain by default, because they correct errors: the corrections of
version 0.9.0 (crashes; records lost, duplicated or matched with another record's name;
columns replaced by position; `Unique = TRUE` for names with several exact matches; the
recycled index of `WFO.one()`), matching that works with the conventions of the WFO Plant
List 2026-06 (with earlier releases, results are unchanged), and the deprecation warnings.
Two further differences: `WFO.family()` no longer returns "bryophytes" (the list of
bryophyte families was removed on request in 0.11.0), and `WFO.remember()` saves its
location in the user configuration directory (it still finds locations saved by WorldFlora).

The verification compared all functions with WorldFlora 1.14-5 on the same data: with the
default settings, `WFO.match()` gives the same columns, column order and column types in 7
option settings, and every difference of results is one of the corrections.

## Changes since 0.12.0

* Speed: the backbone was copied twice per call (`data.table::as.data.table()` copies a
  data.table), which also prevented caching; the prefilter of `agrep()` scans bytes
  (`useBytes = TRUE`) and only the names long enough to contain a match, which halves the
  time of fuzzy matching with identical results; the index and matching context of the
  backbone are cached between calls (`options(WorldFloraFast.cache = FALSE)` to switch off;
  the backbone should be a data.table, as returned by `WFO.read()`).
  On the WFO Plant List 2026-06: 50,000 correctly spelled records 9.0 s -> 5.0 s; 200
  misspelled names 122 s -> 59 s; a second call for one name 2-5 s -> under 0.5 s.
* Removed two parts of the matching steps of 0.10.0 that the epithet check of 0.12.0 made
  redundant (a rejection of fuzzy matches in other families, and the test
  `.genus.consistent()`); results are identical on all test sets.
* Deprecated: `WFO.match.fuzzyjoin()` (2.7 times slower than `WFO.match()` on 100
  misspelled names, with fewer correct matches of truncated genera, 33 against 38 of 40,
  and none of the new matching steps), and the argument `no.dates` (it had no effect).
  `WFO.acceptable.match()` was deprecated in 0.11.0. Deprecated functions still work, with
  a warning, and will be removed in a later version.

# WorldFloraFast 0.12.0

Changes from a review of 70 names of a benchmark of more than 17,000 names (WFO 2026-06).
Of these 70, 14 results change: 13 matches judged wrong are no longer made, and one
omission is corrected. On a sample of 1,137 names with known answers, all exact names
(1,000) and names with one typo (60) are still matched correctly; names with a truncated
genus are matched correctly in 38 of 40 cases (the other two are not valid input).

* New argument `Fuzzy.epithet.check` (default `TRUE`): fuzzy matches found by `agrep()`
  must have an epithet within the `Fuzzy` distance of the submitted epithet, computed on
  the epithet alone, or begin with it; and a genus that is the submitted one, or similar
  and of the same family. `agrep()` allows a distance relative to the whole name, so a long
  genus allowed several edits in a short epithet: "Ocotea luis" was matched with *Ocotea
  lucida*, "Endlicheria dori" with *E. coriacea*, "Meliosma doly" with *M. polyneura*,
  "Picramnia mini" with *P. nitida*, "Cordia varo" with *C. mayoi*, "Dalbergia flava" with
  *D. elata*, "Quercus dives" with *Q. nivea*; "Inga ferrea" was found within "Coumarouna
  ferrea", and "Neea gigante" was matched with *Leea gigantea* (Vitaceae). These names now
  stop at the genus, with the rejected names in `Fuzzy.alternatives`.
* Genus transfer: the family of the submitted genus is that of its accepted genus record
  (names of *Cassine* are filed under 7 families in WFO), and the accepted taxon of a
  candidate must be in that family. "Cassine perplexans" (*Ceanothus*, Rhamnaceae), "Eugenia
  arianeae" (*Hindsia*, Rubiaceae) and "Calophyllum ligustrinum" (*Tovomita*, Clusiaceae) are
  no longer transferred to other families.
* Genus then epithet: similar genus names that are synonyms lead to their accepted genus,
  when the other genera give no match: "Parainarium excelsa" is matched with *Parinari
  excelsa* (via the synonym *Parinarium*; it was not matched). For a submitted genus that
  exists in the backbone, only genera of its family are considered.
* When the first word is a synonym genus and nothing is matched, `Fuzzy.alternatives` gives
  its accepted genus ("Altingia fargesii": "Liquidambar (Altingia is a synonym)").
* Rejected names in `Fuzzy.alternatives` are listed from the closest to the submitted name.

# WorldFloraFast 0.11.1

* Each R source file starts with a caption that states what is inherited from WorldFlora
  1.14-5, what was changed (with references to the numbered corrections of 0.9.0), and what
  is new in WorldFloraFast; the package help page (`?WorldFloraFast`) points to them.

# WorldFloraFast 0.11.0

* New `WFO.spelling.check()` replaces `WFO.acceptable.match()`. A name has one correct
  spelling, the one in the backbone; the function tells whether a submitted spelling
  differs from it only by common misspellings (wrong gender ending, i/j, double letters,
  hyphen, hybrid sign), so that the correction made by fuzzy matching can be trusted
  ("spelling corrected"), or in other ways ("other difference": check the match), or not
  at all ("identical"). `WFO.acceptable.match()` is deprecated; it still returns the same
  values as in WorldFlora.
* `WFO.family()` no longer contains a list of bryophyte families (which would become
  outdated). Families that are not in `vascular.families` give an empty result with a
  warning, reporting the `majorGroup` of the backbone when it has this column (WorldFlora
  returned "bryophytes").
* The documentation of `WFO.browse()`, `WFO.synonyms()`, `WFO.family()` and `WFO.url()`
  explains why they are kept (compatibility with WorldFlora), what they add, and gives
  the equivalent data.table queries.

# WorldFloraFast 0.10.0

## WFO Plant List 2026-06

The 2026-06 release (Zenodo, doi:10.5281/zenodo.20782718) writes ranks in full and in lower
case (`taxonRank` and `verbatimTaxonRank` "species", "variety", "subspecies", "form";
earlier releases: "SPECIES", and "" or "var.") and hybrids with a space after the sign
("Mentha × piperita"; earlier "Mentha ×piperita"). Both conventions are now understood:

* `exclude.infraspecific` compares ranks in a standard form, so the default
  `infraspecific.excluded` ("var.", "subsp.", ...) also excludes "variety", "subspecies", ...
  (with 2026-06 data, nothing was excluded).
* Matching by `Genus`/`Species`/`Infraspecific.rank`/`Infraspecific` treats "", "species" and
  missing ranks of species alike, and "var."/"variety" etc. (species were not matched).
* `WFO.browse()` of a species lists its infraspecific taxa only (the species itself was
  listed too).
* Exact matching ignores a space after the hybrid sign: "Mentha x piperita", "Mentha
  ×piperita" and "Mentha × piperita" match "Mentha × piperita" exactly (they were
  fuzzy matches). `WFO.acceptable.match()` also ignores that space.
* `WFO.example` is now an extract of the 2026-06 release (48 rows, the 12 columns of
  `WFO.read(core.only = TRUE)`), and all examples and the vignette use it. Note that in
  this release *Acacia albida* has three homonyms (Delile, a synonym of *Faidherbia
  albida*; Lindl., a synonym of *Vachellia tortuosa*; and Rojas Acosta, accepted): the
  examples show how authors choose between them.

## Names that need more than spelling corrections

`WFO.match()` has three new arguments, all `TRUE` by default; with all three `FALSE` the
matching steps are those of WorldFlora.

* `Fuzzy.genus`: genus first, then epithet. For names with a truncated or misspelled genus,
  such as "Reinwardtiod cinerum" (*Reinwardtiodendron cinereum*), which was matched with
  the genus *Reinwardtia* (Linaceae). The step is also used, and preferred, when `agrep()`
  found the name only within names of unrelated genera: "Scab paphlagonica" was matched
  with *Festuca paphlagonica*, now with *Scabiosa paphlagonica*. New column `Fuzzy.genus`.
* `Fuzzy.transfer`: the same epithet in another genus of the family, accepted when exactly
  one accepted taxon among the candidates also has a synonym in the submitted genus. For
  example "Chrysophyllum madagascariensis" is matched with *Gambeya madagascariensis*, a
  synonym of *Gambeya boiviniana* (which has the synonym *Chrysophyllum boivinianum*). New
  column `Fuzzy.transfer`.
* `Fuzzy.one.strict`: the genus-only fall-back (`Fuzzy.one`) requires the first word to be
  an accepted genus name. Local names are no longer given a scientific genus through a
  synonym genus or a fuzzy genus match ("Palma colorada" was matched with *Phoenix*, via
  *Palma* Mill.; "Cedro rosado" with *Cedrus*).

On a sample of the WFO 2026-06 release (1,000 exact names, 60 names with a typo, 40 with a
truncated genus, 30 accepted genera with an unknown epithet, and local names), the results
of exact names, names with a typo and genera with an unknown epithet did not change;
names with a truncated genus were matched with the intended species (38 of 40, against
mostly wrong genera before); three of seven local names were no longer given a scientific
name.

### Benchmark of difficult names (WFO 2026-06)

* Genus transfer also accepts a candidate when all same-epithet names of the family lead to
  one accepted taxon and the epithet is distinctive (at most 50 accepted species in the
  backbone): "Lithocarpus acutissima" -> *Quercus acutissima*, "Endiandra bancroftii" ->
  *Beilschmiedia bancroftii* (both were matched with the genus only). Epithets ending in -i
  and -ii are treated alike ("bancrofti", "bancroftii").
* For a submitted genus that exists in the backbone, fuzzy matches in unrelated genera of
  other families are no longer accepted: "Schizolobium robustum" was matched with
  *Schizoglossum robustum* (Apocynaceae), "Sindora assamica" with *Lindera assamica*
  (Lauraceae); both now stop at the genus.
* New column `Fuzzy.alternatives` lists such rejected names, and the candidates of an
  ambiguous genus transfer ("Pterocarpus vaupesiana": *Tachigali*, *Calliandra* and
  *Swartzia vaupesiana*), for expert review.

## Other changes

* An empty submitted `Authorship` is treated as missing: `Auth.dist` and `Old.author.dist`
  are `Inf` (they were the number of characters of the matched authors, so that
  `WFO.one()` preferred the homonym with the shortest author name).
* The documentation of `WFO.match()` describes the order of the matching steps and what
  fuzzy matching cannot do (local names that are themselves backbone names, or that
  `agrep()` finds within longer names).

# WorldFloraFast 0.9.0 (pre-release)

First (pre-)release. WorldFloraFast is a faster, refactored derivative of WorldFlora 1.14-5
(R. Kindt, GPL-3). Function names and arguments are unchanged; new arguments are added at
the end. The code was reorganised by topic, documented with roxygen2, and a vignette was
added (`vignette("WorldFloraFast")`).

## Speed

Measured on a 1.37 million-row backbone in the WFO layout, on one core:

| Task                                       | WorldFlora 1.14-5 | WorldFloraFast |
|--------------------------------------------|------------------:|---------------:|
| `WFO.match`, 600 correctly spelled names   |              51 s |          2.9 s |
| `WFO.match`, 3,000 correctly spelled names |  ~5 min (est.)    |          1.5 s |
| `WFO.match`, 12 misspelled names           |              49 s |          4.2 s |
| `WFO.match`, 100 misspelled names          |  ~7 min (est.)    |           27 s |
| `WFO.match`, 50,000-record inventory       |  > 1 h (est.)     |           18 s |

* The backbone is indexed once per call; exact, conserved-family, genus and accepted-ID
  lookups are hash lookups instead of scans of the whole backbone.
* Fuzzy matching is done once per distinct name, optionally in parallel (`cores`).
* Each `agrep()` search is preceded by an exact pigeonhole prefilter: with at most k edits,
  at least one of k + 1 pieces of the name occurs unchanged in every match, so a
  fixed-string scan leaves a few thousand candidates for `agrep()`. Results are identical
  to a full scan (tested on more than 300 pattern/distance combinations).
* Name cleaning, output assembly, synonym replacement and distances are vectorised;
  `WFO.one()` works per group; `WFO.prepare()` parses each distinct name once.
* `WFO.match.fuzzyjoin()` uses `stringdist::stringdist()` once per distinct name, with an
  exact length window for edit distances; `fuzzyjoin` and `dplyr` are no longer needed.

## Downloading and reading the backbone

* `WFO.download()` downloads the latest WFO Plant List `classification.csv` from Zenodo
  (MD5 verification, retries, no-op if present, `update = TRUE` for newer releases, version
  and DOI in `classification_source.json`). `WFO.url` still downloads a given zip file.
* New `WFO.read()`, used by all functions: all columns as character, `select` and
  `core.only` to read fewer columns.
* `WFO.remember()` stores the location in the user configuration directory instead of the
  installed package; locations saved by WorldFlora are still found. Without `WFO.data` and
  `WFO.file`, functions use the remembered backbone.
* `download_classification()` and `read_classification()` keep the names of the original
  stand-alone download script.

## Corrections (results differ from WorldFlora 1.14-5)

All functions were compared with WorldFlora 1.14-5 on the same data (8 option settings of
`WFO.match()`, 4 of `WFO.match.fuzzyjoin()`, 5 of `WFO.one()`, 5 of `WFO.prepare()` /
`WFO.preprepare()`, and `WFO.browse()`, `WFO.synonyms()`, `WFO.acceptable.match()`,
`WFO.url()`, `new.backbone()`). Every difference is one of the corrections below.

### WFO.match() and WFO.match.fuzzyjoin()

1. `Fuzzy.force = TRUE` failed with "object 'full.matches' not found".
2. A name without fuzzy matches (and no genus fall-back) received the match of an earlier
   record, or caused an error if it was the first one.
3. A missing `Infraspecific` value emptied `Infraspecific.rank` instead.
4. `spec.name.tolower = TRUE` undid `squish`.
5. Names with several exact matches had `Unique = TRUE`.
6. Synonyms were replaced by accepted names by column position (wrong when `taxonID` is not
   the first backbone column); now by column name.
7. `Fuzzy.within = TRUE`: when no candidate contained the name, one row per backbone record
   was returned (30,095 rows for one name on a 30,000-row backbone).
8. Conserved family names (Compositae, Gramineae, ...) not in the backbone were dropped,
   and the previous fuzzy-matched record was duplicated in their place.

### WFO.one()

9. The authorship step indexed all candidates with a selection computed on part of them
   (recycled). The same records were chosen in all comparisons, but `One.Reason` now names
   the step that decided.

### WFO.prepare() and WFO.preprepare()

10. `WFO.prepare()` failed on empty or missing names.
11. Both functions ignored `spec.full` in part (a column named "spec.full" was assumed) and
    failed for data.tables.
12. `WFO.preprepare()` failed as soon as one name did not contain `trinomial.first`.

### Other functions

13. `WFO.family()` never warned about unmatched families (`is.null()` on a data.frame).
14. `new.backbone()`: self-referencing records were emptied but kept the status "Synonym";
    missing `acceptedNameUsageID` values and a single extra column caused errors or odd
    column names.
15. `WFO.url()` failed for data.tables and tibbles; links use https://www.worldfloraonline.org.
16. `dplyr` and `stringr` were used without being declared as dependencies.

## Other changes

* `Old.author.dist` is numeric (`NA` where not applicable) instead of character.
* `WFO.match.fuzzyjoin()`: `Subseq` is numbered 1, 2, ... after `Fuzzy.min` (no gaps).
* Summarised warnings for missing or duplicated `acceptedNameUsageID` targets.
* `WFO.prepare()` gives its messages and warnings once per distinct name.
* `WFO.browse()` reports the matched name with `message()` instead of `cat()`.
* Requires R >= 4.0.0. Imports data.table, jsonlite and stringr; stringdist is suggested.
