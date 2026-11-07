source("../../R/quality_checks.R")

testthat::test_that("anomalies detectees", {
  jeu <- data.frame(
    effectif = c(10, -2, NA_real_, 0, 2.5, 4),
    effectif_totassur = c(8, -2, NA_real_, 0, 2, 7)
  )
  
  resultat <- auditer_effectifs(jeu)
  attendu <- c(1, 1, 1, 1, 1, 1, 0, 1, 1)
  
  testthat::expect_equal(
    as.numeric(resultat$anomalies), attendu
  )
}) 

testthat::test_that("colonne obligatoire absente", {
  jeu <- data.frame(
    effectif = c(10, 20, 30)
  )

  testthat::expect_error(
    auditer_effectifs(jeu),
    "Colonnes obligatoires manquantes"
  )
}) 

testthat::test_that("effectifs valides", {
  jeu <- data.frame(
    effectif = c(10, 20, 30),
    effectif_totassur = c(8, 20, 15)
  )

  resultat <- auditer_effectifs(jeu)

  testthat::expect_true(
    all(resultat$anomalies == 0)
  )
}) 

testthat::test_that("journal des effectifs negatifs", {
  jeu <- data.frame(
    effectif = c(10, -2, 5),
    effectif_totassur = c(8, -2, 4)
  )

  journal <- journaliser_effectifs(jeu)

  testthat::expect_equal(nrow(journal), 2L)

  testthat::expect_true(
    all(journal$ligne == 2L)
  )

  testthat::expect_setequal(
    journal$variable,
    c("effectif", "effectif_totassur")
  )
})