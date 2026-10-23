# WFO Plant List 2026-06 conventions and the matching steps for difficult names.
# WFO.example2026 is an extract of the 2026-06 release.
data(WFO.example2026)
ex <- WFO.example2026
ns <- asNamespace("WorldFloraFast")

test_that("ranks of both WFO conventions are standardised", {
  expect_equal(
    ns$.rank.std(c(
      "variety", "var.", "VAR.", "subspecies", "subsp.", "form", "f.",
      "species", "SPECIES", "", NA
    )),
    c(
      "var.", "var.", "var.", "subsp.", "subsp.", "f.", "f.", "species",
      "species", "", ""
    )
  )
  expect_equal(ns$.rank.key(c("species", "", "variety")), c("", "", "var."))
})

test_that(
  "exclude.infraspecific works with 2026 ('variety') and old ('var.') ranks",
  {
    v <- "Gambeya boiviniana var. lavanchiana"
    expect_equal(
      nrow(q(WFO.match(
        v,
        WFO.data = ex,
        acceptedNameUsageID.match = FALSE,
        verbose = FALSE
      ))),
      1
    )
    r <- q(WFO.match(v,
      WFO.data = ex, acceptedNameUsageID.match = FALSE,
      exclude.infraspecific = TRUE, verbose = FALSE
    ))
    expect_equal(nrow(r), 0)
    old <- ex
    old$verbatimTaxonRank[old$verbatimTaxonRank == "variety"] <- "var."
    r <- q(WFO.match(v,
      WFO.data = old, acceptedNameUsageID.match = FALSE,
      exclude.infraspecific = TRUE, verbose = FALSE
    ))
    expect_equal(nrow(r), 0)
  }
)

test_that("matching by separate columns works with 2026 ranks", {
  d <- data.frame(
    Genus = c("Gambeya", "Gambeya", "Gambeya"), Species = "boiviniana",
    Infraspecific.rank = c(
      "",
      "species",
      "var."
    ), Infraspecific = c("", "", "lavanchiana")
  )
  r <- q(WFO.match(d, WFO.data = ex, acceptedNameUsageID.match = FALSE))
  expect_equal(
    r$scientificName,
    c(
      "Gambeya boiviniana",
      "Gambeya boiviniana",
      "Gambeya boiviniana var. lavanchiana"
    )
  )
})

test_that(
  "WFO.browse of a species lists infraspecific taxa only (2026 ranks)",
  {
    b <- q(WFO.browse("Gambeya boiviniana", WFO.data = ex))
    expect_equal(b$scientificName, "Gambeya boiviniana var. lavanchiana")
  }
)

test_that("hybrids match exactly in both notations", {
  x <- c("Mentha x piperita", "Mentha \u00d7piperita", "Mentha \u00d7 piperita")
  r <- q(WFO.match(x, WFO.data = ex, verbose = FALSE))
  expect_true(all(r$Matched) && !any(r$Fuzzy))
  expect_equal(unique(r$scientificName), "Mentha \u00d7 piperita")
  expect_equal(r$Hybrid, rep("\u00d7", 3))
  old <- ex
  old$scientificName <- gsub(
    "\u00d7 ",
    "\u00d7",
    old$scientificName
  ) # WFO <= 2025 notation
  r <- q(WFO.match(x, WFO.data = old, verbose = FALSE))
  expect_true(all(r$Matched) && !any(r$Fuzzy))
  expect_equal(
    WFO.spelling.check(data.frame(
      spec.name = c("Mentha piperita", "Mentha \u00d7piperita"),
      scientificName = "Mentha \u00d7 piperita",
      New.accepted = FALSE,
      Old.name = ""
    )),
    c("spelling corrected", "identical")
  )
})

