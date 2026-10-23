# Changelog

## WorldFloraFast 1.0.8 (pre-release)

- [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
  is much faster for large inventories with repeated names: records with
  the same candidates (the same candidate rows, with the same values of
  the columns used to choose) get the same choice, so the choice is made
  once per distinct set of candidates and copied to the other records.
  The kept rows are also collected without growing a vector in the loop.
  On a 113,432-record inventory (3,315 records with several candidates,
  63 distinct names among them): 3.7 s -\> 0.2 s; on 567,160 records:
  37.0 s -\> 0.9 s. Results are identical (one row per submitted
  record), in all settings of
  [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md).
  With `verbose = TRUE`, messages are given once per distinct set of
  candidates, followed by the number of records resolved in the same
  way.

## WorldFloraFast 1.0.7 (pre-release)

- New argument `spec.name.fix.encoding` of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  and
  [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md),
  `TRUE` by default: names garbled by a wrong character encoding are
  repaired. UTF-8 text read as Mac Roman or Windows-1252, up to four
  times over, is restored (“Abies holoph‚Äö√Ñ√Æ‚àö√¢lla” gives “Abies
  holophylla”; “Citrus √ó aurantium” gives “Citrus × aurantium”), and
  Cyrillic letters that look like Latin ones are replaced in names that
  also contain Latin letters (“Abies holophуlla” with a Cyrillic “у”).
  Accented text such as “Allemão”, and text entirely in Cyrillic, are
  not changed. `FALSE` gives the results of WorldFlora. The submitted
  names remain in `spec.name.ORIG`.
- “sp”, “spp” and “indet” without a full stop at the end of a name are
  removed like “sp.” and “spp.” (with `spec.name.sub`), in
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  and
  [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md):
  “Albizia sp” gives *Albizia*; it was matched with *Albizia gummifera*,
  whose epithet was the closest to “sp”. In
  [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md),
  “Albizia sp L.” gives the name “Albizia” and the author “L.”.

## WorldFloraFast 1.0.6 (pre-release)

Refinements from a benchmark of 275 plant names with verified names,
matched against the WFO Plant List 2026-06. Correct answers (the
verified name or its current accepted name) after
[`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md):
WorldFlora 1.14-5 81.7%, WorldFloraFast 1.0.5 80.2%, 1.0.6 89.5% (93.0%
with `spec.name.aff.genus = TRUE`). On the earlier test sets, no result
changes.

- Epithet check (`Fuzzy.epithet.check`): epithets and genus names of 8
  or more letters may differ by 2 edits (1 before), and a swap of two
  adjacent letters counts as one edit. “Appunia seibertii” is matched
  with *Appunia siebertii*, “Cleyera theaeoides” with *Cleyera
  theoides*. Short epithets keep a limit of 1 edit (“Ocotea luis” is
  still not *Ocotea lucida*).
- `Fuzzy.keep.genus` applies only to genera with species names in the
  backbone: a genus name alone, such as “Hyeronima” (a variant of
  *Hieronyma*, without species in WFO), does not keep its genus.
  “Hyeronima alchorneoides” is matched with *Hieronyma alchorneoides*.
- Morphospecies codes at the end of a name (” sp.1”, ” sp.1_ECOSUR1”, ”
  sp9”, ” sp. 2”) are removed before cleaning, in
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  and
  [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md),
  so that the genus is matched: “Aegiphila sp.1_ECOSUR1” gives
  *Aegiphila*. WorldFlora removed ” sp.” and kept the rest glued to the
  genus (“Aegiphila1_ECOSUR”), which matched nothing. `Number.detected`
  is unchanged.
- New argument `spec.name.aff.genus` of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  and
  [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md),
  `FALSE` by default: if `TRUE`, names with “aff.” (“Drypetes aff.
  amazonica”) are reduced to the genus, since *affinis* means near, but
  not, the species. Give it to both functions.
- Vignette: a section on the benchmark. README: computing times of
  WorldFlora and WorldFloraFast on the benchmark.

## WorldFloraFast 1.0.5 (pre-release)

- [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  saves the backbone by default in a per-user data folder,
  `tools::R_user_dir("WorldFloraFast", "data")` (subfolder `wfo`), in a
  folder per release (for example `wfo/2026-06/classification.csv`). The
  folder is the same in every session and project, and is kept when the
  package or R are reinstalled, so the backbone is downloaded only once.
  A newer release (`update = TRUE`) is saved next to the older ones; a
  pinned release (`record.id`, `pinned = TRUE`) in its own folder.
  WorldFlora saved the backbone in the working directory:
  `save.dir = getwd()` still does, and any other `save.dir` behaves as
  before.
- In a new session,
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  without `WFO.data` or `WFO.file`,
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  and
  [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  use the backbone file remembered by the last download, or, if it no
  longer exists, the newest release in the data folder. A message gives
  the file and the release used.
- New
  [`WFO.releases()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.releases.md):
  lists the releases in the data folder (version, Zenodo record and DOI,
  date, size, which one is in use) and deletes old ones
  (`remove = "2025-12"`).

## WorldFloraFast 1.0.4 (pre-release)

- Website built with pkgdown:
  <https://jeromechave.github.io/WorldFloraFast/>, published by a GitHub
  Actions workflow (`.github/workflows/pkgdown.yaml`) on every push to
  `main`. The reference is grouped by task: matching, preparing names,
  getting the backbone, other backbones, exploring, data, deprecated
  functions.
- `DESCRIPTION` gives the website and the issue tracker (`URL`,
  `BugReports`).
- Some examples in the documentation, tests and NEWS were replaced by
  others that show the same behaviour. Results are unchanged.

## WorldFloraFast 1.0.3 (pre-release)

Code style: the package follows the [tidyverse style
guide](https://style.tidyverse.org/), checked with lintr (`.lintr`, no
lints) and formatted with styler. `STYLE.md` records the decisions.
Results are unchanged.

- Code and tests formatted with styler; lines of code, comments and
  documentation wrapped at 80 characters; comments start with a single
  `#`.
- `.lintr` records the exceptions to the style guide: the names of the
  WorldFlora API (15 of 17 exported functions and 52 of 80 argument
  names use dots, 34 with capitals, such as
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
  `Fuzzy.min`, `WFO.data`) are kept for backward compatibility; dotted
  lower-case names and internal names starting with a dot are accepted;
  cyclomatic complexity is limited to 75 (current maximum 73), to be
  lowered.
- New
  [`WFO.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md),
  the name of
  [`new.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)
  in line with the other functions;
  [`new.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md),
  the name in WorldFlora, remains as an alias (it reads like an S3
  method `new()` for a class “backbone”).
- [`download_classification()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  and
  [`read_classification()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md),
  the only snake_case exported functions (names of the stand-alone
  download script), are deprecated in favour of
  [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  and
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md);
  they still work, with a warning.

## WorldFloraFast 1.0.2 (pre-release)

- Parallel processing (`cores`) is reliable: when a parallel process
  fails (for example for lack of memory),
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  returns no result for all names of that process, which could make
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  fail or leave names unmatched. These names are now matched again
  without parallel processing, with a warning. (Few names usually need
  fuzzy matching, so `cores` is rarely needed.)
- [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
  stops with an error if its result does not have each submitted record
  exactly once, in the submitted order.
- New argument `Fuzzy.skip.placeholder` of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
  `TRUE` by default: names made only of placeholder words (“indet.”,
  “sp.”, “spp.”, “cf.”, “aff.”, “unknown”, and the words of
  `sub.pattern`) are not fuzzy-matched. WorldFlora matched “indet.” with
  *Opuntia coindetti* (= *Opuntia streptacantha*, a cactus), in which
  “indet” occurs. `FALSE` gives the results of WorldFlora.
- `Fuzzy.epithet.check` is now `TRUE` by default (a correction): fuzzy
  matches must have an epithet within the fuzzy distance of the
  submitted epithet, computed on the epithet alone. “Endlicheria dori”
  was matched with *Endlicheria coriacea* (“dori” found within the
  name), “Ocotea luis” with *Ocotea lucida*; both now give the genus.
  The check accepts epithets written together with the next word
  (“australissubsp.”) and does not judge names whose second word is a
  rank (“Dichondramrepens var. sericea”). On a sample of the WFO Plant
  List 2026-06, all 1,000 exact names and all 60 names with one typo are
  still matched correctly. `FALSE` gives the results of WorldFlora. The
  result columns `Fuzzy.genus`, `Fuzzy.transfer` and
  `Fuzzy.alternatives` are now only added when one of the optional steps
  (`Fuzzy.genus`, `Fuzzy.transfer`, `Fuzzy.one.strict`) is used, so that
  the default result has the columns of WorldFlora.

## WorldFloraFast 1.0.1 (pre-release)

- New argument `Fuzzy.keep.genus` of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
  `TRUE` by default: when the genus of a submitted name is spelled
  correctly (it is a name in the backbone), fuzzy matches in other
  genera are not accepted; matches in that genus are kept, and without
  them the genus-only fall-back gives the genus. This corrects matches
  of WorldFlora that replaced a correct genus: “Neea gigante” was
  matched with *Leea gigantea* (Vitaceae), “Ulmus parviflora” with
  *Dioscorea communis* (via *Tamus parviflora*), “Brenania nitida” with
  *Stellaria congesta*, “Sindora assamica” with *Lindera assamica*. On
  the WFO Plant List 2026-06, this changes 15 of the 70 names of the
  benchmark (all to the submitted genus or one of its species) and none
  of a sample of 1,137 names with known answers.
  `Fuzzy.keep.genus = FALSE` gives the results of WorldFlora. Names that
  were not kept are listed in `Fuzzy.alternatives` when the optional
  steps are used.

## WorldFloraFast 1.0.0 (pre-release)

First version intended for general use. Compared with WorldFlora 1.14-5,
WorldFloraFast:

- matches names much faster (on the WFO Plant List 2026-06: 50,000
  records in 5 s, misspelled names in about 0.3 s each, repeated calls
  on the same backbone in under a second);
- downloads and reads the backbone from Zenodo
  ([`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md),
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)),
  and understands the conventions of the WFO Plant List 2026-06 and of
  earlier releases;
