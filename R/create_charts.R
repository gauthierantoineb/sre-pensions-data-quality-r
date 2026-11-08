# ==========================================
# SRE DATA QUALITY & STATISTICAL REPORTING
# Fichier : R/create_charts.R
# Objet : Graphique des nouvelles pensions
# ==========================================

creer_graphique_flux <- function(
  fichier = "outputs/tables/flux_annuel.csv",
  sortie = "outputs/figures/flux_annuel.png"
) {

  # Verifier le package

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Le package ggplot2 doit etre installe")
  }

  # Verifier le fichier source

  if (!file.exists(fichier)) {
    stop("Tableau des indicateurs introuvable")
  }

  donnees <- read.csv(fichier)

  colonnes <- c("annee", "nouvelles_pensions")

  if (!all(colonnes %in% names(donnees))) {
    stop("Colonnes obligatoires manquantes")
  }

  if (nrow(donnees) == 0 ||
      anyNA(donnees[colonnes]) ||
      !is.numeric(donnees$annee) ||
      !is.numeric(donnees$nouvelles_pensions) ||
      any(!is.finite(donnees$nouvelles_pensions)) ||
      any(donnees$nouvelles_pensions < 0) ||
      anyDuplicated(donnees$annee) > 0) {
    stop("Donnees invalides pour le graphique")
  }

  donnees <- donnees[
    order(donnees$annee),
  ]

  # Construire le graphique

  graphique <- ggplot2::ggplot(
    donnees,
    ggplot2::aes(
      x = annee,
      y = nouvelles_pensions
    )
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
      breaks = donnees$annee
    ) +

    ggplot2::scale_y_continuous(
      limits = c(0, NA),
      labels = function(x) {
        format(
          x,
          big.mark = " ",
          scientific = FALSE,
          trim = TRUE
        )
      }
    ) +

    ggplot2::labs(
      title = "Nouvelles pensions civiles de droit direct",
      subtitle = paste(
        "Evolution annuelle -",
        min(donnees$annee),
        "a",
        max(donnees$annee)
      ),
      x = "Annee",
      y = "Nombre de nouvelles pensions",
      caption = paste(
        "Source : DGFiP / SRE - Cube flux civil droit direct 1",
        "Projet personnel non officiel",
        sep = "\n"
      )
    ) +

    ggplot2::theme_minimal(
      base_size = 12
    ) +

    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold"
      ),
      panel.grid.minor = ggplot2::element_blank()
    )

  # Exporter le graphique

  dir.create(
    dirname(sortie),
    recursive = TRUE,
    showWarnings = FALSE
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

  invisible(graphique)
}