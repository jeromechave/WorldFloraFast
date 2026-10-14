wd <- mini_backbone()

test_that("exact, synonym and accepted-name replacement", {
  r <- q(WFO.match("Acacia albida", WFO.data = wd, verbose = FALSE))
  expect_equal(nrow(r), 1)
  expect_true(r$New.accepted)
  expect_equal(r$scientificName, "Faidherbia albida")
  expect_equal(r$Old.name, "Acacia albida")
  expect_equal(r$Old.ID, "wfo-0000000002")
})

test_that("exact homonyms are flagged as not unique (fix)", {
  r <- q(WFO.match("Acacia nilotica", WFO.data = wd, verbose = FALSE))
  expect_equal(nrow(r), 2)
  expect_equal(r$Subseq, 1:2)
  expect_false(any(r$Unique))
})

test_that("conserved family names are matched and kept (bug 10)", {
  r <- q(WFO.match(
    c("Coffea arabica", "Compositae", "Gramineae", "Ficus sycomorus"),
    WFO.data = wd, verbose = FALSE
  ))
  expect_equal(r$OriSeq, 1:4)
  expect_equal(
    r$scientificName,
    c("Coffea arabica", "Asteraceae", "Poaceae", "Ficus sycomorus")
  )
})

test_that("an unmatched name never inherits the previous match (bug 2)", {
  r <- q(WFO.match(
    c("Brachystegia spiciformiz", "Xx yy", "Qwertyuiop asdfghjkl"),
    WFO.data = wd, Fuzzy.one = FALSE, verbose = FALSE
  ))
  expect_true(r$Matched[1])
  expect_false(any(r$Matched[2:3]))
  expect_true(all(r$taxonID[2:3] == ""))
  # first record unmatched used to be an error
  r <- q(WFO.match("Xx yy", WFO.data = wd, verbose = FALSE))
  expect_false(r$Matched)
})

test_that("fuzzy matching, genus fall-back and Fuzzy.dist", {
  r <- q(WFO.match("Brachystegia spicformis", WFO.data = wd, verbose = FALSE))
  expect_true(r$Fuzzy)
  expect_equal(r$scientificName, "Brachystegia spiciformis")
  expect_equal(r$Fuzzy.dist, 1)
  r <- q(WFO.match("Coffea unknownensis", WFO.data = wd, verbose = FALSE))
  expect_true(r$Fuzzy.one)
  expect_equal(r$scientificName, "Coffea")
})

test_that(
  "Fuzzy.force works (bug 1) and Fuzzy.within does not explode (bug 9)",
  {
    r <- q(WFO.match(
      "Coffea arabica",
      WFO.data = wd,
      Fuzzy.force = TRUE,
      verbose = FALSE
    ))
    expect_true(r$Matched[1])
    expect_true("Coffea arabica" %in% r$scientificName)
    r <- q(WFO.match(
      "Brachystegia spicformis",
      WFO.data = wd,
      Fuzzy.within = TRUE,
      verbose = FALSE
    ))
    expect_equal(nrow(r), 1)
    expect_false(r$Matched)
  }
)

test_that(
  "name cleaning: squish, brackets, numbers, sp., hybrids, tolower (bug 4)",
  {
    r <- q(WFO.match(
      c(
        "  Coffea   arabica ",
        "Coffea arabica (coffee)",
        "Ficus sp. 3",
        "Eucalyptus x hybrida"
      ),
      WFO.data = wd, verbose = FALSE
    ))
    expect_equal(
      r$spec.name,
      c("Coffea arabica", "Coffea arabica", "Ficus", "Eucalyptus \u00d7hybrida")
    )
    expect_equal(r$Squished, c(TRUE, FALSE, FALSE, FALSE))
    expect_equal(r$Hybrid, c("", "", "", "\u00d7"))
    r <- q(WFO.match(
      "COFFEA   ARABICA",
      WFO.data = wd,
      spec.name.tolower = TRUE,
      verbose = FALSE
    ))
    expect_equal(r$spec.name, "Coffea arabica")
  }
)

test_that(
  "matching via Genus/Species columns; missing Infraspecific (bug 3)",
  {
    d <- data.frame(
      Genus = c("Acacia", "Ficus"), Species = c("nilotica", "sycomorus"),
      Infraspecific.rank = c("subsp.", NA), Infraspecific = c("tomentosa", NA)
    )
    r <- q(WFO.match(d, WFO.data = wd, verbose = FALSE))
    expect_equal(
      r$scientificName,
      c("Acacia nilotica subsp. tomentosa", "Ficus sycomorus")
    )
  }
)

test_that(
  "accepted-name columns are replaced by name, not by position (bug 7)",
  {
    wd2 <- wd[,
      c(rev(names(wd))),
      with = FALSE
    ] # taxonID no longer the first column
    r <- q(WFO.match("Acacia albida", WFO.data = wd2, verbose = FALSE))
    expect_equal(r$scientificName, "Faidherbia albida")
    expect_equal(r$taxonID, "wfo-0000000001")
    expect_equal(r$family, "Fabaceae")
  }
)

test_that("authorship distances; invalid strings give Inf", {
  d <- data.frame(
    spec.name = c("Acacia nilotica", "Ficus sycomorus"),
    Authorship = c("Auct.", "L.")
  )
  r <- q(WFO.match(d, WFO.data = wd, verbose = FALSE))
  expected <- mapply(
    function(a, b) as.numeric(utils::adist(a, b)),
    r$Authorship,
    r$scientificNameAuthorship
  )
  expect_equal(r$Auth.dist, unname(expected))
  expect_equal(r$Auth.dist[3], 0)
  expect_equal(
    r$Old.author.dist[1:2],
    as.character(c(utils::adist("Auct.", "(L.) Willd. ex Delile"), 0))
  )
  expect_true(is.character(r$Old.author.dist)) # as in WorldFlora
})

test_that("input formats: vector, factor, data.table", {
  a <- q(WFO.match("Coffea arabica", WFO.data = wd, verbose = FALSE))
  b <- q(WFO.match(factor("Coffea arabica"), WFO.data = wd, verbose = FALSE))
  c <- q(WFO.match(
    data.table::data.table(spec.name = "Coffea arabica"),
    WFO.data = wd,
    verbose = FALSE
  ))
  expect_equal(a$taxonID, b$taxonID)
  expect_equal(a$taxonID, c$taxonID)
})
