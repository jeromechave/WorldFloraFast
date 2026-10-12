## Offline tests of the download helpers (no network access).
ns <- asNamespace("WorldFloraFast")

test_that("Zenodo file listings are read in both JSON layouts", {
  legacy <- list(id = 1e8, files = list(list(key = "classification.csv", size = 10, checksum = "md5:abc")))
  rdm <- list(id = "5", files = list(entries = list(a = list(key = "_uber.zip", size = 3, checksum = "md5:def"))))
  expect_equal(ns$.extract.files(legacy)[[1]]$checksum, "abc")
  expect_equal(ns$.extract.files(rdm)[[1]]$key, "_uber.zip")
  expect_equal(ns$.record.id.chr(legacy), "100000000")
})

test_that("checksums, zip members and atomic installation", {
  d <- tempfile(); dir.create(d)
  f <- file.path(d, "classification.csv"); writeLines("taxonID\tscientificName\nwfo-1\tFicus", f)
  expect_true(suppressMessages(ns$.verify.md5(f, unname(tools::md5sum(f)))))
  g <- file.path(d, "copy.csv"); file.copy(f, g)
  expect_error(suppressMessages(ns$.verify.md5(g, "00")), "Checksum mismatch")
  expect_false(file.exists(g))
  z <- file.path(d, "x.zip")
  old <- setwd(d); utils::zip(z, "classification.csv", flags = "-q"); setwd(old)
  expect_equal(ns$.find.in.zip(z, "classification.csv"), "classification.csv")
  expect_true(is.na(ns$.find.in.zip(z, "other.csv")))
  dest <- file.path(d, "final.csv")
  ns$.install.file(f, dest)
  expect_true(file.exists(dest)); expect_false(file.exists(paste0(dest, ".part")))
})

test_that("an existing copy is used without contacting Zenodo", {
  d <- tempfile(); dir.create(d)
  writeLines("taxonID\tscientificName\nwfo-1\tFicus", file.path(d, "classification.csv"))
  jsonlite::write_json(list(record_id = "7", version = "2026-01", doi = "10.1/x"),
                       file.path(d, "classification_source.json"), auto_unbox = TRUE)
  withr_env <- Sys.getenv("ZENODO_BASE"); Sys.setenv(ZENODO_BASE = "http://invalid.invalid")
  on.exit(Sys.setenv(ZENODO_BASE = withr_env))
  p <- suppressMessages(WFO.download(save.dir = d, WFO.remember = FALSE))
  expect_equal(attr(p, "version"), "2026-01")
  expect_equal(attr(p, "record_id"), "7")
})
