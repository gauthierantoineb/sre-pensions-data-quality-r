#!/usr/bin/env Rscript
# Depuis la racine du depot :
# Rscript scripts/inspect_source.R --download
# Rscript scripts/inspect_source.R --local /chemin/vers/cube.csv

if (!file.exists("config/data_sources.yml")) {
  stop("Executer depuis la racine du depot.", call. = FALSE)
}
for (pkg in c("yaml", "readr")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package manquant : ", pkg, ". Installer avec install.packages().", call. = FALSE)
  }
}
source("R/validate_schema.R")
source("R/import_data.R")
config <- yaml::read_yaml("config/data_sources.yml")
args <- commandArgs(trailingOnly = TRUE)
if (identical(args, "--download")) {
  local_file <- NULL
} else if (length(args) == 2L && identical(args[1], "--local")) {
  local_file <- args[2]
} else {
  stop("Utilisation : --download OU --local chemin/vers/fichier.csv", call. = FALSE)
}

snapshot <- acquire_cube_csv(config$export_csv_url, local_file)
message("Copie brute preservee : ", snapshot)
imported <- read_cube_csv(snapshot, config$expected_columns,
                          config$csv_delimiter, config$decimal_mark)
data <- imported$data
if (!all(grepl("^[0-9]{4}$", data$annee[!is.na(data$annee)]))) {
  warning("Certaines annees ne sont pas codees sur quatre chiffres.", call. = FALSE)
}
profile <- c(
  paste0("fichier=", snapshot),
  paste0("n_lignes=", nrow(data)),
  paste0("n_variables=", ncol(data)),
  paste0("annees_observees=", paste(sort(unique(data$annee)), collapse = ",")),
  paste0("categories_observees=", paste(sort(unique(data$categorie_civile)), collapse = ",")),
  paste0("motifs_observes=", paste(sort(unique(data$motif_depart)), collapse = ",")),
  paste0("sexes_observes=", paste(sort(unique(data$sexe)), collapse = ",")),
  paste0("marqueurs_non_disponibilite=", nrow(imported$missing_markers))
)
dir.create("outputs/quality", recursive = TRUE, showWarnings = FALSE)
writeLines(profile, "outputs/quality/source_profile.txt")
utils::write.csv(imported$missing_markers, "outputs/quality/missing_markers.csv",
                 row.names = FALSE, na = "")
cat(paste(profile, collapse = "\n"), "\n")
message("Inspection terminee. Ce script n'est PAS un audit qualite complet.")