test_that("edge cases: truncated genus, genus transfer, local name", {
  x <- c(
    "Reinwardtiod cinerum",
    "Chrysophyllum madagascariensis",
    "Palma colorada"
  )
  r <- q(WFO.match.ff(x, WFO.data = ex, verbose = FALSE))
  expect_equal(
    r$scientificName,
    c("Reinwardtiodendron cinereum", "Gambeya boiviniana", NA)
  )
  expect_equal(r$Fuzzy.genus, c(TRUE, FALSE, FALSE))
  expect_equal(r$Fuzzy.transfer, c(FALSE, TRUE, FALSE))
  expect_equal(r$Old.name[2], "Gambeya madagascariensis")
  expect_false(r$Matched[3])
})

test_that(
  "with the new steps switched off, the genus fall-back of WorldFlora is used",
  {
    x <- c(
      "Reinwardtiod cinerum",
      "Chrysophyllum madagascariensis",
      "Palma colorada"
    )
    r <- q(WFO.match(
      x,
      WFO.data = ex,
      verbose = FALSE
    )) # defaults: WorldFlora steps
    expect_false(any(c(
      "Fuzzy.genus",
      "Fuzzy.transfer",
      "Fuzzy.alternatives"
    ) %in% names(r)))
    r1 <- q(WFO.one(r, verbose = FALSE))
    expect_equal(
      r1$scientificName,
      c("Reinwardtia", "Chrysophyllum", "Phoenix")
    )
    expect_true(all(r1$Fuzzy.one))
  }
)

test_that(
  "a genus transfer needs evidence; otherwise the accepted genus",
  {
    ex2 <- ex[ex$scientificName != "Chrysophyllum boivinianum", ]
    r <- q(WFO.match.ff(
      "Chrysophyllum madagascariensis",
      WFO.data = ex2,
      verbose = FALSE
    ))
    expect_false(r$Fuzzy.transfer)
    expect_equal(r$scientificName, "Chrysophyllum")
    expect_equal(r$taxonRank, "genus")
  }
)

test_that(
  "strict genus fall-back keeps accepted genera and refuses synonym genera",
  {
    r <- q(WFO.match.ff(
      c("Ceiba roja", "Gambeya unknownensis", "Palma sp1 colorada"),
      WFO.data = ex,
      verbose = FALSE
    ))
    expect_equal(r$scientificName[1:2], c("Ceiba", "Gambeya"))
    # "Palma sp1 colorada" contains a number: reduced to "Palma", an exact name
    # (synonym of Phoenix)
    expect_equal(r$scientificName[3], "Phoenix")
  }
)

test_that(
  "homonyms resolved by authors; NA authors: Inf, empty: their length",
  {
    aa <- data.frame(
      spec.name = "Acacia albida",
      Authorship = c("Delile", "Lindl.", NA)
    )
    m <- q(WFO.match(aa, WFO.data = ex, verbose = FALSE))
    expect_true(all(is.infinite(m$Auth.dist[m$OriSeq == 3])))
    m0 <- q(WFO.match(
      data.frame(spec.name = "Acacia albida", Authorship = ""),
      WFO.data = ex,
      verbose = FALSE
    ))
    expect_equal(
      m0$Auth.dist,
      nchar(m0$scientificNameAuthorship)
    ) # as in WorldFlora
    o <- q(WFO.one(
      m,
      Auth.dist = "Auth.dist",
      Old.author.dist = "Old.author.dist",
      verbose = FALSE
    ))
    expect_equal(
      o$scientificName,
      c("Faidherbia albida", "Vachellia tortuosa", "Acacia albida")
    )
    expect_equal(o$scientificNameAuthorship[3], "Rojas Acosta")
  }
)

test_that(
  "unrelated genera rejected, then genus-then-epithet finds the name",
  {
    bk <- bb(
      c("Scabiosa", "Scabiosa paphlagonica", "Festuca", "Festuca paphlagonica"),
      c("Caprifoliaceae", "Caprifoliaceae", "Poaceae", "Poaceae")
    )
    r <- q(WFO.match.ff("Scab paphlagonica", WFO.data = bk, verbose = FALSE))
    expect_true(r$Fuzzy.genus)
    expect_equal(r$scientificName, "Scabiosa paphlagonica")
    expect_match(r$Fuzzy.alternatives, "Festuca paphlagonica")
  }
)


