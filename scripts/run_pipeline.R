
# ==================================================
# SRE DATA QUALITY & STATISTICAL REPORTING
# Fichier : scripts/run_pipeline.R
# Objet : Execution automatique du pipeline
# Projet personnel non officiel
# ==================================================

executer_pipeline <- function() {

  debut <- Sys.time()
  statut <- "ECHEC"
  nom_source <- NA_character_

  # 1. Verifier le projet

  if (!file.exists("config/data_sources.yml")) {
    stop("Lancer le pipeline depuis la racine du projet")
  }

  dossiers <- c(
    "data/processed",
    "outputs/tables",
    "outputs/figures",
    "outputs/quality"
  )

  for (d in dossiers) {
    dir.create(
      d,
      recursive = TRUE,
      showWarnings = FALSE
    )
  }

  # Journal d'execution, meme en cas d'echec

  on.exit({

    write.csv(
      data.frame(
        date_utc = format(
          Sys.time(),
          "%Y-%m-%dT%H:%M:%SZ",
          tz = "UTC"
        ),
        statut = statut,
        fichier_brut = nom_source
      ),
      "outputs/quality/statut_pipeline.csv",
      row.names = FALSE
    )

  }, add = TRUE)

  cat("\n=== PIPELINE SRE ===\n")

  # 2. Verifier les dependances

  packages <- c(
    "yaml",
    "readr",
    "ggplot2",
    "testthat",
    "knitr",
    "rmarkdown"
  )

  absents <- packages[
    !vapply(
      packages,
      requireNamespace,
      logical(1),
      quietly = TRUE
    )
  ]

  if (length(absents) > 0) {
    stop(paste(
      "Packages absents :",
      paste(absents, collapse = ", ")
    ))
  }

  if (!nzchar(Sys.which("quarto"))) {
    stop("Quarto est introuvable")
  }

  cat("Dependances disponibles\n")

  # 3. Charger les scripts R

  script_graphiques <- if (
    file.exists("R/create_distribution_charts.R")
  ) {
    "R/create_distribution_charts.R"
  } else {
    "R/create_distribution_charte.R"
  }

  scripts_r <- c(
    "R/validate_schema.R",
    "R/import_data.R",
    "R/quality_checks.R",
    "R/compute_indicators.R",
    "R/compute_distributions.R",
    "R/compute_means.R",
    "R/create_charts.R",
    script_graphiques,
    "R/create_means_charts.R"
  )

  for (f in scripts_r) {

    if (!file.exists(f)) {
      stop(paste("Script introuvable :", f))
    }

    source(f)
  }

  cat("Scripts charges\n")

  # 4. Selectionner le CSV brut

  fichier <- Sys.getenv(
    "SRE_CUBE_FILE",
    unset = ""
  )

  if (!nzchar(fichier)) {

    candidats <- list.files(
      "data/raw",
      pattern = paste0(
        "^cube_flux_civil_droit_direct_1_",
        ".*\\.csv$"
      ),
      full.names = TRUE
    )

    if (length(candidats) != 1L) {
      stop(paste(
        "Il faut exactement un CSV source.",
        "Si plusieurs fichiers existent,",
        "definir SRE_CUBE_FILE."
      ))
    }

    fichier <- candidats[1]
  }

  if (!file.exists(fichier) ||
      file.info(fichier)$size == 0) {
    stop("CSV brut absent ou vide")
  }

  nom_source <- basename(fichier)

  cat("Source :", fichier, "\n")

  # 5. Importer les donnees

  cfg <- yaml::read_yaml(
    "config/data_sources.yml"
  )

  if (!all(c(
    "expected_columns",
    "csv_delimiter",
    "decimal_mark"
  ) %in% names(cfg))) {
    stop("Configuration des donnees incomplete")
  }

  import <- read_cube_csv(
    fichier,
    cfg$expected_columns,
    cfg$csv_delimiter,
    cfg$decimal_mark
  )

  cube <- import$data

  if (!is.data.frame(cube) ||
      nrow(cube) == 0) {
    stop("Importation invalide")
  }

  cat(
    "Importation :",
    nrow(cube), "lignes,",
    ncol(cube), "variables\n"
  )

  # 6. Enregistrer la provenance

  provenance <- data.frame(
    source = paste0(
      "https://data.economie.gouv.fr/",
      "explore/dataset/",
      "cube-flux-civil-droit-direct-1/"
    ),
    fichier_brut = nom_source,
    empreinte_md5 = unname(
      tools::md5sum(fichier)
    ),
    date_traitement = format(
      Sys.time(),
      "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    ),
    lignes = nrow(cube),
    variables = ncol(cube)
  )

  write.csv(
    provenance,
    "outputs/quality/provenance.csv",
    row.names = FALSE
  )

  # 7. Controler les effectifs

  audit <- auditer_effectifs(cube)
  journal <- journaliser_effectifs(cube)

  write.csv(
    audit,
    "outputs/quality/audit_effectifs.csv",
    row.names = FALSE
  )

  write.csv(
    journal,
    "outputs/quality/journal_anomalies.csv",
    row.names = FALSE
  )

  if (anyNA(audit$anomalies)) {
    stop("Resultats de controle invalides")
  }

  if (any(journal$gravite == "bloquante")) {
    stop("Anomalies bloquantes detectees")
  }

  cat(
    "Audit des effectifs :",
    nrow(journal),
    "signalements\n"
  )

  # Copie R importee et controlee sur ce perimetre

  saveRDS(
    cube,
    "data/processed/cube_importe_controle.rds"
  )

  # 8. Executer les tests automatises connus

  fichiers_tests <- c(
    "tests/testthat/test-quality-checks.R",
    "tests/testthat/test-compute-means.R"
  )

  for (f in fichiers_tests) {

    if (!file.exists(f)) {
      stop(paste("Test manquant :", f))
    }

    testthat::test_file(
      f,
      reporter = "summary",
      stop_on_failure = TRUE,
      stop_on_warning = TRUE
    )
  }

  cat("Tests automatises executes sans echec\n")

  # 9. Calculer les indicateurs

  flux <- calculer_flux_annuel(cube)

  repartitions <- calculer_repartitions(cube)

  moyennes <- calculer_moyennes_annuelles(cube)

  # Reconciliation avec les effectifs sources

  if (sum(flux$nouvelles_pensions) !=
      sum(cube$effectif)) {
    stop("Echec de reconciliation du flux")
  }

  ref_moyennes <- flux$nouvelles_pensions[
    match(moyennes$annee, flux$annee)
  ]

  if (anyNA(ref_moyennes) ||
      !setequal(flux$annee, moyennes$annee) ||
      any(ref_moyennes !=
          moyennes$nouvelles_pensions)) {
    stop("Echec de reconciliation des moyennes")
  }

  for (tab in repartitions) {

    total <- aggregate(
      effectif ~ annee,
      data = tab,
      FUN = sum
    )

    ref <- flux$nouvelles_pensions[
      match(total$annee, flux$annee)
    ]

    if (anyNA(ref) ||
        !setequal(total$annee, flux$annee) ||
        any(total$effectif != ref)) {
      stop("Echec de reconciliation des repartitions")
    }
  }

  cat("Indicateurs calcules et reconcilies\n")

  # 10. Exporter les tableaux

  write.csv(
    flux,
    "outputs/tables/flux_annuel.csv",
    row.names = FALSE
  )

  write.csv(
    moyennes,
    "outputs/tables/moyennes_annuelles.csv",
    row.names = FALSE
  )

  noms <- c(
    categories = "repartition_categories.csv",
    sexes = "repartition_sexes.csv",
    motifs = "repartition_motifs.csv"
  )

  for (nom in names(noms)) {

    write.csv(
      repartitions[[nom]],
      file.path("outputs/tables", noms[[nom]]),
      row.names = FALSE
    )
  }

  # 11. Creer les graphiques

  creer_graphique_flux()

  creer_graphiques_repartition()

  creer_graphiques_moyennes()

  figures <- file.path(
    "outputs/figures",
    c(
      "flux_annuel.png",
      "repartition_categories.png",
      "repartition_sexes.png",
      "repartition_motifs.png",
      "age_moyen_annuel.png",
      "pension_moyenne_annuelle.png"
    )
  )

  for (f in figures) {

    if (!file.exists(f) ||
        file.info(f)$size == 0) {
      stop(paste("Graphique manquant :", f))
    }
  }

  cat("Six graphiques disponibles\n")

  # 12. Generer le rapport Quarto

  rapport <- "reports/analyse_pensions.qmd"

  if (!file.exists(rapport) ||
      length(readLines(
        rapport,
        warn = FALSE
      )) < 20) {
    stop("Fichier Quarto absent ou incomplet")
  }

  sortie_quarto <- suppressWarnings(
    system2(
      "quarto",
      c(
        "render",
        rapport,
        "--to",
        "html"
      ),
      stdout = TRUE,
      stderr = TRUE
    )
  )

  cat(
    paste(sortie_quarto, collapse = "\n"),
    "\n"
  )

  code_retour <- attr(sortie_quarto, "status")

  if (is.null(code_retour)) {
    code_retour <- 0L
  }

  html <- "reports/analyse_pensions.html"

  if (code_retour != 0L ||
      !file.exists(html)) {
    stop("Echec de generation du rapport")
  }

  contenu <- readLines(
    html,
    warn = FALSE,
    encoding = "UTF-8"
  )

  if (!any(grepl(
    "Synthèse exécutive",
    contenu,
    fixed = TRUE
  ))) {
    stop("Rapport HTML incomplet")
  }

  # 13. Fin du pipeline

  statut <- "SUCCES"

  cat("\n=== PIPELINE TERMINE ===\n")
  cat("Statut :", statut, "\n")
  cat("Rapport :", html, "\n")
  cat(
    "Duree :",
    round(
      as.numeric(
        difftime(
          Sys.time(), debut,
          units = "secs"
        )
      ),
      1
    ),
    "secondes\n"
  )

  invisible(TRUE)
}

# Lancement de la chaine

executer_pipeline()
