
# ==========================================
# SRE DATA QUALITY & STATISTICAL REPORTING
# Fichier : R/compute_distributions.R
# Objet : Repartitions des nouvelles pensions
# ==========================================

calculer_repartitions <- function(donnees) {
  
  dimensions <- c(
    "annee",
    "categorie_civile",
    "motif_depart",
    "sexe"
  )
  
  colonnes <- c(dimensions, "effectif")
  
  # 1. Verifier les donnees
  
  if (!all(colonnes %in% names(donnees))) {
    stop("Colonnes obligatoires manquantes")
  }
  
  if (nrow(donnees) == 0) {
    stop("Jeu de donnees vide")
  }
  
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
    stop("Doublons de cles metier")
  }
  
  if (any(!grepl(
    "^[0-9]{4}$",
    as.character(donnees$annee)
  ))) {
    stop("Format des annees invalide")
  }
  
  if (any(!donnees$categorie_civile %in%
          c("A", "B", "C"))) {
    stop("Categorie civile inconnue")
  }
  
  if (any(!donnees$sexe %in% c("F", "M"))) {
    stop("Code sexe inconnu")
  }
  
  if (any(trimws(
    as.character(donnees$motif_depart)
  ) == "")) {
    stop("Motif de depart vide")
  }
  
  donnees$annee <- as.integer(
    as.character(donnees$annee)
  )
  
  # 2. Calculer les totaux annuels
  
  totaux <- aggregate(
    donnees$effectif,
    by = list(annee = donnees$annee),
    FUN = sum
  )
  
  names(totaux)[2] <- "total_annuel"
  
  # 3. Fonction de repartition
  
  repartir <- function(variable) {
    
    resultat <- aggregate(
      donnees$effectif,
      by = list(
        annee = donnees$annee,
        modalite = donnees[[variable]]
      ),
      FUN = sum
    )
    
    names(resultat)[3] <- "effectif"
    
    resultat <- merge(
      resultat,
      totaux,
      by = "annee"
    )
    
    resultat$part_pct <- ifelse(
      resultat$total_annuel == 0,
      NA_real_,
      100 * resultat$effectif /
        resultat$total_annuel
    )
    
    # Verification de reconciliation
    
    controle <- aggregate(
      resultat$effectif,
      by = list(annee = resultat$annee),
      FUN = sum
    )
    
    reference <- totaux$total_annuel[
      match(controle$annee, totaux$annee)
    ]
    
    if (any(controle$x != reference)) {
      stop(paste(
        "Echec de reconciliation :",
        variable
      ))
    }
    
    resultat <- resultat[
      order(
        resultat$annee,
        resultat$modalite
      ),
    ]
    
    rownames(resultat) <- NULL
    
    return(resultat)
  }
  
  # 4. Calculer les trois repartitions
  
  list(
    categories = repartir("categorie_civile"),
    sexes = repartir("sexe"),
    motifs = repartir("motif_depart")
  )
}

# ==========================================
# FIN DU FICHIER
# ==========================================