test_that(
  "transfer: distinctive epithet unique in family accepted (bancrofti)",
  {
    bk <- bb(
      c(
        "Endiandra",
        "Endiandra sieberi",
        "Beilschmiedia",
        "Beilschmiedia bancroftii",
        "Acacia bancrofti"
      ),
      c("Lauraceae", "Lauraceae", "Lauraceae", "Lauraceae", "Fabaceae")
    )
    r <- q(WFO.match.ff("Endiandra bancroftii", WFO.data = bk, verbose = FALSE))
    expect_true(r$Fuzzy.transfer)
    expect_equal(r$scientificName, "Beilschmiedia bancroftii")
  }
)

test_that("transfer: several candidate species are not accepted but listed", {
  bk <- bb(
    c(
      "Pterocarpus",
      "Pterocarpus indicus",
      "Swartzia vaupesiana",
      "Tachigali vaupesiana"
    ),
    "Fabaceae"
  )
  r <- q(WFO.match.ff("Pterocarpus vaupesiana", WFO.data = bk, verbose = FALSE))
  expect_false(r$Fuzzy.transfer)
  expect_equal(r$scientificName, "Pterocarpus")
  expect_equal(
    r$Fuzzy.alternatives,
    "Swartzia vaupesiana; Tachigali vaupesiana"
  )
})

test_that(
  "fuzzy matches only in another family are not accepted for an existing genus",
  {
    bk <- bb(
      c("Sindora", "Sindora siamensis", "Lindera", "Lindera assamica"),
      c("Fabaceae", "Fabaceae", "Lauraceae", "Lauraceae")
    )
    r <- q(WFO.match.ff("Sindora assamica", WFO.data = bk, verbose = FALSE))
    expect_equal(r$scientificName, "Sindora")
    expect_equal(r$Fuzzy.alternatives, "Lindera assamica")
    r0 <- q(WFO.match(
      "Sindora assamica",
      WFO.data = bk,
      Fuzzy.keep.genus = FALSE,
      Fuzzy.epithet.check = FALSE,
      verbose = FALSE
    ))
    expect_equal(r0$scientificName, "Lindera assamica") # WorldFlora behaviour
  }
)

test_that("WFO.family warns for families outside vascular.families", {
  bk <- data.frame(
    taxonID = c(
      "1",
      "2"
    ), scientificName = c(
      "Sphagnum",
      "Sphagnum palustre"
    ), scientificNameAuthorship = "",
    taxonRank = c(
      "genus",
      "species"
    ), taxonomicStatus = "Accepted", acceptedNameUsageID = "",
    family = "Sphagnaceae", majorGroup = "B", stringsAsFactors = FALSE
  )
  expect_warning(
    f <- suppressMessages(WFO.family(
      "Sphagnum palustre",
      WFO.data = bk,
      verbose = FALSE
    )),
    "majorGroup in the backbone: B"
  )
  expect_equal(nrow(f), 0)
})

# ---- rules from the 70-name diagnosis (WorldFloraFast 0.12.0) ----

test_that(
  "family of a genus from its accepted genus record (not Rhamnaceae)",
  {
    bk <- bb(
      c(
        "Cassine",
        "Cassine peragua",
        "Cassine rhamnoides",
        "Ceanothus perplexans"
      ),
      c("Celastraceae", "Celastraceae", "Rhamnaceae", "Rhamnaceae")
    )
    r <- q(WFO.match.ff("Cassine perplexans", WFO.data = bk, verbose = FALSE))
    expect_false(r$Fuzzy.transfer)
    expect_equal(r$scientificName, "Cassine")
  }
)

test_that("a transfer needs the accepted taxon in the family too", {
  bk <- bb(c("Quercus", "Quercus robur", "Meliosma dives", "Meliosma idiopoda"),
    c("Fagaceae", "Fagaceae", "Fagaceae", "Sabiaceae"),
    status = c(
      "Accepted",
      "Accepted",
      "Synonym",
      "Accepted"
    ), accepted = c("", "", "id4", "")
  )
  r <- q(WFO.match.ff("Quercus dives", WFO.data = bk, verbose = FALSE))
  expect_equal(r$scientificName, "Quercus")
})

