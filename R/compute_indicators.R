# ============================================
# SRE DATA QUALITY & STATISTICAL REPORTING
# Fichier : R/compute_indicators.R
# Objet : Evolution annuelle des pensions
# ============================================

calculer_flux_annuel <- function(donnees) {

  # 1. Verifier les variables obligatoires

  dimensions <- c(
    "annee",
    "categorie_civile",
    "motif_depart",
    "sexe"
  )

  colonnes <- c(dimensions, "effectif")

  if (!all(colonnes %in% names(donnees))) {
    stop("Variables obligatoires manquantes")
  }

  # 2. Verifier les donnees

  if (anyNA(donnees[colonnes])) {
    stop("Valeurs manquantes detectees")
  }

  if (!is.numeric(donnees$effectif) ||
      any(!is.finite(donnees$effectif)) ||
      any(donnees$effectif < 0) ||
      any(donnees$effectif != floor(donnees$effectif))) {
    stop("Effectifs invalides")
  }

  if (anyDuplicated(donnees[dimensions]) > 0) {
    stop("Doublons de dimensions detectes")
  }

  annees <- as.character(donnees$annee)

  if (any(!grepl("^[0-9]{4}$", annees))) {
    stop("Format des annees invalide")
  }

  # 3. Calculer les effectifs annuels

  resultat <- aggregate(
    donnees$effectif,
    by = list(annee = as.integer(annees)),
    FUN = sum
  )

  names(resultat)[2] <- "nouvelles_pensions"

  resultat <- resultat[
    order(resultat$annee),
  ]

  rownames(resultat) <- NULL

  # 4. Calculer les variations annuelles

  precedent <- c(
    NA_real_,
    head(resultat$nouvelles_pensions, -1)
  )

  resultat$variation_absolue <-
    resultat$nouvelles_pensions - precedent

  resultat$variation_pct <- ifelse(
    is.na(precedent) | precedent == 0,
    NA_real_,
    100 * resultat$variation_absolue / precedent
  )

  return(resultat)
}

# ============================================
# FIN DU FICHIER
# ============================================