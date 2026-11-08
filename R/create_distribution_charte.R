
# =============================================
# SRE DATA QUALITY & STATISTICAL REPORTING
# Fichier : R/create_distribution_charts.R
# Objet : Graphiques des repartitions annuelles
# =============================================

creer_graphiques_repartition <- function() {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Installer ggplot2 avant de continuer")
  }

  fichiers <- c(
    categories = "repartition_categories.csv",
    sexes = "repartition_sexes.csv",
    motifs = "repartition_motifs.csv"
  )

  titres <- c(
    categories = "Categories civiles",
    sexes = "Repartition par sexe",
    motifs = "Motifs de depart (codes du cube)"
  )

  # Importation des tableaux deja calcules

  tableaux <- lapply(fichiers, function(nom) {

    chemin <- file.path("outputs/tables", nom)

    if (!file.exists(chemin)) {
      stop(paste("Fichier absent :", chemin))
    }

    tab <- read.csv(chemin)

    requis <- c(
      "annee", "modalite", "effectif",
      "total_annuel", "part_pct"
    )

    if (!all(requis %in% names(tab)) ||
        nrow(tab) == 0 ||
        anyNA(tab[requis])) {
      stop(paste("Tableau invalide :", nom))
    }

    if (anyDuplicated(tab[c("annee", "modalite")])) {
      stop("Doublons dans les repartitions")
    }

    tab
  })

  annees <- sapply(tableaux, function(x) {
    max(x$annee)
  })

  if (length(unique(annees)) != 1) {
    stop("Les tableaux n'ont pas la meme annee finale")
  }

  annee <- annees[1]

  dir.create(
    "outputs/figures",
    recursive = TRUE,
    showWarnings = FALSE
  )

  # Construction des trois figures

  for (nom in names(tableaux)) {

    tab <- tableaux[[nom]]

    donnees <- tab[
      tab$annee == annee,
      ,
      drop = FALSE
    ]

    if (!is.numeric(donnees$part_pct) ||
        !is.numeric(donnees$effectif) ||
        any(!is.finite(donnees$part_pct)) ||
        any(donnees$part_pct < 0) ||
        any(donnees$part_pct > 100) ||
        length(unique(donnees$total_annuel)) != 1 ||
        sum(donnees$effectif) !=
          unique(donnees$total_annuel) ||
        abs(sum(donnees$part_pct) - 100) > 0.01) {
      stop(paste("Repartition incoherente :", nom))
    }

    ordre <- donnees$modalite[
      order(donnees$part_pct, decreasing = TRUE)
    ]

    donnees$modalite <- factor(
      donnees$modalite,
      levels = rev(ordre)
    )

    graphique <- ggplot2::ggplot(
      donnees,
      ggplot2::aes(
        x = modalite,
        y = part_pct
      )
    ) +
      ggplot2::geom_col(
        fill = "#245577",
        width = 0.65
      ) +
      ggplot2::geom_text(
        ggplot2::aes(
          label = paste0(
            formatC(
              part_pct,
              format = "f",
              digits = 1,
              decimal.mark = ","
            ),
            " %"
          )
        ),
        hjust = -0.15,
        size = 4
      ) +
      ggplot2::coord_flip(clip = "off") +
      ggplot2::scale_y_continuous(
        labels = function(x) paste0(x, " %"),
        expand = ggplot2::expansion(
          mult = c(0, 0.20)
        )
      ) +
      ggplot2::labs(
        title = titres[[nom]],
        subtitle = paste(
          "Nouvelles pensions civiles -",
          annee
        ),
        x = NULL,
        y = "Part des nouvelles pensions",
        caption = paste(
          "Source : DGFiP / SRE",
          "Cube flux civil droit direct 1",
          "Projet personnel non officiel",
          sep = "\n"
        )
      ) +
      ggplot2::theme_minimal(base_size = 13) +
      ggplot2::theme(
        plot.title = ggplot2::element_text(
          face = "bold"
        ),
        panel.grid.major.y =
          ggplot2::element_blank(),
        panel.grid.minor =
          ggplot2::element_blank()
      )

    sortie <- file.path(
      "outputs/figures",
      paste0("repartition_", nom, ".png")
    )

    ggplot2::ggsave(
      filename = sortie,
      plot = graphique,
      width = 9,
      height = 5,
      dpi = 300,
      bg = "white"
    )

    print(graphique)

    message("Graphique cree : ", sortie)
  }

  invisible(TRUE)
}
