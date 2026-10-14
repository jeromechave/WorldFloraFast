# ----------------------------------------------------------------------------
# zzz.R: start-up message
#
# Provenance, relative to WorldFlora 1.14-5 (R. Kindt, GPL-3):
#   Inherited:
#     - .onAttach() with a start-up message.
#   Changed:
#     - The message text.
#   New in WorldFloraFast:
#     - none
#   ("NEWS n" refers to the numbered corrections of version 0.9.0 in NEWS.md.)
# ----------------------------------------------------------------------------

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "WorldFloraFast ", utils::packageVersion("WorldFloraFast"),
    ": WFO.download() obtains the World Flora Online backbone; ",
    "WFO.match() matches names.\n",
    "Derived from WorldFlora (Kindt 2020); see citation(\"WorldFloraFast\")."
  )
}
