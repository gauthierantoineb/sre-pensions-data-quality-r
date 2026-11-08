
# ==================================================
# SRE DATA QUALITY & STATISTICAL REPORTING
# Fichier : R/quality_checks.R
# Objet : Controle qualite des effectifs
# ==================================================


# 1. VERIFICATION DES COLONNES ET DES TYPES

verifier_effectifs <- function(donnees) {
  
  colonnes <- c(
    "effectif",
    "effectif_totassur"
  )
  
  if (!is.data.frame(donnees)) {
    stop("Les donnees doivent etre un tableau")
  }
  
  if (!all(colonnes %in% names(donnees))) {
    stop("Colonnes obligatoires manquantes")
  }
  
  if (!all(sapply(donnees[colonnes], is.numeric))) {
    stop("Les effectifs doivent etre numeriques")
  }
  
  invisible(TRUE)
}


# 2. TABLEAU RECAPITULATIF DES CONTROLES

auditer_effectifs <- function(donnees) {
  
  verifier_effectifs(donnees)
  
  colonnes <- c(
    "effectif",
    "effectif_totassur"
  )
  
  resultats <- lapply(colonnes, function(nom) {
    
    x <- donnees[[nom]]
    
    data.frame(
      variable = nom,
      
      controle = c(
        "Manquants",
        "Negatifs",
        "Non entiers",
        "Nuls"
      ),
      
      anomalies = c(
        sum(is.na(x)),
        sum(x < 0, na.rm = TRUE),
        sum(x != floor(x), na.rm = TRUE),
        sum(x == 0, na.rm = TRUE)
      )
    )
  })
  
  bilan <- do.call(rbind, resultats)
  
  autre <- data.frame(
    variable = "effectif_totassur",
    controle = "Superieur a effectif",
    
    anomalies = sum(
      donnees$effectif_totassur >
        donnees$effectif,
      na.rm = TRUE
    )
  )
  
  rownames(bilan) <- NULL
  
  bilan <- rbind(bilan, autre)
  
  rownames(bilan) <- NULL
  
  return(bilan)
}


# 3. JOURNAL DETAILLE DES ANOMALIES

journaliser_effectifs <- function(donnees) {
  
  verifier_effectifs(donnees)
  
  colonnes <- c(
    "effectif",
    "effectif_totassur"
  )
  
  # Initialiser un journal vide
  
  journal <- data.frame(
    ligne = integer(),
    variable = character(),
    valeur = character(),
    regle = character(),
    gravite = character(),
    action = character(),
    stringsAsFactors = FALSE
  )
  
  # Examiner les deux effectifs
  
  for (nom in colonnes) {
    
    x <- donnees[[nom]]
    
    controles <- list(
      EFFECTIF_MANQUANT = which(is.na(x)),
      EFFECTIF_NEGATIF = which(x < 0),
      EFFECTIF_NON_ENTIER = which(x != floor(x)),
      EFFECTIF_NUL = which(x == 0)
    )
    
    gravites <- c(
      EFFECTIF_MANQUANT = "bloquante",
      EFFECTIF_NEGATIF = "bloquante",
      EFFECTIF_NON_ENTIER = "bloquante",
      EFFECTIF_NUL = "observation"
    )
    
    actions <- c(
      EFFECTIF_MANQUANT =
        "Verifier la source",
      
      EFFECTIF_NEGATIF =
        "Verifier la source",
      
      EFFECTIF_NON_ENTIER =
        "Verifier le type et la valeur",
      
      EFFECTIF_NUL =
        "Verifier si le zero est attendu"
    )
    
    for (regle in names(controles)) {
      
      lignes <- controles[[regle]]
      
      if (length(lignes) > 0) {
        
        nouvelle_anomalie <- data.frame(
          ligne = lignes,
          variable = nom,
          valeur = as.character(x[lignes]),
          regle = regle,
          gravite = unname(gravites[regle]),
          action = unname(actions[regle]),
          stringsAsFactors = FALSE
        )
        
        journal <- rbind(
          journal,
          nouvelle_anomalie
        )
      }
    }
  }
  
  # Verifier la relation entre effectifs
  
  lignes <- which(
    donnees$effectif_totassur >
      donnees$effectif
  )
  
  if (length(lignes) > 0) {
    
    autre <- data.frame(
      ligne = lignes,
      variable = "effectif_totassur",
      
      valeur = as.character(
        donnees$effectif_totassur[lignes]
      ),
      
      regle = "EFFECTIF_SUPERIEUR",
      gravite = "avertissement",
      
      action =
        "Verifier les definitions des effectifs",
      
      stringsAsFactors = FALSE
    )
    
    journal <- rbind(journal, autre)
  }
  
  rownames(journal) <- NULL
  
  return(journal)
}


# ==================================================
# FIN DU FICHIER
# Les donnees sources ne sont jamais modifiees.
# ==================================================