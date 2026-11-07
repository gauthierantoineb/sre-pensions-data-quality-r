#!/usr/bin/env Rscript
# Telecharge le JSON de metadonnees et exporte les descriptions exactes des champs.
# L'URL de l'API est documentee, mais son accessibilite reste a verifier.
if (!file.exists("config/data_sources.yml")) stop("Executer depuis la racine du depot.")
for (pkg in c("yaml", "jsonlite")) {
  if (!requireNamespace(pkg, quietly = TRUE)) stop("Installer le package ", pkg, ".")
}
cfg <- yaml::read_yaml("config/data_sources.yml")
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/quality", recursive = TRUE, showWarnings = FALSE)
target <- file.path("data/raw", paste0("metadata_", format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"), ".json"))
tryCatch(
  utils::download.file(cfg$metadata_api_url, target, method = "libcurl", mode = "wb", quiet = TRUE),
  error = function(e) stop("Acces aux metadonnees impossible : ", conditionMessage(e), call. = FALSE)
)
if (!file.exists(target) || file.info(target)$size == 0L) {
  stop("Reponse de metadonnees vide ou absente.", call. = FALSE)
}
metadata <- tryCatch(jsonlite::fromJSON(target, simplifyVector = FALSE),
                     error = function(e) stop("Reponse non interpretable comme JSON : ", conditionMessage(e)))
if (is.null(metadata$fields) || !length(metadata$fields)) {
  stop("Champs 'fields' introuvables dans les metadonnees. Examiner : ", target)
}
get_field <- function(entry, key) {
  value <- entry[[key]]
  if (is.null(value) || !length(value)) return(NA_character_)
  paste(as.character(unlist(value)), collapse = " | ")
}
fields <- data.frame(
  nom = vapply(metadata$fields, get_field, character(1), key = "name"),
  type_portail = vapply(metadata$fields, get_field, character(1), key = "type"),
  libelle = vapply(metadata$fields, get_field, character(1), key = "label"),
  description = vapply(metadata$fields, get_field, character(1), key = "description"),
  stringsAsFactors = FALSE
)
utils::write.csv(fields, "outputs/quality/metadata_fields.csv", row.names = FALSE,
                 fileEncoding = "UTF-8", na = "")
cat("JSON brut preserve :", target, "\n")
cat("Descriptions exportees : outputs/quality/metadata_fields.csv\n")
cat("Confronter ce fichier au dictionnaire : ne pas supposer un libelle absent.\n")
