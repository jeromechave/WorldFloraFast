## WFO Plant List 2026-06 conventions and the matching steps for difficult names.
## WFO.example2026 is an extract of the 2026-06 release.
data(WFO.example2026)
E <- WFO.example2026
ns <- asNamespace("WorldFloraFast")

test_that("ranks of both WFO conventions are standardised", {
  expect_equal(ns$.rank.std(c("variety", "var.", "VAR.", "subspecies", "subsp.", "form", "f.", "species", "SPECIES", "", NA)),
               c("var.", "var.", "var.", "subsp.", "subsp.", "f.", "f.", "species", "species", "", ""))
  expect_equal(ns$.rank.key(c("species", "", "variety")), c("", "", "var."))
})

test_that("exclude.infraspecific works with 2026 ranks ('variety') and old ranks ('var.')", {
  v <- "Gambeya boiviniana var. lavanchiana"
  expect_equal(nrow(q(WFO.match(v, WFO.data = E, acceptedNameUsageID.match = FALSE, verbose = FALSE))), 1)
  expect_equal(nrow(q(WFO.match(v, WFO.data = E, acceptedNameUsageID.match = FALSE,
                                exclude.infraspecific = TRUE, verbose = FALSE))), 0)
  old <- E; old$verbatimTaxonRank[old$verbatimTaxonRank == "variety"] <- "var."
  expect_equal(nrow(q(WFO.match(v, WFO.data = old, acceptedNameUsageID.match = FALSE,
                                exclude.infraspecific = TRUE, verbose = FALSE))), 0)
})

test_that("matching by separate columns works with 2026 ranks", {
  d <- data.frame(Genus = c("Gambeya", "Gambeya", "Gambeya"), Species = "boiviniana",
                  Infraspecific.rank = c("", "species", "var."), Infraspecific = c("", "", "lavanchiana"))
  r <- q(WFO.match(d, WFO.data = E, acceptedNameUsageID.match = FALSE))
  expect_equal(r$scientificName, c("Gambeya boiviniana", "Gambeya boiviniana", "Gambeya boiviniana var. lavanchiana"))
})

test_that("WFO.browse of a species lists infraspecific taxa only (2026 ranks)", {
  b <- q(WFO.browse("Gambeya boiviniana", WFO.data = E))
  expect_equal(b$scientificName, "Gambeya boiviniana var. lavanchiana")
})

test_that("hybrids match exactly in both notations", {
  x <- c("Mentha x piperita", "Mentha \u00d7piperita", "Mentha \u00d7 piperita")
  r <- q(WFO.match(x, WFO.data = E, verbose = FALSE))
  expect_true(all(r$Matched) && !any(r$Fuzzy))
  expect_equal(unique(r$scientificName), "Mentha \u00d7 piperita")
  expect_equal(r$Hybrid, rep("\u00d7", 3))
  old <- E; old$scientificName <- gsub("\u00d7 ", "\u00d7", old$scientificName)   # WFO <= 2025 notation
  r <- q(WFO.match(x, WFO.data = old, verbose = FALSE))
  expect_true(all(r$Matched) && !any(r$Fuzzy))
  expect_equal(WFO.spelling.check(data.frame(spec.name = c("Mentha piperita", "Mentha \u00d7piperita"),
                                             scientificName = "Mentha \u00d7 piperita", New.accepted = FALSE, Old.name = "")),
               c("spelling corrected", "identical"))
})

test_that("edge cases: truncated genus, genus transfer, local name", {
  x <- c("Reinwardtiod cinerum", "Chrysophyllum madagascariensis", "Palma colorada")
  r <- q(WFO.match.ff(x, WFO.data = E, verbose = FALSE))
  expect_equal(r$scientificName, c("Reinwardtiodendron cinereum", "Gambeya boiviniana", NA))
  expect_equal(r$Fuzzy.genus, c(TRUE, FALSE, FALSE))
  expect_equal(r$Fuzzy.transfer, c(FALSE, TRUE, FALSE))
  expect_equal(r$Old.name[2], "Gambeya madagascariensis")
  expect_false(r$Matched[3])
})

test_that("with the new steps switched off, the genus fall-back of WorldFlora is used", {
  x <- c("Reinwardtiod cinerum", "Chrysophyllum madagascariensis", "Palma colorada")
  r <- q(WFO.match(x, WFO.data = E, verbose = FALSE))      # defaults: WorldFlora steps
  expect_false(any(c("Fuzzy.genus", "Fuzzy.transfer", "Fuzzy.alternatives") %in% names(r)))
  r1 <- q(WFO.one(r, verbose = FALSE))
  expect_equal(r1$scientificName, c("Reinwardtia", "Chrysophyllum", "Phoenix"))
  expect_true(all(r1$Fuzzy.one))
})

