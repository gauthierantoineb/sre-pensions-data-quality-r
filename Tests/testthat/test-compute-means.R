source("../../R/compute_means.R")

testthat::test_that("calcul des moyennes ponderees", {

  jeu <- data.frame(
    annee = c("2025", "2025"),
    categorie_civile = c("A", "B"),
    motif_depart = c("VAS", "VAS"),
    sexe = c("F", "F"),
    effectif = c(2, 8),
    age = c(120, 520),
    montant_pension = c(4000, 24000)
  )

  resultat <- calculer_moyennes_annuelles(jeu)

  testthat::expect_equal(
    resultat$nouvelles_pensions, 10
  )

  testthat::expect_equal(
    resultat$age_moyen_ans, 64
  )

  testthat::expect_equal(
    resultat$pension_moyenne_euros, 2800
  )
})

testthat::test_that("denominateur nul refuse", {

  jeu <- data.frame(
    annee = c("2025", "2025"),
    categorie_civile = c("A", "B"),
    motif_depart = c("VAS", "VAS"),
    sexe = c("F", "F"),
    effectif = c(0, 0),
    age = c(0, 0),
    montant_pension = c(0, 0)
  )

  testthat::expect_error(
    calculer_moyennes_annuelles(jeu),
    "Denominateur annuel nul"
  )
})

testthat::test_that("schema incomplet refuse", {

  jeu <- data.frame(
    annee = "2025",
    effectif = 10
  )

  testthat::expect_error(
    calculer_moyennes_annuelles(jeu),
    "Schema incomplet"
  )
})