test_that(
  "epithet check: short epithets cannot be replaced; typos in endings are kept",
  {
    bk <- bb(
      c(
        "Ocotea",
        "Ocotea lucida",
        "Disa",
        "Disa equestris",
        "Quercus",
        "Quercus cornelius-mulleri"
      ),
      c(
        "Lauraceae",
        "Lauraceae",
        "Orchidaceae",
        "Orchidaceae",
        "Fagaceae",
        "Fagaceae"
      )
    )
    r <- q(WFO.match.ff(
      c("Ocotea luis", "Disa equestrism", "Quercus cornelius"),
      WFO.data = bk,
      verbose = FALSE
    ))
    expect_equal(
      r$scientificName,
      c("Ocotea", "Disa equestris", "Quercus cornelius-mulleri")
    )
    expect_match(r$Fuzzy.alternatives[1], "Ocotea lucida")
    r0 <- q(WFO.match.ff(
      "Ocotea luis",
      WFO.data = bk,
      Fuzzy.epithet.check = FALSE,
      verbose = FALSE
    ))
    expect_equal(r0$scientificName, "Ocotea lucida") # WorldFlora behaviour
  }
)

test_that(
  "a one-letter change of an existing genus into another family is rejected",
  {
    bk <- bb(
      c("Neea", "Neea floribunda", "Leea", "Leea gigantea"),
      c("Nyctaginaceae", "Nyctaginaceae", "Vitaceae", "Vitaceae")
    )
    r <- q(WFO.match.ff("Neea gigante", WFO.data = bk, verbose = FALSE))
    expect_equal(r$scientificName, "Neea")
    expect_match(r$Fuzzy.alternatives, "^Leea gigantea")
  }
)

test_that(
  "genus then epithet follows synonym genera, but only as a fall-back",
  {
    bk <- bb(
      c("Parinari", "Parinarium", "Parinari excelsa"), "Chrysobalanaceae",
      status = c("Accepted", "Synonym", "Accepted"), accepted = c("", "id1", "")
    )
    r <- q(WFO.match.ff("Parainarium excelsa", WFO.data = bk, verbose = FALSE))
    expect_equal(r$scientificName, "Parinari excelsa")
    bk2 <- bb(
      c(
        "Triquetrella",
        "Triquetrella californica",
        "Triquetra",
        "Astragalus",
        "Astragalus californicus"
      ),
      c("Pottiaceae", "Pottiaceae", "Fabaceae", "Fabaceae", "Fabaceae"),
      status = c(
        "Accepted",
        "Accepted",
        "Synonym",
        "Accepted",
        "Accepted"
      ), accepted = c("", "", "id4", "", "")
    )
    r <- q(WFO.match.ff("Triquetr californica",
      WFO.data = bk2, verbose = FALSE
    ))
    expect_equal(r$scientificName, "Triquetrella californica")
  }
)

test_that("an unmatched name in a synonym genus lists the accepted genus", {
  bk <- bb(
    c("Liquidambar", "Altingia", "Liquidambar formosana"), "Altingiaceae",
    status = c("Accepted", "Synonym", "Accepted"), accepted = c("", "id1", "")
  )
  r <- q(WFO.match.ff("Altingia fargesii", WFO.data = bk, verbose = FALSE))
  expect_false(r$Matched)
  expect_equal(r$Fuzzy.alternatives, "Liquidambar (Altingia is a synonym)")
})

