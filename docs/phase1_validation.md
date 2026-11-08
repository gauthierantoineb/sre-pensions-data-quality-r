# Journal de validation — Phase 1

Date du cadrage : 6 novembre 2026.

| Controle | Statut | Preuve / point en suspens |
|---|---|---|
| Offre 2026-33192 et missions | VERIFIE PAR CONSULTATION WEB | Publication Passerelles, date limite 10/11/2026 |
| Producteur, domaine, objet du cube | VERIFIE PAR CONSULTATION WEB | Fiche officielle data.economie.gouv.fr ; reprise data.gouv.fr |
| Champs visibles et exemple de schema | VERIFIE SUR TABLE WEB | 11 colonnes, 330 enregistrements affiches au moment de la consultation |
| Licence et derniere mise a jour | VERIFIE PAR CATALOGUE SECONDAIRE | Licence Ouverte 2.0, derniere mise a jour 11/08/2026 (data.gouv.fr) |
| Periode precise / exhaustivite du CSV | A VERIFIER | Exemples entre 2015 et 2025 ; couverture temporelle non renseignee au catalogue secondaire |
| Mappage definitif des 5 codes de motif | A VERIFIER | Noms de codes observes, nomenclature detaillee absente de la page web accessible |
| Description exacte de chaque champ du JSON du cube | A VERIFIER | L'API metadata n'a pas repondu depuis l'environnement de preparation |
| Endpoint de telechargement et contenu CSV | A EXECUTER | URL conforme a la documentation Explore API 2.1, echec d'acces depuis cet environnement |
| Fonctions R et tests `testthat` | NON EXECUTES | Aucun interpreteur R / Rscript disponible localement |
| Paquet `renv` et fichier de verrouillage | NON INITIALISES | A generer apres execution effective et installation des dependances sous R |
| Indicateurs, graphiques, rapport | NON PRODUITS | Prevus pour phases 3 et 4 ; aucun chiffre invente |

**Important** : le fait d'avoir ecrit des tests ne vaut pas execution des tests.

## Commandes a lancer avant de valider la phase

```r
install.packages(c("readr", "yaml", "jsonlite", "testthat", "renv"))
```

```bash
Rscript scripts/inspect_metadata.R
Rscript scripts/inspect_source.R --download
Rscript scripts/run_tests.R
```

En cas d'indisponibilite de l'API : telecharger un CSV depuis l'interface du portail et passer par `--local`. Conserver logs d'execution et verifier les tableaux par rapprochement avec les chiffres cles 2025 du SRE.

## Verification pedagogique

1. Pourquoi `annee` reste-t-elle un caractere au stade d'import ?
2. Comment distinguer un champ numerique vraiment manquant du marqueur `S` et d'un `.` ?
3. Pourquoi le controle de doublons doit-il porter sur la combinaison des dimensions ?
4. Pour une moyenne annuelle, pourquoi additionner les numerateurs avant de diviser par la somme des effectifs ?