test_that("a genus transfer needs evidence; without it the accepted genus is the fall-back", {
  E2 <- E[E$scientificName != "Chrysophyllum boivinianum", ]
  r <- q(WFO.match.ff("Chrysophyllum madagascariensis", WFO.data = E2, verbose = FALSE))
  expect_false(r$Fuzzy.transfer)
  expect_equal(r$scientificName, "Chrysophyllum")
  expect_equal(r$taxonRank, "genus")
})

test_that("strict genus fall-back keeps accepted genera and refuses synonym genera", {
  r <- q(WFO.match.ff(c("Ceiba roja", "Gambeya unknownensis", "Palma sp1 colorada"), WFO.data = E, verbose = FALSE))
  expect_equal(r$scientificName[1:2], c("Ceiba", "Gambeya"))
  # "Palma sp1 colorada" contains a number: reduced to "Palma", an exact name (synonym of Phoenix)
  expect_equal(r$scientificName[3], "Phoenix")
})

test_that("homonyms are resolved by authors; NA authors give Inf, empty authors their length", {
  aa <- data.frame(spec.name = "Acacia albida", Authorship = c("Delile", "Lindl.", NA))
  m <- q(WFO.match(aa, WFO.data = E, verbose = FALSE))
  expect_true(all(is.infinite(m$Auth.dist[m$OriSeq == 3])))
  m0 <- q(WFO.match(data.frame(spec.name = "Acacia albida", Authorship = ""), WFO.data = E, verbose = FALSE))
  expect_equal(m0$Auth.dist, nchar(m0$scientificNameAuthorship))     # as in WorldFlora
  o <- q(WFO.one(m, Auth.dist = "Auth.dist", Old.author.dist = "Old.author.dist", verbose = FALSE))
  expect_equal(o$scientificName, c("Faidherbia albida", "Vachellia tortuosa", "Acacia albida"))
  expect_equal(o$scientificNameAuthorship[3], "Rojas Acosta")
})

test_that("candidates of unrelated genera are rejected, then genus-then-epithet finds the name", {
  B <- bb(c("Scabiosa", "Scabiosa paphlagonica", "Festuca", "Festuca paphlagonica"),
          c("Caprifoliaceae", "Caprifoliaceae", "Poaceae", "Poaceae"))
  r <- q(WFO.match.ff("Scab paphlagonica", WFO.data = B, verbose = FALSE))
  expect_true(r$Fuzzy.genus)
  expect_equal(r$scientificName, "Scabiosa paphlagonica")
  expect_match(r$Fuzzy.alternatives, "Festuca paphlagonica")
})


test_that("transfer: a distinctive epithet unique in the family is accepted (bancrofti = bancroftii)", {
  B <- bb(c("Endiandra", "Endiandra sieberi", "Beilschmiedia", "Beilschmiedia bancroftii", "Acacia bancrofti"),
          c("Lauraceae", "Lauraceae", "Lauraceae", "Lauraceae", "Fabaceae"))
  r <- q(WFO.match.ff("Endiandra bancroftii", WFO.data = B, verbose = FALSE))
  expect_true(r$Fuzzy.transfer)
  expect_equal(r$scientificName, "Beilschmiedia bancroftii")
})

test_that("transfer: several candidate species are not accepted but listed", {
  B <- bb(c("Pterocarpus", "Pterocarpus indicus", "Swartzia vaupesiana", "Tachigali vaupesiana"), "Fabaceae")
  r <- q(WFO.match.ff("Pterocarpus vaupesiana", WFO.data = B, verbose = FALSE))
  expect_false(r$Fuzzy.transfer)
  expect_equal(r$scientificName, "Pterocarpus")
  expect_equal(r$Fuzzy.alternatives, "Swartzia vaupesiana; Tachigali vaupesiana")
})

test_that("fuzzy matches only in another family are not accepted for an existing genus", {
  B <- bb(c("Sindora", "Sindora siamensis", "Lindera", "Lindera assamica"),
          c("Fabaceae", "Fabaceae", "Lauraceae", "Lauraceae"))
  r <- q(WFO.match.ff("Sindora assamica", WFO.data = B, verbose = FALSE))
  expect_equal(r$scientificName, "Sindora")
  expect_equal(r$Fuzzy.alternatives, "Lindera assamica")
  r0 <- q(WFO.match("Sindora assamica", WFO.data = B, Fuzzy.keep.genus = FALSE, Fuzzy.epithet.check = FALSE, verbose = FALSE))
  expect_equal(r0$scientificName, "Lindera assamica")       # WorldFlora behaviour
})