test_that("a correctly spelled genus is kept (Fuzzy.keep.genus, default)", {
  bk <- bb(
    c(
      "Neea", "Neea floribunda", "Leea", "Leea gigantea",
      "Ulmus", "Ulmus pumila", "Tamus parviflora"
    ),
    c(
      "Nyctaginaceae", "Nyctaginaceae", "Vitaceae", "Vitaceae",
      "Ulmaceae", "Ulmaceae", "Dioscoreaceae"
    )
  )
  r <- q(WFO.match(
    c("Neea gigante", "Ulmus parviflora", "Ulmuss pumila"),
    WFO.data = bk,
    verbose = FALSE
  ))
  expect_equal(r$scientificName, c("Neea", "Ulmus", "Ulmus pumila"))
  expect_equal(r$taxonRank[1:2], c("genus", "genus"))
  # WorldFlora behaviour
  r0 <- q(WFO.match(
    c("Ulmus parviflora", "Neea gigante"),
    WFO.data = bk,
    Fuzzy.keep.genus = FALSE,
    Fuzzy.epithet.check = FALSE,
    verbose = FALSE
  ))
  expect_equal(r0$scientificName, c("Tamus parviflora", "Leea gigantea"))
  # the candidates that were not kept are reported when the optional columns are
  # used
  r1 <- q(WFO.match(
    "Ulmus parviflora",
    WFO.data = bk,
    Fuzzy.one.strict = TRUE,
    verbose = FALSE
  ))
  expect_equal(r1$Fuzzy.alternatives, "Tamus parviflora")
})

# ---- 1.0.2: placeholders, epithet check by default, parallel processing ----

test_that(
  "placeholders are not fuzzy-matched (Fuzzy.skip.placeholder, default)",
  {
    bk <- bb(
      c("Opuntia", "Opuntia coindetti", "Acacia", "Acacia albida"),
      c("Cactaceae", "Cactaceae", "Fabaceae", "Fabaceae")
    )
    r <- q(WFO.match(
      c("indet.", "sp.", "Indet", "cf.", "Acacia sp."),
      WFO.data = bk,
      verbose = FALSE
    ))
    expect_equal(r$Matched, c(FALSE, FALSE, FALSE, FALSE, TRUE))
    expect_equal(r$scientificName[5], "Acacia")
    expect_equal(r$spec.name.ORIG[1], "indet.")
    r0 <- q(WFO.match(
      "indet.",
      WFO.data = bk,
      Fuzzy.skip.placeholder = FALSE,
      verbose = FALSE
    ))
    expect_equal(r0$scientificName, "Opuntia coindetti") # WorldFlora behaviour
    expect_equal(
      q(WFO.one(r, spec.name = "spec.name", verbose = FALSE))$scientificName[1],
      "indet."
    )
  }
)

test_that("the epithet check is on by default and adds no columns", {
  bk <- bb(
    c("Endlicheria", "Endlicheria coriacea", "Ocotea", "Ocotea lucida"),
    c("Lauraceae", "Lauraceae", "Lauraceae", "Lauraceae")
  )
  r <- q(WFO.match(
    c("Endlicheria dori", "Ocotea luis", "Ocotea lucidda"),
    WFO.data = bk,
    verbose = FALSE
  ))
  expect_equal(r$scientificName, c("Endlicheria", "Ocotea", "Ocotea lucida"))
  expect_false(any(c(
    "Fuzzy.genus",
    "Fuzzy.transfer",
    "Fuzzy.alternatives"
  ) %in% names(r)))
  r0 <- q(WFO.match(
    "Endlicheria dori",
    WFO.data = bk,
    Fuzzy.epithet.check = FALSE,
    verbose = FALSE
  ))
  # WorldFlora behaviour
  expect_equal(r0$scientificName, "Endlicheria coriacea")
})

test_that("the epithet check accepts epithets run together with a rank", {
  bk <- bb(
    c(
      "Phragmites", "Phragmites australis",
      "Phragmites australis subsp. americanus",
      "Dichondra", "Dichondra repens", "Dichondra repens var. sericea"
    ),
    c(
      "Poaceae",
      "Poaceae",
      "Poaceae",
      "Convolvulaceae",
      "Convolvulaceae",
      "Convolvulaceae"
    )
  )
  r <- q(WFO.match(
    c("Phragmites australissubsp. americanus", "Dichondramrepens var. sericea"),
    WFO.data = bk,
    verbose = FALSE
  ))
  expect_equal(
    r$scientificName,
    c("Phragmites australis subsp. americanus", "Dichondra repens var. sericea")
  )
})

