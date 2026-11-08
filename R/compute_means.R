# ==========================================
# SRE DATA QUALITY & STATISTICAL REPORTING
# Fichier : R/compute_means.R
# Objet : Calcul des moyennes annuelles
# ==========================================

calculer_moyennes_annuelles <- function(donnees) {

  # 1. Variables obligatoires

  dimensions <- c(
    "annee",
    "categorie_civile",
    "motif_depart",
    "sexe"
  )

  mesures <- c(
    "effectif",
    "age",
    "montant_pension"
  )

  requis <- c(dimensions, mesures)

  if (!is.data.frame(donnees) ||
      !all(requis %in% names(donnees))) {
    stop("Schema incomplet")
  }

  if (nrow(donnees) == 0 ||
      anyNA(donnees[requis])) {
    stop("Donnees vides ou manquantes")
  }

  # 2. Validation des mesures

  if (!all(sapply(donnees[mesures], is.numeric))) {
    stop("Types numeriques invalides")
  }

  if (any(!is.finite(
    as.matrix(donnees[mesures])
  ))) {
    stop("Mesures non finies")
  }

  if (any(donnees$effectif < 0) ||
      any(donnees$effectif !=
          floor(donnees$effectif)) ||
      any(donnees$age < 0) ||
      any(donnees$montant_pension < 0)) {
    stop("Mesures invalides")
  }

  if (anyDuplicated(donnees[dimensions]) > 0) {
    stop("Doublons de cles metier")
  }

  annees <- as.character(donnees$annee)

  if (any(!grepl("^[0-9]{4}$", annees))) {
    stop("Annees invalides")
  }

  # 3. Sommer les mesures par annee

  totaux <- aggregate(
    donnees[mesures],
    by = list(annee = as.integer(annees)),
    FUN = sum
  )

  totaux <- totaux[
    order(totaux$annee),
  ]

  # 4. Verifier le denominateur

  if (any(totaux$effectif == 0)) {
    stop("Denominateur annuel nul")
  }

  # 5. Calculer les moyennes

  resultat <- data.frame(
    annee = totaux$annee,

    nouvelles_pensions = totaux$effectif,

    age_moyen_ans =
      totaux$age / totaux$effectif,

    pension_moyenne_euros =
      totaux$montant_pension / totaux$effectif
  )

  rownames(resultat) <- NULL

  return(resultat)
}

# ==========================================
# FIN DU FICHIER
# ==========================================