# Acquisition conservatrice : copie exacte du CSV, provenance, puis lecture typee.
# Dependances : readr (import CSV). Aucun nettoyage automatique des observations.

assert_nonempty_file <- function(path) {
  if (length(path) != 1L || is.na(path) || !file.exists(path) ||
      dir.exists(path)) stop("Fichier absent ou chemin invalide : ", path, call. = FALSE)
  size <- file.info(path)$size
  if (is.na(size) || size == 0) stop("Fichier vide : ", path, call. = FALSE)
  invisible(TRUE)
}

acquire_cube_csv <- function(export_url, local_file = NULL,
                             output_dir = "data/raw") {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  stamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
  target <- file.path(output_dir, paste0("cube_flux_civil_droit_direct_1_", stamp, ".csv"))
  if (file.exists(target)) stop("Instantane deja present : ", target, call. = FALSE)
  temp <- tempfile(fileext = ".csv")
  on.exit(unlink(temp), add = TRUE)
  if (is.null(local_file)) {
    if (!is.character(export_url) || length(export_url) != 1L ||
        !grepl("^https://data[.]economie[.]gouv[.]fr/", export_url)) {
      stop("L'URL de telechargement doit appartenir au portail officiel.", call. = FALSE)
    }
    old_timeout <- getOption("timeout")
    options(timeout = max(60, old_timeout))
    on.exit(options(timeout = old_timeout), add = TRUE)
    tryCatch(
      utils::download.file(export_url, destfile = temp, method = "libcurl", quiet = TRUE,
                           mode = "wb"),
      error = function(e) stop("Telechargement impossible : ", conditionMessage(e), call. = FALSE)
    )
    origin <- export_url
    acquisition_mode <- "telechargement"
  } else {
    assert_nonempty_file(local_file)
    if (!file.copy(local_file, temp, overwrite = TRUE)) {
      stop("Impossible de copier le CSV local.", call. = FALSE)
    }
    origin <- normalizePath(local_file, winslash = "/", mustWork = TRUE)
    acquisition_mode <- "fichier_local"
  }
  assert_nonempty_file(temp)
  # Ecarter une page d'erreur HTML renvoyee avec un HTTP 200.
  first_line <- readLines(temp, n = 1L, warn = FALSE, encoding = "UTF-8")
  if (!length(first_line) || grepl("^\\s*<(html|!doctype)", first_line,
                                   ignore.case = TRUE)) {
    stop("Reponse vide ou page HTML au lieu d'un CSV.", call. = FALSE)
  }
  if (!file.copy(temp, target, overwrite = FALSE)) {
    stop("Echec de preservation de la copie brute.", call. = FALSE)
  }
  info <- c(
    paste0("date_acquisition_utc=", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    paste0("mode=", acquisition_mode),
    paste0("origine=", origin),
    paste0("fichier=", basename(target)),
    paste0("taille_octets=", file.info(target)$size),
    paste0("md5=", unname(tools::md5sum(target)))
  )
  writeLines(info, paste0(target, ".provenance.txt"), useBytes = TRUE)
  target
}

# Retourne valeurs typees, champs texte d'origine et marques de non-disponibilite.
# Les codes S/s et . ne sont jamais traites comme des valeurs numeriques valides.
read_cube_csv <- function(path, expected_columns, delimiter = ";", decimal_mark = ".") {
  assert_nonempty_file(path)
  if (!delimiter %in% c(";", ",", "\t", "|")) stop("Separateur CSV non pris en charge.")
  if (!decimal_mark %in% c(".", ",")) stop("Marque decimale non prise en charge.")
  raw <- readr::read_delim(
    file = path, delim = delimiter,
    col_types = readr::cols(.default = readr::col_character()),
    na = character(), trim_ws = TRUE, name_repair = "minimal",
    locale = readr::locale(encoding = "UTF-8"),
    show_col_types = FALSE, progress = FALSE
  )
  issues <- readr::problems(raw)
  if (nrow(issues)) stop("CSV mal forme : erreurs de structure lors de l'importation.")
  validate_schema(raw, expected_columns)
  if (anyNA(names(raw)) || any(!nzchar(names(raw)))) {
    stop("En-tete CSV invalide.", call. = FALSE)
  }
  typed <- as.data.frame(raw, stringsAsFactors = FALSE)
  numerical <- c("effectif", "age", "montant_pension", "duree_services_retenus",
                 "duree_bonifications_retenues", "duree_totassur", "effectif_totassur")
  sentinel_rows <- list()
  for (field in numerical) {
    v <- trimws(typed[[field]])
    missing_code <- is.na(v) | v %in% c("", "NA", ".", "S", "s")
    if (any(missing_code)) {
      sentinel_rows[[field]] <- data.frame(
        ligne = which(missing_code), variable = field,
        marqueur = v[missing_code], stringsAsFactors = FALSE
      )
    }
    valid_pattern <- if (decimal_mark == ".") {
      "^[+-]?[0-9]+([.][0-9]+)?$"
    } else {
      "^[+-]?[0-9]+(,[0-9]+)?$"
    }
    bad <- which(!missing_code & !grepl(valid_pattern, v))
    if (length(bad)) {
      stop(sprintf("Valeur numerique non conforme dans %s, ligne %s (export CSV).",
                   field, bad[1]), call. = FALSE)
    }
    v[missing_code] <- NA_character_
    if (decimal_mark == ",") v <- sub(",", ".", v, fixed = TRUE)
    typed[[field]] <- as.numeric(v)
  }
  # La variable annee reste du texte, comme la dimension du catalogue.
  # Sa validite (quatre chiffres, periode) est controlee dans le module qualite.
  markers <- if (length(sentinel_rows)) do.call(rbind, sentinel_rows) else {
    data.frame(ligne = integer(), variable = character(), marqueur = character())
  }
  rownames(markers) <- NULL
  list(data = typed, raw_text = as.data.frame(raw), missing_markers = markers)
}