test_that("results of failed parallel processes are computed again", {
  skip_on_os("windows")
  ns <- asNamespace("WorldFloraFast")
  parent <- Sys.getpid()
  # workers 'lose' every third result
  f <- function(i) {
    if (Sys.getpid() != parent && i %% 3 == 0) NULL else list(rows = i)
  }
  expect_warning(r <- ns$.parallel.lapply(1:12, f, cores = 2), "matched again")
  expect_equal(vapply(r, `[[`, 0L, "rows"), 1:12)
})

test_that("WFO.one returns each submitted record once, in order", {
  r <- q(WFO.match(
    c("Acacia albida", "indet.", "", NA, "Acacia albida", "Gambeya boiviniana"),
    WFO.data = ex,
    verbose = FALSE
  ))
  o <- q(WFO.one(r, verbose = FALSE))
  expect_equal(o$OriSeq, 1:6)
})

# ---- 1.0.6: benchmark refinements ----

test_that("edit distance counts an adjacent swap once; long words allow 2", {
  ns <- asNamespace("WorldFloraFast")
  expect_equal(ns$.edit.dist("seibertii", "siebertii"), 1)
  expect_equal(ns$.edit.dist("abc", "acb"), 1)
  expect_equal(ns$.edit.dist("theaeoides", "theoides"), 2)
  expect_equal(ns$.word.k("theaeoides", 0.1), 2)
  expect_equal(ns$.word.k("luis", 0.1), 1)
})

test_that("epithet check: swaps and 2 edits in long epithets are accepted", {
  bk <- bb(
    c("Appunia", "Appunia siebertii", "Cleyera", "Cleyera theoides"),
    c("Rubiaceae", "Rubiaceae", "Pentaphylacaceae", "Pentaphylacaceae")
  )
  r <- q(WFO.match(c("Appunia seibertii", "Cleyera theaeoides"),
    WFO.data = bk, verbose = FALSE
  ))
  expect_equal(r$scientificName, c("Appunia siebertii", "Cleyera theoides"))
})

test_that("a genus name without species does not keep its genus", {
  bk <- bb(
    c("Hyeronima", "Hieronyma", "Hieronyma alchorneoides"),
    "Phyllanthaceae",
    status = c("Unchecked", "Accepted", "Accepted")
  )
  r <- q(WFO.match("Hyeronima alchorneoides", WFO.data = bk, verbose = FALSE))
  expect_equal(r$scientificName, "Hieronyma alchorneoides")
})

test_that("morphospecies codes leave the genus", {
  bk <- bb(c("Aegiphila", "Aegiphila elata"), "Lamiaceae")
  x <- c("Aegiphila sp.1_ECOSUR1", "Aegiphila sp9", "Aegiphila sp. 2")
  r <- q(WFO.match(x, WFO.data = bk, verbose = FALSE))
  expect_equal(r$scientificName, rep("Aegiphila", 3))
  p <- q(WFO.prepare(x, spec.full = "spec.full", verbose = FALSE))
  expect_equal(p$spec.name, rep("Aegiphila", 3))
})

test_that("spec.name.aff.genus reduces aff. names to the genus", {
  bk <- bb(c("Drypetes", "Drypetes amazonica"), "Putranjivaceae")
  x <- c("Drypetes aff. amazonica", "Drypetes sp. aff. amazonica")
  r0 <- q(WFO.match(x, WFO.data = bk, verbose = FALSE))
  expect_equal(r0$scientificName, rep("Drypetes amazonica", 2)) # WorldFlora
  r <- q(WFO.match(x,
    WFO.data = bk, spec.name.aff.genus = TRUE, verbose = FALSE
  ))
  expect_equal(r$scientificName, rep("Drypetes", 2))
  p <- q(WFO.prepare("Annona lutescens Saff.",
    spec.full = "spec.full", spec.name.aff.genus = TRUE, verbose = FALSE
  ))
  expect_equal(p$spec.name, "Annona lutescens") # Saff. is an author
})