test_that("WFO.family warns for families outside vascular.families", {
  B <- data.frame(taxonID = c("1", "2"), scientificName = c("Sphagnum", "Sphagnum palustre"), scientificNameAuthorship = "",
                  taxonRank = c("genus", "species"), taxonomicStatus = "Accepted", acceptedNameUsageID = "",
                  family = "Sphagnaceae", majorGroup = "B", stringsAsFactors = FALSE)
  expect_warning(f <- suppressMessages(WFO.family("Sphagnum palustre", WFO.data = B, verbose = FALSE)), "majorGroup in the backbone: B")
  expect_equal(nrow(f), 0)
})

## ---- rules from the 70-name diagnosis (WorldFloraFast 0.12.0) ----

test_that("the family of a genus comes from its accepted genus record (no transfer to Rhamnaceae)", {
  B <- bb(c("Cassine", "Cassine peragua", "Cassine rhamnoides", "Ceanothus perplexans"),
          c("Celastraceae", "Celastraceae", "Rhamnaceae", "Rhamnaceae"))
  r <- q(WFO.match.ff("Cassine perplexans", WFO.data = B, verbose = FALSE))
  expect_false(r$Fuzzy.transfer)
  expect_equal(r$scientificName, "Cassine")
})

test_that("a transfer needs the accepted taxon in the family too", {
  B <- bb(c("Quercus", "Quercus robur", "Meliosma dives", "Meliosma idiopoda"),
          c("Fagaceae", "Fagaceae", "Fagaceae", "Sabiaceae"),
          status = c("Accepted", "Accepted", "Synonym", "Accepted"), accepted = c("", "", "id4", ""))
  r <- q(WFO.match.ff("Quercus dives", WFO.data = B, verbose = FALSE))
  expect_equal(r$scientificName, "Quercus")
})

test_that("epithet check: short epithets cannot be replaced; typos in endings are kept", {
  B <- bb(c("Ocotea", "Ocotea lucida", "Disa", "Disa equestris", "Quercus", "Quercus cornelius-mulleri"),
          c("Lauraceae", "Lauraceae", "Orchidaceae", "Orchidaceae", "Fagaceae", "Fagaceae"))
  r <- q(WFO.match.ff(c("Ocotea luis", "Disa equestrism", "Quercus cornelius"), WFO.data = B, verbose = FALSE))
  expect_equal(r$scientificName, c("Ocotea", "Disa equestris", "Quercus cornelius-mulleri"))
  expect_match(r$Fuzzy.alternatives[1], "Ocotea lucida")
  r0 <- q(WFO.match.ff("Ocotea luis", WFO.data = B, Fuzzy.epithet.check = FALSE, verbose = FALSE))
  expect_equal(r0$scientificName, "Ocotea lucida")       # WorldFlora behaviour
})

test_that("a one-letter change of an existing genus into another family is rejected", {
  B <- bb(c("Neea", "Neea floribunda", "Leea", "Leea gigantea"),
          c("Nyctaginaceae", "Nyctaginaceae", "Vitaceae", "Vitaceae"))
  r <- q(WFO.match.ff("Neea gigante", WFO.data = B, verbose = FALSE))
  expect_equal(r$scientificName, "Neea")
  expect_match(r$Fuzzy.alternatives, "^Leea gigantea")
})

test_that("genus then epithet follows synonym genera, but only as a fall-back", {
  B <- bb(c("Parinari", "Parinarium", "Parinari excelsa"), "Chrysobalanaceae",
          status = c("Accepted", "Synonym", "Accepted"), accepted = c("", "id1", ""))
  r <- q(WFO.match.ff("Parainarium excelsa", WFO.data = B, verbose = FALSE))
  expect_equal(r$scientificName, "Parinari excelsa")
  B2 <- bb(c("Triquetrella", "Triquetrella californica", "Triquetra", "Astragalus", "Astragalus californicus"),
           c("Pottiaceae", "Pottiaceae", "Fabaceae", "Fabaceae", "Fabaceae"),
           status = c("Accepted", "Accepted", "Synonym", "Accepted", "Accepted"), accepted = c("", "", "id4", "", ""))
  r <- q(WFO.match.ff("Triquetr californica", WFO.data = B2, verbose = FALSE))
  expect_equal(r$scientificName, "Triquetrella californica")
})

test_that("an unmatched name in a synonym genus lists the accepted genus", {
  B <- bb(c("Liquidambar", "Altingia", "Liquidambar formosana"), "Altingiaceae",
          status = c("Accepted", "Synonym", "Accepted"), accepted = c("", "id1", ""))
  r <- q(WFO.match.ff("Altingia fargesii", WFO.data = B, verbose = FALSE))
  expect_false(r$Matched)
  expect_equal(r$Fuzzy.alternatives, "Liquidambar (Altingia is a synonym)")
})

