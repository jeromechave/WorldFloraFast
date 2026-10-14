test_that("pigeonhole prefilter returns exactly what agrep returns", {
  ns <- asNamespace("WorldFloraFast")
  set.seed(1)
  syl <- c(
    "ac", "ia", "fi", "cus", "bra", "chy", "ste", "gia", "nil", "oti", "ca",
    "al", "bi", "da", "ra", "\u00e9"
  )
  rnd <- function(n) {
    vapply(seq_len(n), function(i) {
      paste0(
        paste(sample(syl, sample(2:4, 1), TRUE), collapse = ""), " ",
        paste(sample(syl, sample(2:5, 1), TRUE), collapse = "")
      )
    }, "")
  }
  u <- unique(rnd(3000))
  for (p in c(sample(u, 60), rnd(30), substr(sample(u, 20), 1, 6))) {
    for (d in c(0.1, 0.2, 1, 2)) {
      expect_identical(ns$.agrep.ids(p, u, d), agrep(p, u, max.distance = d))
      expect_identical(
        ns$.agrep.ids(p, u, d, u.nchar = nchar(u)),
        agrep(p, u, max.distance = d)
      )
    }
  }
})

test_that(
  "WFO.one: one row per record; authorship index not recycled (bug 6)",
  {
    wd <- mini_backbone()
    r <- q(WFO.match(
      data.frame(spec.name = "Acacia nilotica", Authorship = "Auct."),
      WFO.data = wd, acceptedNameUsageID.match = FALSE, verbose = FALSE
    ))
    r$New.accepted <- FALSE
    o <- q(WFO.one(r, Auth.dist = "Auth.dist", verbose = FALSE))
    expect_equal(nrow(o), 1)
    expect_equal(o$scientificNameAuthorship, "Auct.")
    expect_equal(o$One.Reason, "Authorship best match")
    r <- q(WFO.match(
      c("Acacia nilotica", "Xx yy"),
      WFO.data = wd,
      verbose = FALSE
    ))
    o <- q(WFO.one(r, spec.name = "spec.name", verbose = FALSE))
    expect_equal(o$OriSeq, 1:2)
    expect_equal(o$scientificName[2], "Xx yy")
    expect_equal(o$One.Reason[2], "no match found")
  }
)

test_that("WFO.url accepts data.tables and vectors", {
  expect_equal(
    WFO.url(data.table::data.table(taxonID = c("wfo-1", ""))),
    c("http://worldfloraonline.org/taxon/wfo-1", NA)
  )
  expect_equal(WFO.url("wfo-2"), "http://worldfloraonline.org/taxon/wfo-2")
})

test_that("WFO.read reads everything as character and selects columns", {
  f <- tempfile(fileext = ".csv")
  data.table::fwrite(
    data.frame(taxonID = "wfo-1", scientificName = "NA", genus = "", x = 1),
    f,
    sep = "\t"
  )
  d <- WFO.read(f)
  expect_true(all(vapply(d, is.character, TRUE)))
  expect_equal(d$scientificName, "NA")
  expect_warning(d2 <- WFO.read(f, core.only = TRUE))
  expect_equal(names(d2), c("taxonID", "scientificName", "genus"))
  expect_equal(nrow(WFO.read(dirname(f) |> file.path(basename(f)))), 1)
})

test_that("WFO.match.fuzzyjoin (stringdist) matches and keeps closest", {
  skip_if_not_installed("stringdist")
  wd <- mini_backbone()
  expect_warning(r <- suppressMessages(WFO.match.fuzzyjoin(
    c("Coffea arabica", "Brachystegia spicformis", "Xx"),
    WFO.data = wd
  )), "deprecated")
  expect_equal(
    r$scientificName[1:2],
    c("Coffea arabica", "Brachystegia spiciformis")
  )
  expect_equal(r$Fuzzy.dist[2], 1)
  expect_false(r$Matched[3])
})

test_that("no.dates is deprecated but still accepted", {
  wd <- mini_backbone()
  expect_warning(
    r <- suppressMessages(WFO.match(
      "Coffea arabica",
      WFO.data = wd,
      no.dates = FALSE,
      verbose = FALSE
    )),
    "no.dates"
  )
  expect_equal(r$scientificName, "Coffea arabica")
  expect_silent(suppressMessages(WFO.match(
    "Coffea arabica",
    WFO.data = wd,
    verbose = FALSE
  )))
})