# ---- 1.0.7: garbled text, look-alike letters, "sp" without a full stop ----

test_that("garbled text and Cyrillic look-alike letters are repaired", {
  ns <- asNamespace("WorldFloraFast")
  bad <- paste0(
    "Abies holoph\u201a\u00c4\u00f6\u221a\u00d1\u221a\u00c6\u201a",
    "\u00e0\u00f6\u221a\u00a2lla"
  )
  expect_equal(ns$.fix.encoding(bad), "Abies holophylla")
  expect_equal(ns$.fix.encoding("Abies holoph\u0443lla"), "Abies holophylla")
  expect_equal(
    ns$.fix.encoding("Citrus \u221a\u00f3 aurantium"),
    "Citrus \u00d7 aurantium"
  )
  # left unchanged: accented text, all-Cyrillic text, ordinary names
  expect_equal(ns$.fix.encoding("Allem\u00e3o"), "Allem\u00e3o")
  cyrillic <- "\u041a\u043e\u043c\u0430\u0440\u043e\u0432"
  expect_equal(ns$.fix.encoding(cyrillic), cyrillic)
  expect_equal(ns$.fix.encoding("Abies alba"), "Abies alba")
  bk <- bb(c("Abies", "Abies holophylla"), "Pinaceae")
  r <- q(WFO.match(bad, WFO.data = bk, verbose = FALSE))
  expect_equal(r$scientificName, "Abies holophylla")
  expect_false(r$Fuzzy)
  expect_equal(r$spec.name.ORIG, bad)
  p <- q(WFO.prepare(bad, spec.full = "spec.full", verbose = FALSE))
  expect_equal(p$spec.name, "Abies holophylla")
  r0 <- q(WFO.match(bad,
    WFO.data = bk, spec.name.fix.encoding = FALSE, verbose = FALSE
  ))
  expect_true(r0$Fuzzy) # WorldFlora behaviour: no repair
})

test_that("sp, spp and indet without a full stop leave the genus", {
  bk <- bb(c("Albizia", "Albizia gummifera", "Albizia lebbeck"), "Fabaceae")
  x <- c("Albizia sp", "Albizia spp", "Albizia indet", "Albizia sp.")
  r <- q(WFO.match(x, WFO.data = bk, verbose = FALSE))
  expect_equal(r$scientificName, rep("Albizia", 4))
  expect_true(all(!r$Fuzzy))
  p <- q(WFO.prepare(c(x, "Albizia sp L."),
    spec.full = "spec.full", verbose = FALSE
  ))
  expect_equal(p$spec.name, rep("Albizia", 5))
  expect_equal(p$Authorship[5], "L.")
})

# ---- 1.0.8: WFO.one() chooses once per distinct set of candidates ----

test_that("WFO.one: repeated names get the same choice, authors still decide", {
  aa <- data.frame(
    spec.name = "Acacia albida",
    Authorship = c("Delile", "Lindl.", "Delile", "Lindl.", NA, "Delile")
  )
  m <- q(WFO.match(aa, WFO.data = ex, verbose = FALSE))
  o <- q(WFO.one(m,
    Auth.dist = "Auth.dist", Old.author.dist = "Old.author.dist",
    verbose = FALSE
  ))
  expect_equal(o$OriSeq, 1:6)
  # the same name with the same author gets the same choice; another author
  # can give another choice
  expect_equal(o$scientificName[c(1, 3, 6)], rep(o$scientificName[1], 3))
  expect_equal(o$scientificName[2], o$scientificName[4])
  expect_false(o$scientificName[1] == o$scientificName[2])
  # without authors, all copies of a name get the same choice and reason
  o2 <- q(WFO.one(m, verbose = FALSE))
  expect_equal(length(unique(o2$scientificName)), 1)
  expect_equal(length(unique(o2$One.Reason)), 1)
  expect_message(
    WFO.one(m, verbose = TRUE),
    "had the same candidates as an earlier record"
  )
})