- offers optional matching steps for difficult names (truncated or
  misspelled genera, species transferred to another genus, short
  epithets, local names);
- corrects 16 errors of WorldFlora 1.14-5 (see version 0.9.0 below);
- is documented with roxygen2, a vignette, and a provenance caption in
  each R file.

### Backward compatibility with WorldFlora

By default, WorldFloraFast behaves as WorldFlora 1.14-5 (see 1.0.1 for
one further correction, `Fuzzy.keep.genus`): same functions, arguments,
defaults, result columns (names, order and types) and data set
`WFO.example`. Only errors of WorldFlora are corrected; everything else
that WorldFloraFast adds is optional. Compared with 0.12.0, this
restores:

- the defaults of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md):
  the optional steps `Fuzzy.genus`, `Fuzzy.transfer`, `Fuzzy.one.strict`
  and `Fuzzy.epithet.check` are `FALSE`, and their result columns
  (`Fuzzy.genus`, `Fuzzy.transfer`, `Fuzzy.alternatives`) are only added
  when one of them is used;
- the types of `Subseq` (double), `Fuzzy.toomany` (integer when counts
  are given) and `Fuzzy.dist` (logical when no distance was calculated),
  and `Old.author.dist` as text (“” where no synonym was replaced);
- author distances for an empty `Authorship` (the number of characters
  of the matched authors; `NA` gives `Inf`);
