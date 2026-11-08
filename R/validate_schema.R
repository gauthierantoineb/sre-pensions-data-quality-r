# Verification stricte du contrat de colonnes attendu pour la version initiale du cube.
# Aucun controle statistique ne doit etre confondu avec un controle de schema.

validate_schema <- function(data, expected_columns) {
  if (!is.data.frame(data)) stop("Le jeu importe doit etre un data.frame.", call. = FALSE)
  if (!is.character(expected_columns) || length(expected_columns) == 0L ||
      anyNA(expected_columns) || anyDuplicated(expected_columns)) {
    stop("Configuration du schema attendu invalide.", call. = FALSE)
  }
  observed <- names(data)
  if (anyDuplicated(observed)) {
    stop("En-tetes de colonnes dupliques dans le CSV.", call. = FALSE)
  }
  missing <- setdiff(expected_columns, observed)
  unexpected <- setdiff(observed, expected_columns)
  if (length(missing) > 0L || length(unexpected) > 0L) {
    stop(paste0(
      "Schema incompatible. Colonnes manquantes: ",
      if (length(missing)) paste(missing, collapse = ", ") else "aucune",
      ". Colonnes inattendues: ",
      if (length(unexpected)) paste(unexpected, collapse = ", ") else "aucune",
      "."
    ), call. = FALSE)
  }
  if (nrow(data) == 0L) stop("Le CSV ne contient aucune observation.", call. = FALSE)
  invisible(TRUE)
}
