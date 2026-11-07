# Tests synthetiques : aucune donnee officielle n'est modifiee ou simulee pour le rapport.
source("R/validate_schema.R")
source("R/import_data.R")
expected <- c("annee", "categorie_civile", "motif_depart", "sexe",
              "effectif", "age", "montant_pension", "duree_services_retenus",
              "duree_bonifications_retenues", "duree_totassur", "effectif_totassur")

testthat::test_that("fichier absent refuse", {
  testthat::expect_error(assert_nonempty_file(tempfile(fileext = ".csv")), "absent")
})

testthat::test_that("schema complet accepte, colonne absente refusee", {
  testthat::expect_true(validate_schema(as.data.frame(setNames(rep(list(1), length(expected)), expected)), expected))
  frame <- as.data.frame(setNames(rep(list(1), length(expected) - 1L), expected[-1L]))
  testthat::expect_error(validate_schema(frame, expected), "Colonnes manquantes")
})

testthat::test_that("colonne inattendue et nom duplique refuses", {
  frame <- as.data.frame(setNames(rep(list(1), length(expected)), expected))
  frame$intrus <- 1
  testthat::expect_error(validate_schema(frame, expected), "inattendues")
  names(frame)[2] <- names(frame)[1]
  testthat::expect_error(validate_schema(frame, expected), "dupliques")
})

testthat::test_that("marqueur S distingue de la non-applicabilite point", {
  values <- as.list(rep("0", length(expected)))
  names(values) <- expected
  values$annee <- "2025"
  values$categorie_civile <- "A"
  values$motif_depart <- "VAS"
  values$sexe <- "F"
  values$effectif <- "1"
  values$age <- "S"
  values$montant_pension <- "."
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.table(as.data.frame(values), tmp, sep = ";", quote = FALSE,
                     row.names = FALSE, na = "")
  result <- read_cube_csv(tmp, expected)
  testthat::expect_true(is.na(result$data$age[1]))
  testthat::expect_true(is.na(result$data$montant_pension[1]))
  testthat::expect_setequal(result$missing_markers$marqueur, c("S", "."))
})