- the links of
  [`WFO.url()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  (“<http://worldfloraonline.org/taxon/>…”), and the output of
  [`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  with [`cat()`](https://rdrr.io/r/base/cat.html);
- the numbering of `Subseq` after `Fuzzy.min` in
  [`WFO.match.fuzzyjoin()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.fuzzyjoin.md);
- the data set `WFO.example` of WorldFlora; the extract of the WFO Plant
  List 2026-06 used by the examples is the new data set
  `WFO.example2026`.

Differences that remain by default, because they correct errors: the
corrections of version 0.9.0 (crashes; records lost, duplicated or
matched with another record’s name; columns replaced by position;
`Unique = TRUE` for names with several exact matches; the recycled index
of
[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)),
matching that works with the conventions of the WFO Plant List 2026-06
(with earlier releases, results are unchanged), and the deprecation
warnings. Two further differences:
[`WFO.family()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
no longer returns “bryophytes” (the list of bryophyte families was
removed on request in 0.11.0), and
[`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
saves its location in the user configuration directory (it still finds
locations saved by WorldFlora).

The verification compared all functions with WorldFlora 1.14-5 on the
same data: with the default settings,
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
gives the same columns, column order and column types in 7 option
settings, and every difference of results is one of the corrections.

### Changes since 0.12.0

- Speed: the backbone was copied twice per call
  ([`data.table::as.data.table()`](https://rdrr.io/pkg/data.table/man/as.data.table.html)
  copies a data.table), which also prevented caching; the prefilter of
  [`agrep()`](https://rdrr.io/r/base/agrep.html) scans bytes
  (`useBytes = TRUE`) and only the names long enough to contain a match,
  which halves the time of fuzzy matching with identical results; the
  index and matching context of the backbone are cached between calls
  (`options(WorldFloraFast.cache = FALSE)` to switch off; the backbone
  should be a data.table, as returned by
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)).
  On the WFO Plant List 2026-06: 50,000 correctly spelled records 9.0 s
  -\> 5.0 s; 200 misspelled names 122 s -\> 59 s; a second call for one
  name 2-5 s -\> under 0.5 s.
- Removed two parts of the matching steps of 0.10.0 that the epithet
  check of 0.12.0 made redundant (a rejection of fuzzy matches in other
  families, and the test `.genus.consistent()`); results are identical
  on all test sets.
- Deprecated:
  [`WFO.match.fuzzyjoin()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.fuzzyjoin.md)
  (2.7 times slower than
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  on 100 misspelled names, with fewer correct matches of truncated
  genera, 33 against 38 of 40, and none of the new matching steps), and
  the argument `no.dates` (it had no effect).
  [`WFO.acceptable.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.acceptable.match.md)
  was deprecated in 0.11.0. Deprecated functions still work, with a
  warning, and will be removed in a later version.

## WorldFloraFast 0.12.0

Changes from a review of 70 names of a benchmark of more than 17,000
names (WFO 2026-06). Of these 70, 14 results change: 13 matches judged
wrong are no longer made, and one omission is corrected. On a sample of
1,137 names with known answers, all exact names (1,000) and names with
one typo (60) are still matched correctly; names with a truncated genus
are matched correctly in 38 of 40 cases (the other two are not valid
input).

- New argument `Fuzzy.epithet.check` (default `TRUE`): fuzzy matches
  found by [`agrep()`](https://rdrr.io/r/base/agrep.html) must have an
  epithet within the `Fuzzy` distance of the submitted epithet, computed
  on the epithet alone, or begin with it; and a genus that is the
  submitted one, or similar and of the same family.
  [`agrep()`](https://rdrr.io/r/base/agrep.html) allows a distance
  relative to the whole name, so a long genus allowed several edits in a
  short epithet: “Ocotea luis” was matched with *Ocotea lucida*,
  “Endlicheria dori” with *E. coriacea*, “Meliosma doly” with *M.
  polyneura*, “Picramnia mini” with *P. nitida*, “Cordia varo” with *C.
  mayoi*, “Dalbergia flava” with *D. elata*, “Quercus dives” with *Q.
  nivea*; “Inga ferrea” was found within “Coumarouna ferrea”, and “Neea
  gigante” was matched with *Leea gigantea* (Vitaceae). These names now
  stop at the genus, with the rejected names in `Fuzzy.alternatives`.
- Genus transfer: the family of the submitted genus is that of its
  accepted genus record (names of *Cassine* are filed under 7 families
  in WFO), and the accepted taxon of a candidate must be in that family.
  “Cassine perplexans” (*Ceanothus*, Rhamnaceae), “Eugenia arianeae”
  (*Hindsia*, Rubiaceae) and “Calophyllum ligustrinum” (*Tovomita*,
  Clusiaceae) are no longer transferred to other families.
- Genus then epithet: similar genus names that are synonyms lead to
  their accepted genus, when the other genera give no match:
  “Parainarium excelsa” is matched with *Parinari excelsa* (via the
  synonym *Parinarium*; it was not matched). For a submitted genus that
  exists in the backbone, only genera of its family are considered.
- When the first word is a synonym genus and nothing is matched,
  `Fuzzy.alternatives` gives its accepted genus (“Altingia fargesii”:
  “Liquidambar (Altingia is a synonym)”).
- Rejected names in `Fuzzy.alternatives` are listed from the closest to
  the submitted name.

## WorldFloraFast 0.11.1

- Each R source file starts with a caption that states what is inherited
  from WorldFlora 1.14-5, what was changed (with references to the
  numbered corrections of 0.9.0), and what is new in WorldFloraFast; the
  package help page
  ([`?WorldFloraFast`](https://jeromechave.github.io/WorldFloraFast/reference/WorldFloraFast-package.md))
  points to them.

## WorldFloraFast 0.11.0

- New
  [`WFO.spelling.check()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.spelling.check.md)
  replaces
  [`WFO.acceptable.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.acceptable.match.md).
  A name has one correct spelling, the one in the backbone; the function
  tells whether a submitted spelling differs from it only by common
  misspellings (wrong gender ending, i/j, double letters, hyphen, hybrid
  sign), so that the correction made by fuzzy matching can be trusted
  (“spelling corrected”), or in other ways (“other difference”: check
  the match), or not at all (“identical”).
  [`WFO.acceptable.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.acceptable.match.md)
  is deprecated; it still returns the same values as in WorldFlora.
- [`WFO.family()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  no longer contains a list of bryophyte families (which would become
  outdated). Families that are not in `vascular.families` give an empty
  result with a warning, reporting the `majorGroup` of the backbone when
  it has this column (WorldFlora returned “bryophytes”).
- The documentation of
  [`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md),
  [`WFO.synonyms()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md),
  [`WFO.family()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  and
  [`WFO.url()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  explains why they are kept (compatibility with WorldFlora), what they
  add, and gives the equivalent data.table queries.

## WorldFloraFast 0.10.0

### WFO Plant List 2026-06

The 2026-06 release (Zenodo, <https://doi.org/10.5281/zenodo.20782718>)
writes ranks in full and in lower case (`taxonRank` and
`verbatimTaxonRank` “species”, “variety”, “subspecies”, “form”; earlier
releases: “SPECIES”, and “” or “var.”) and hybrids with a space after
the sign (“Mentha × piperita”; earlier “Mentha ×piperita”). Both
conventions are now understood:

- `exclude.infraspecific` compares ranks in a standard form, so the
  default `infraspecific.excluded` (“var.”, “subsp.”, …) also excludes
  “variety”, “subspecies”, … (with 2026-06 data, nothing was excluded).
- Matching by `Genus`/`Species`/`Infraspecific.rank`/`Infraspecific`
  treats ““,”species” and missing ranks of species alike, and
  “var.”/“variety” etc. (species were not matched).
- [`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  of a species lists its infraspecific taxa only (the species itself was
  listed too).
- Exact matching ignores a space after the hybrid sign: “Mentha x
  piperita”, “Mentha ×piperita” and “Mentha × piperita” match “Mentha ×
  piperita” exactly (they were fuzzy matches).
  [`WFO.acceptable.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.acceptable.match.md)
  also ignores that space.
- `WFO.example` is now an extract of the 2026-06 release (48 rows, the
  12 columns of `WFO.read(core.only = TRUE)`), and all examples and the
  vignette use it. Note that in this release *Acacia albida* has three
  homonyms (Delile, a synonym of *Faidherbia albida*; Lindl., a synonym
  of *Vachellia tortuosa*; and Rojas Acosta, accepted): the examples
  show how authors choose between them.

### Names that need more than spelling corrections

[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
has three new arguments, all `TRUE` by default; with all three `FALSE`
the matching steps are those of WorldFlora.

- `Fuzzy.genus`: genus first, then epithet. For names with a truncated
  or misspelled genus, such as “Reinwardtiod cinerum”
  (*Reinwardtiodendron cinereum*), which was matched with the genus
  *Reinwardtia* (Linaceae). The step is also used, and preferred, when
  [`agrep()`](https://rdrr.io/r/base/agrep.html) found the name only
  within names of unrelated genera: “Scab paphlagonica” was matched with
  *Festuca paphlagonica*, now with *Scabiosa paphlagonica*. New column
  `Fuzzy.genus`.
- `Fuzzy.transfer`: the same epithet in another genus of the family,
  accepted when exactly one accepted taxon among the candidates also has
  a synonym in the submitted genus. For example “Chrysophyllum
  madagascariensis” is matched with *Gambeya madagascariensis*, a
  synonym of *Gambeya boiviniana* (which has the synonym *Chrysophyllum
  boivinianum*). New column `Fuzzy.transfer`.
- `Fuzzy.one.strict`: the genus-only fall-back (`Fuzzy.one`) requires
  the first word to be an accepted genus name. Local names are no longer
  given a scientific genus through a synonym genus or a fuzzy genus
  match (“Palma colorada” was matched with *Phoenix*, via *Palma* Mill.;
  “Cedro rosado” with *Cedrus*).

On a sample of the WFO 2026-06 release (1,000 exact names, 60 names with
a typo, 40 with a truncated genus, 30 accepted genera with an unknown
epithet, and local names), the results of exact names, names with a typo
and genera with an unknown epithet did not change; names with a
truncated genus were matched with the intended species (38 of 40,
against mostly wrong genera before); three of seven local names were no
longer given a scientific name.

#### Benchmark of difficult names (WFO 2026-06)

- Genus transfer also accepts a candidate when all same-epithet names of
  the family lead to one accepted taxon and the epithet is distinctive
  (at most 50 accepted species in the backbone): “Lithocarpus
  acutissima” -\> *Quercus acutissima*, “Endiandra bancroftii” -\>
  *Beilschmiedia bancroftii* (both were matched with the genus only).
  Epithets ending in -i and -ii are treated alike (“bancrofti”,
  “bancroftii”).
- For a submitted genus that exists in the backbone, fuzzy matches in
  unrelated genera of other families are no longer accepted:
  “Schizolobium robustum” was matched with *Schizoglossum robustum*
  (Apocynaceae), “Sindora assamica” with *Lindera assamica* (Lauraceae);
  both now stop at the genus.
- New column `Fuzzy.alternatives` lists such rejected names, and the
  candidates of an ambiguous genus transfer (“Pterocarpus vaupesiana”:
  *Tachigali*, *Calliandra* and *Swartzia vaupesiana*), for expert
  review.

### Other changes

- An empty submitted `Authorship` is treated as missing: `Auth.dist` and
  `Old.author.dist` are `Inf` (they were the number of characters of the
  matched authors, so that
  [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
  preferred the homonym with the shortest author name).
- The documentation of
  [`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md)
  describes the order of the matching steps and what fuzzy matching
  cannot do (local names that are themselves backbone names, or that
  [`agrep()`](https://rdrr.io/r/base/agrep.html) finds within longer
  names).

## WorldFloraFast 0.9.0 (pre-release)

First (pre-)release. WorldFloraFast is a faster, refactored derivative
of WorldFlora 1.14-5 (R. Kindt, GPL-3). Function names and arguments are
unchanged; new arguments are added at the end. The code was reorganised
by topic, documented with roxygen2, and a vignette was added
([`vignette("WorldFloraFast")`](https://jeromechave.github.io/WorldFloraFast/articles/WorldFloraFast.md)).

### Speed

Measured on a 1.37 million-row backbone in the WFO layout, on one core:

| Task | WorldFlora 1.14-5 | WorldFloraFast |
|----|---:|---:|
| `WFO.match`, 600 correctly spelled names | 51 s | 2.9 s |
| `WFO.match`, 3,000 correctly spelled names | ~5 min (est.) | 1.5 s |
| `WFO.match`, 12 misspelled names | 49 s | 4.2 s |
| `WFO.match`, 100 misspelled names | ~7 min (est.) | 27 s |
| `WFO.match`, 50,000-record inventory | \> 1 h (est.) | 18 s |

- The backbone is indexed once per call; exact, conserved-family, genus
  and accepted-ID lookups are hash lookups instead of scans of the whole
  backbone.
- Fuzzy matching is done once per distinct name, optionally in parallel
  (`cores`).
- Each [`agrep()`](https://rdrr.io/r/base/agrep.html) search is preceded
  by an exact pigeonhole prefilter: with at most k edits, at least one
  of k + 1 pieces of the name occurs unchanged in every match, so a
  fixed-string scan leaves a few thousand candidates for
  [`agrep()`](https://rdrr.io/r/base/agrep.html). Results are identical
  to a full scan (tested on more than 300 pattern/distance
  combinations).
- Name cleaning, output assembly, synonym replacement and distances are
  vectorised;
  [`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md)
  works per group;
  [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
  parses each distinct name once.
- [`WFO.match.fuzzyjoin()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.fuzzyjoin.md)
  uses
  [`stringdist::stringdist()`](https://rdrr.io/pkg/stringdist/man/stringdist.html)
  once per distinct name, with an exact length window for edit
  distances; `fuzzyjoin` and `dplyr` are no longer needed.

### Downloading and reading the backbone

- [`WFO.download()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  downloads the latest WFO Plant List `classification.csv` from Zenodo
  (MD5 verification, retries, no-op if present, `update = TRUE` for
  newer releases, version and DOI in `classification_source.json`).
  `WFO.url` still downloads a given zip file.
- New
  [`WFO.read()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md),
  used by all functions: all columns as character, `select` and
  `core.only` to read fewer columns.
- [`WFO.remember()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  stores the location in the user configuration directory instead of the
  installed package; locations saved by WorldFlora are still found.
  Without `WFO.data` and `WFO.file`, functions use the remembered
  backbone.
- [`download_classification()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.download.md)
  and
  [`read_classification()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.read.md)
  keep the names of the original stand-alone download script.

### Corrections (results differ from WorldFlora 1.14-5)

All functions were compared with WorldFlora 1.14-5 on the same data (8
option settings of
[`WFO.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.md),
4 of
[`WFO.match.fuzzyjoin()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.fuzzyjoin.md),
5 of
[`WFO.one()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.one.md),
5 of
[`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
/
[`WFO.preprepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md),
and
[`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md),
[`WFO.synonyms()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md),
[`WFO.acceptable.match()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.acceptable.match.md),
[`WFO.url()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md),
[`new.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md)).
Every difference is one of the corrections below.

#### WFO.match() and WFO.match.fuzzyjoin()

1.  `Fuzzy.force = TRUE` failed with “object ‘full.matches’ not found”.
2.  A name without fuzzy matches (and no genus fall-back) received the
    match of an earlier record, or caused an error if it was the first
    one.
3.  A missing `Infraspecific` value emptied `Infraspecific.rank`
    instead.
4.  `spec.name.tolower = TRUE` undid `squish`.
5.  Names with several exact matches had `Unique = TRUE`.
6.  Synonyms were replaced by accepted names by column position (wrong
    when `taxonID` is not the first backbone column); now by column
    name.
7.  `Fuzzy.within = TRUE`: when no candidate contained the name, one row
    per backbone record was returned (30,095 rows for one name on a
    30,000-row backbone).
8.  Conserved family names (Compositae, Gramineae, …) not in the
    backbone were dropped, and the previous fuzzy-matched record was
    duplicated in their place.

#### WFO.one()

9.  The authorship step indexed all candidates with a selection computed
    on part of them (recycled). The same records were chosen in all
    comparisons, but `One.Reason` now names the step that decided.

#### WFO.prepare() and WFO.preprepare()

10. [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
    failed on empty or missing names.
11. Both functions ignored `spec.full` in part (a column named
    “spec.full” was assumed) and failed for data.tables.
12. [`WFO.preprepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
    failed as soon as one name did not contain `trinomial.first`.

#### Other functions

13. [`WFO.family()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
    never warned about unmatched families
    ([`is.null()`](https://rdrr.io/r/base/NULL.html) on a data.frame).
14. [`new.backbone()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.backbone.md):
    self-referencing records were emptied but kept the status “Synonym”;
    missing `acceptedNameUsageID` values and a single extra column
    caused errors or odd column names.
15. [`WFO.url()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
    failed for data.tables and tibbles; links use
    <https://www.worldfloraonline.org>.
16. `dplyr` and `stringr` were used without being declared as
    dependencies.

### Other changes

- `Old.author.dist` is numeric (`NA` where not applicable) instead of
  character.
- [`WFO.match.fuzzyjoin()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.match.fuzzyjoin.md):
  `Subseq` is numbered 1, 2, … after `Fuzzy.min` (no gaps).
- Summarised warnings for missing or duplicated `acceptedNameUsageID`
  targets.
- [`WFO.prepare()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.prepare.md)
  gives its messages and warnings once per distinct name.
- [`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
  reports the matched name with
  [`message()`](https://rdrr.io/r/base/message.html) instead of
  [`cat()`](https://rdrr.io/r/base/cat.html).
- Requires R \>= 4.0.0. Imports data.table, jsonlite and stringr;
  stringdist is suggested.
