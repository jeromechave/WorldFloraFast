# Per-user data folder (1.0.5). R's per-user folders are redirected to a
# temporary directory, so that the tests never touch the user's own backbone.
local_user_dirs <- function(env = parent.frame()) {
  root <- withr::local_tempdir("wff_user_", .local_envir = env)
  withr::local_envvar(
    c(
      R_USER_DATA_DIR = file.path(root, "data"),
      R_USER_CONFIG_DIR = file.path(root, "config"),
      ZENODO_BASE = "http://invalid.invalid"
    ),
    .local_envir = env
  )
  invisible(root)
}

make_release <- function(version, record) {
  ns <- asNamespace("WorldFloraFast")
  d <- file.path(ns$.wfo.data.dir(), version)
  dir.create(d, recursive = TRUE)
  data.table::fwrite(
    data.frame(taxonID = "wfo-1", scientificName = paste("release", version)),
    file.path(d, "classification.csv"),
    sep = "\t"
  )
  jsonlite::write_json(
    list(
      record_id = record, version = version, doi = paste0("10.1/", record),
      downloaded = "2026-01-01"
    ),
    file.path(d, "classification_source.json"),
    auto_unbox = TRUE
  )
  file.path(d, "classification.csv")
}

test_that("the data folder is in the per-user data folder", {
  local_user_dirs()
  ns <- asNamespace("WorldFloraFast")
  expect_true(startsWith(ns$.wfo.data.dir(), Sys.getenv("R_USER_DATA_DIR")))
  expect_equal(ns$.release.folder("2026-06", "1"), "2026-06")
  expect_equal(ns$.release.folder(NA, "123"), "record_123")
  expect_equal(ns$.release.folder("2026/06 beta", "1"), "2026_06_beta")
})

test_that("no release: empty list, and a clear error when reading", {
  local_user_dirs()
  r <- suppressMessages(WFO.releases())
  expect_equal(nrow(r), 0)
  expect_error(suppressMessages(WFO.read()), "WFO.download")
})

test_that("releases are listed newest first; the newest is used", {
  local_user_dirs()
  make_release("2025-12", "100")
  f26 <- make_release("2026-06", "200")
  r <- suppressMessages(WFO.releases())
  expect_equal(r$release, c("2026-06", "2025-12"))
  expect_equal(r$in.use, c(TRUE, FALSE))
  expect_equal(r$record.id, c("200", "100"))
  expect_message(d <- WFO.read(), "newest release")
  expect_equal(d$scientificName, "release 2026-06")
})

test_that("the remembered file is used first; if deleted, the newest", {
  local_user_dirs()
  f25 <- make_release("2025-12", "100")
  make_release("2026-06", "200")
  suppressMessages(
    WFO.remember(WFO.file = f25, WFO.data = "x", WFO.pos = new.env())
  )
  expect_message(d <- WFO.read(), "remembered")
  expect_equal(d$scientificName, "release 2025-12")
  suppressMessages(WFO.releases(remove = "2025-12"))
  expect_false(file.exists(f25))
  expect_message(d <- WFO.read(), "newest release")
  expect_equal(d$scientificName, "release 2026-06")
  expect_error(
    suppressMessages(WFO.releases(remove = "1999-01")),
    "No release"
  )
})

test_that("WFO.download() uses an existing release without Zenodo", {
  local_user_dirs()
  make_release("2026-06", "200")
  p <- suppressMessages(WFO.download(WFO.remember = FALSE))
  expect_equal(basename(dirname(p)), "2026-06")
  expect_equal(attr(p, "version"), "2026-06")
  expect_equal(attr(p, "record_id"), "200")
})