test_that("a correctly spelled genus is kept (Fuzzy.keep.genus, default)", {
  B <- bb(c("Trema", "Trema tomentosum", "Premna", "Premna tomentosa", "Ulmus", "Ulmus pumila", "Tamus parviflora"),
          c("Cannabaceae", "Cannabaceae", "Lamiaceae", "Lamiaceae", "Ulmaceae", "Ulmaceae", "Dioscoreaceae"))
  r <- q(WFO.match(c("Trema tomentosa", "Ulmus parviflora", "Tremma tomentosum"), WFO.data = B, verbose = FALSE))
  expect_equal(r$scientificName, c("Trema tomentosum", "Ulmus", "Trema tomentosum"))
  expect_equal(r$taxonRank[2], "genus")
  ## WorldFlora behaviour
  r0 <- q(WFO.match("Ulmus parviflora", WFO.data = B, Fuzzy.keep.genus = FALSE, Fuzzy.epithet.check = FALSE, verbose = FALSE))
  expect_equal(r0$scientificName, "Tamus parviflora")
  ## the candidates that were not kept are reported when the optional columns are used
  r1 <- q(WFO.match("Ulmus parviflora", WFO.data = B, Fuzzy.one.strict = TRUE, verbose = FALSE))
  expect_equal(r1$Fuzzy.alternatives, "Tamus parviflora")
})

## ---- 1.0.2: placeholders, epithet check by default, parallel processing ----

test_that("placeholders are not fuzzy-matched (Fuzzy.skip.placeholder, default)", {
  B <- bb(c("Opuntia", "Opuntia coindetti", "Acacia", "Acacia albida"), c("Cactaceae", "Cactaceae", "Fabaceae", "Fabaceae"))
  r <- q(WFO.match(c("indet.", "sp.", "Indet", "cf.", "Acacia sp."), WFO.data = B, verbose = FALSE))
  expect_equal(r$Matched, c(FALSE, FALSE, FALSE, FALSE, TRUE))
  expect_equal(r$scientificName[5], "Acacia")
  expect_equal(r$spec.name.ORIG[1], "indet.")
  r0 <- q(WFO.match("indet.", WFO.data = B, Fuzzy.skip.placeholder = FALSE, verbose = FALSE))
  expect_equal(r0$scientificName, "Opuntia coindetti")      # WorldFlora behaviour
  expect_equal(q(WFO.one(r, spec.name = "spec.name", verbose = FALSE))$scientificName[1], "indet.")
})

test_that("the epithet check is on by default and adds no columns", {
  B <- bb(c("Drypetes", "Drypetes kwangtungensis", "Ocotea", "Ocotea lucida"),
          c("Putranjivaceae", "Putranjivaceae", "Lauraceae", "Lauraceae"))
  r <- q(WFO.match(c("Drypetes likwa", "Ocotea luis", "Ocotea lucidda"), WFO.data = B, verbose = FALSE))
  expect_equal(r$scientificName, c("Drypetes", "Ocotea", "Ocotea lucida"))
  expect_false(any(c("Fuzzy.genus", "Fuzzy.transfer", "Fuzzy.alternatives") %in% names(r)))
  r0 <- q(WFO.match("Drypetes likwa", WFO.data = B, Fuzzy.epithet.check = FALSE, verbose = FALSE))
  expect_equal(r0$scientificName, "Drypetes kwangtungensis")   # WorldFlora behaviour
})

test_that("the epithet check accepts epithets run together with a rank", {
  B <- bb(c("Phragmites", "Phragmites australis", "Phragmites australis subsp. americanus",
            "Dichondra", "Dichondra repens", "Dichondra repens var. sericea"),
          c("Poaceae", "Poaceae", "Poaceae", "Convolvulaceae", "Convolvulaceae", "Convolvulaceae"))
  r <- q(WFO.match(c("Phragmites australissubsp. americanus", "Dichondramrepens var. sericea"), WFO.data = B, verbose = FALSE))
  expect_equal(r$scientificName, c("Phragmites australis subsp. americanus", "Dichondra repens var. sericea"))
})

test_that("results of failed parallel processes are computed again", {
  skip_on_os("windows")
  ns <- asNamespace("WorldFloraFast")
  parent <- Sys.getpid()
  f <- function(i) if (Sys.getpid() != parent && i %% 3 == 0) NULL else list(rows = i)   # workers 'lose' every third result
  expect_warning(r <- ns$.parallel.lapply(1:12, f, cores = 2), "matched again")
  expect_equal(vapply(r, `[[`, 0L, "rows"), 1:12)
})

test_that("WFO.one returns each submitted record once, in order", {
  r <- q(WFO.match(c("Acacia albida", "indet.", "", NA, "Acacia albida", "Gambeya boiviniana"), WFO.data = E, verbose = FALSE))
  o <- q(WFO.one(r, verbose = FALSE))
  expect_equal(o$OriSeq, 1:6)
})
