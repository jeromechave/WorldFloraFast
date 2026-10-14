wd <- mini_backbone()

test_that("WFO.prepare splits names, ranks and authors", {
  x <- c(
    "Acacia nilotica subsp. tomentosa (Benth.) Brenan", "Ficus sycomorus L.",
    "Prunus africana (Hook. f.) Kalkman", "Coffea sp. 3", "Aa ab L."
  )
  r <- q(WFO.prepare(x, verbose = FALSE))
  expect_equal(r$spec.name, c(
    "Acacia nilotica subsp. tomentosa", "Ficus sycomorus", "Prunus africana",
    "Coffea", "Aa ab"
  ))
  expect_equal(
    r$Authorship,
    c("(Benth.) Brenan", "L.", "(Hook. f.) Kalkman", "", "L.")
  )
  expect_equal(r$genus.2, c("", "", "", "", "Aa"))
  expect_equal(r$spec.full, x)
})

test_that(
  "WFO.prepare: empty/missing names, other columns, data.tables (fixes)",
  {
    r <- q(WFO.prepare(c("Ficus sycomorus L.", "", NA), verbose = FALSE))
    expect_equal(r$spec.name, c("Ficus sycomorus", "", ""))
    d <- data.table::data.table(
      full = c("Ficus sycomorus L.", "Coffea arabica L."),
      id = 1:2
    )
    r <- q(WFO.prepare(d, spec.full = "full", verbose = FALSE))
    expect_equal(r$spec.name, c("Ficus sycomorus", "Coffea arabica"))
    expect_equal(r$id, 1:2)
  }
)

test_that("WFO.preprepare handles names without the first rank (fix)", {
  r <- WFO.preprepare(c(
    "Acacia nilotica subsp. kraussiana var. major L.", "Ficus sycomorus L.",
    "Ficus var. alba Sm."
  ))
  expect_equal(r$first, c(TRUE, FALSE, FALSE))
  expect_equal(r$only.second, c(FALSE, FALSE, TRUE))
  expect_equal(r$also.second, c(TRUE, FALSE, FALSE))
  expect_equal(r$second.split.after[1], "var. major L.")
})

test_that("WFO.browse, WFO.synonyms and WFO.family", {
  b <- q(WFO.browse("Acacia", WFO.data = wd))
  expect_equal(
    b$scientificName,
    c("Acacia albida", "Acacia nilotica", "Acacia nilotica")
  )
  expect_equal(
    b$New.name,
    c("Faidherbia albida", "Vachellia nilotica", "Vachellia nilotica")
  )
  s <- q(WFO.synonyms("Faidherbia albida", WFO.data = wd))
  expect_equal(s$scientificName, c("Faidherbia albida", "Acacia albida"))
  f <- q(WFO.family("Coffea arabica", WFO.data = wd))
  expect_equal(f$Order, "Gentianales")
  wd2 <- data.table::copy(wd)
  wd2$family[13] <- "Notafamilyaceae"
  expect_warning(
    q2 <- suppressMessages(WFO.family("Coffea arabica", WFO.data = wd2)),
    "not in vascular.families"
  )
})

test_that(
  "WFO.backbone: self-references accepted; missing IDs empty (fixes)",
  {
    x <- data.frame(
      id = c(
        "A1",
        "A2",
        "A3"
      ), name = c("Felis catus", "Felis domesticus", "Panthera leo"),
      author = c(
        "L.",
        "E.",
        "(L.)"
      ), accepted = c("", "A1", "A3"), habitat = "x"
    )
    bk <- suppressMessages(WFO.backbone(x,
      taxonID = "id", scientificName = "name",
      scientificNameAuthorship = "author", acceptedNameUsageID = "accepted"
    ))
    expect_equal(bk$taxonomicStatus, c("Accepted", "Synonym", "Accepted"))
    expect_equal(bk$acceptedNameUsageID, c("", "A1", ""))
    expect_equal(bk$habitat, rep("x", 3))
    x$accepted[2] <- NA
    bk <- WFO.backbone(x[1:2, ],
      taxonID = "id", scientificName = "name",
      scientificNameAuthorship = "author", acceptedNameUsageID = "accepted"
    )
    expect_equal(bk$taxonomicStatus, c("Accepted", "Accepted"))
    r <- q(WFO.match("Felis domestica", WFO.data = WFO.backbone(data.frame(
      taxonID = c("1", "2"),
      scientificName = c(
        "Felis catus",
        "Felis domesticus"
      ), scientificNameAuthorship = "",
      accepted = c("", "1")
    ), acceptedNameUsageID = "accepted"), verbose = FALSE))
    expect_equal(r$scientificName, "Felis catus")
  }
)

test_that(
  "WFO.spelling.check classifies; WFO.acceptable.match is deprecated",
  {
    x <- data.frame(
      spec.name = c(
        "Ficus scott-elliottii", "Acacia nilotica", "Coffea arabicus",
        "Syzygium naiadum",
        "Faidherbia albida", "Xx yy"
      ),
      scientificName = c(
        "Ficus scott-elliotii", "Acacia senegal", "Coffea arabica",
        "Syzygium najadum",
        "Faidherbia albida", NA
      ),
      New.accepted = FALSE, Old.name = ""
    )
    expect_equal(WFO.spelling.check(x), c(
      "spelling corrected", "other difference", "spelling corrected",
      "spelling corrected", "identical", NA
    ))
    expect_warning(old <- WFO.acceptable.match(x), "deprecated")
    expect_equal(old, c(TRUE, FALSE, TRUE, TRUE, TRUE, NA))
  }
)

test_that("WFO.spelling.check compares replaced synonyms with the synonym", {
  x <- data.frame(
    spec.name = "Acacia albidum", scientificName = "Faidherbia albida",
    New.accepted = TRUE, Old.name = "Acacia albida"
  )
  expect_equal(WFO.spelling.check(x), "spelling corrected")
})

test_that("new.backbone() is an exact alias; script names are deprecated", {
  x <- data.frame(
    id = c("A1", "A2"), name = c("Felis catus", "Felis domesticus"),
    author = c("L.", "E."), accepted = c("", "A1")
  )
  a <- WFO.backbone(x,
    taxonID = "id", scientificName = "name",
    scientificNameAuthorship = "author", acceptedNameUsageID = "accepted"
  )
  b <- new.backbone(x,
    taxonID = "id", scientificName = "name",
    scientificNameAuthorship = "author", acceptedNameUsageID = "accepted"
  )
  expect_identical(a, b)
  expect_identical(names(formals(new.backbone)), names(formals(WFO.backbone)))
  f <- tempfile(fileext = ".csv")
  data.table::fwrite(data.frame(taxonID = "wfo-1", scientificName = "Ficus"), f)
  expect_warning(r <- read_classification(f), "deprecated")
  expect_equal(r$scientificName, "Ficus")
})
