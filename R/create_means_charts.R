# ==========================================
# SRE DATA QUALITY & STATISTICAL REPORTING
# Fichier : R/create_means_charts.R
# Objet : Graphiques des moyennes annuelles
# ==========================================

creer_graphiques_moyennes <- function() {

  # 1. Verifier les dependances

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Le package ggplot2 est absent")
  }

  fichier <- "outputs/tables/moyennes_annuelles.csv"

  if (!file.exists(fichier)) {
    stop("Fichier des moyennes introuvable")
  }

  # 2. Lire et valider les indicateurs

  donnees <- read.csv(fichier)

  colonnes <- c(
    "annee",
    "nouvelles_pensions",
    "age_moyen_ans",
    "pension_moyenne_euros"
  )

  if (!all(colonnes %in% names(donnees)) ||
      nrow(donnees) < 2) {
    stop("Tableau incomplet")
  }

  if (!all(sapply(donnees[colonnes], is.numeric)) ||
      any(!is.finite(as.matrix(donnees[colonnes]))) ||
      any(donnees$nouvelles_pensions <= 0) ||
      any(donnees$age_moyen_ans < 0) ||
      any(donnees$pension_moyenne_euros < 0) ||
      anyDuplicated(donnees$annee) > 0) {
    stop("Indicateurs invalides")
  }

  donnees <- donnees[order(donnees$annee), ]

  if (any(diff(donnees$annee) != 1)) {
    warning("Certaines annees sont absentes")
  }

  # 3. Definir les deux graphiques

  graphiques <- list(
    age = list(
      variable = "age_moyen_ans",
      titre = "Age moyen a la date d'effet initiale",
      unite = "Age moyen (annees)",
      fichier = "age_moyen_annuel.png"
    ),

    pension = list(
      variable = "pension_moyenne_euros",
      titre = "Montant mensuel brut moyen",
      unite = "Pension mensuelle (euros courants)",
      fichier = "pension_moyenne_annuelle.png"
    )
  )

  # 4. Creer et exporter les figures

  dir.create(
    "outputs/figures",
    recursive = TRUE,
    showWarnings = FALSE
  )

  for (nom in names(graphiques)) {

    info <- graphiques[[nom]]

    graphique_data <- data.frame(
      annee = donnees$annee,
      valeur = donnees[[info$variable]]
    )

    graphique <- ggplot2::ggplot(
      graphique_data,
      ggplot2::aes(x = annee, y = valeur)
    ) +
      ggplot2::geom_line(
        color = "#245577",
        linewidth = 1
      ) +
      ggplot2::geom_point(
        color = "#245577",
        size = 2.5
      ) +
      ggplot2::scale_x_continuous(
        breaks = donnees$annee[
          seq(1, nrow(donnees), by = 2)
        ]
      ) +
      ggplot2::labs(
        title = info$titre,
        subtitle = paste(
          "Nouvelles pensions civiles de droit direct",
          min(donnees$annee),
          "-",
          max(donnees$annee)
        ),
        x = "Annee",
        y = info$unite,
        caption = paste(
          "Source : DGFiP / SRE",
          "Projet personnel non officiel",
          sep = "\n"
        )
      ) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        plot.title = ggplot2::element_text(
          face = "bold"
        ),
        panel.grid.minor =
          ggplot2::element_blank()
      )

    sortie <- file.path(
      "outputs/figures",
      info$fichier
    )

    ggplot2::ggsave(
      filename = sortie,
      plot = graphique,
      width = 9,
      height = 5.5,
      dpi = 300,
      bg = "white"
    )

    print(graphique)
    message("Graphique cree : ", sortie)
  }

  invisible(TRUE)
}