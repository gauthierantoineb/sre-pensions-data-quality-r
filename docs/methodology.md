# Protocole methodologique — MVP

## Question metier

Comment reconstituer des statistiques annuelles fiables sur les nouvelles pensions civiles de droit direct, a partir d'un seul cube agrege et de controles documentes, en distinguant les defauts techniques, les anomalies a instruire et les variations descriptives ?

## Champ et limites

- Flux de nouvelles pensions civiles de droit direct, et **non** stocks de pensions.
- Cellule agregee par annee, categorie, motif detaille et sexe, **sous reserve de verification de la cle sur l'export**.
- Edition definitive 2025 des chiffres cles diffusee en juin 2026 ; comparaison exploratoire avec les donnees les plus recentes.
- L'annee la plus ancienne et la plus recente, la continuite temporelle, la licence de chaque export et les nomenclatures doivent etre confirmees avant diffusion.
- Le SRE a signale une refonte de sa chaine de production en 2022. Une evolution temporelle n'est pas une interpretation causale.

## Formules prevues (non executees)

Pour un perimetre P (par ex. l'ensemble des cellules d'une annee) :

- `N(P) = sum(effectif_i)` : nombre de nouvelles pensions (unite : pensions).
- `part_categorie(P,c) = sum(effectif_i pour c) / N(P) * 100` : part en %.
- `age_moyen(P) = sum(age_i) / N(P)` : annees a la date d'effet de la pension initiale.
- `pension_moyenne(P) = sum(montant_pension_i) / N(P)` : euros courants mensuels bruts.
- `duree_totassur_moyenne(P) = sum(duree_totassur_i) / sum(effectif_totassur_i)` : unite a confirmer dans le JSON.
- `variation_abs_N(t) = N(t) - N(t-1)` ; `variation_pct_N(t) = 100*(N(t)-N(t-1))/N(t-1)` si `N(t-1)>0` ; sinon NA + anomalie contextuelle.

**Precondition** : ne jamais appliquer une formule si une composante critique manque, si les denominators sont invalides, ou si les cellules se chevauchent. La somme n'est licite que sur des cellules disjointes.

## Controle qualite prioritaire (8 regles)

| ID | Regle | Gravite initiale | Traitement en cas de signalement |
|---|---|---|---|
| Q01 | Schema technique : 11 colonnes attendues, types convertibles, pas de colonnes cachees | Bloquante | Suspendre le calcul et verifier version/export |
| Q02 | Completude des dimensions de cle et mesures critiques ; distinguer champ vide, `S`, `.` | Bloquante si perimetre impacte ; sinon avertissement | Caracteriser la non-disponibilite avant calcul |
| Q03 | Doublons exacts et doublons des 4 dimensions de cle | Bloquante | Rechercher doublons d'extraction / granularite |
| Q04 | `effectif` et `effectif_totassur` entiers >= 0 ; `effectif_totassur <= effectif` | Bloquante | Examiner le champ et la specification du producteur |
| Q05 | Modalites categorie/sexe/motif conformes au dictionnaire versionne | Avertissement | Verifier evolution de nomenclature ; ne pas recoder automatiquement |
| Q06 | Denominateurs > 0 pour moyennes et correspondance des mesures ; valeurs interdites | Bloquante pour l'indicateur concerne | Ne pas publier de moyenne non definie |
| Q07 | Age moyen et pension mensuelle moyenne plausibles selon un domaine justifie ; pas de correction automatique | Avertissement | Examiner agregat, unite, changement de definition |
| Q08 | Variations temporelles inhabituelles et reconciliation avec chiffres cles publics | Observation / avertissement | Consigner ecart, verifier champ et methode, pas de correction automatique |

Le seuil de variation temporelle sera fixe et documente **apres** examen du profil reel. Il n'est pas approprie d'en inventer un pour faire remonter des anomalies.

### Reconciliation avec publication officielle

Le SRE publie **47 104 nouvelles pensions civiles de droit direct en 2025** dans l'edition definitive de juin 2026. Ce chiffre publie est une cible de rapprochement externe, **pas un resultat genere par le projet**. Une difference avec `sum(effectif)` en 2025 exigera une explication de perimetre/version avant toute diffusion.

Source : https://retraitesdeletat.gouv.fr/statistiques/flux-civ-DD.html

## Sorties MVP (a produire dans les phases suivantes)

1. `outputs/quality/summary.csv` et `outputs/quality/anomalies.csv`, avec regle, cle, valeur, severite, proposition d'investigation.
2. `data/processed/cube_validated.rds` avec transformations tracees, sans correction implicite.
3. Tables annuelles et ventilations par categorie, sexe, motif ; calcul des moyennes seulement si les conditions sont satisfaites.
4. Graphiques : flux annuel, categorie, motif, age, montant mensuel brut. Distribution selon sexe dans une table.
5. Rapport `reports/analyse_pensions.qmd` et note non technique appuyes **uniquement** sur les sorties calculees.

## Regle de diffusion

Toute anomalie bloquante affectant un indicateur interdit de le publier. Une observation statistique inhabituelle ne suffit pas a invalider un chiffre. Aucun secret statistique ne sera deduit en recoupant volontairement des cellules masquees.

## Sources

- https://data.economie.gouv.fr/explore/dataset/cube-flux-civil-droit-direct-1/
- https://retraitesdeletat.gouv.fr/statistiques/flux-civ-DD.html
- https://retraitesdeletat.gouv.fr/statistiques/glossaire.html
- https://retraitesdeletat.gouv.fr/professionnels/les-donnees-statistiques/les-chiffres-cles-des-retraites-de-letat
