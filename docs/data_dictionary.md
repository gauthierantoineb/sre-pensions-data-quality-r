# Dictionnaire des données

## Source

DGFiP / Service des retraites de l'État.

Jeu : Retraite - Cube flux civil droit direct 1.

Descriptions issues des métadonnées du portail officiel.

## Variables

### `annee`

- Type portail : `text`
- Unité : Année
- Dénominateur : `Sans objet`

**Description officielle extraite :**

> Type : Dimension
> 
> Définition : Année d'observation de la pension en base de donnée au 31/12/N. 
> 
> Nomenclature : De 2013 à 2019.
> 

### `categorie_civile`

- Type portail : `text`
- Unité : Sans unité
- Dénominateur : `Sans objet`

**Description officielle extraite :**

> Type : Dimension
> 
> Définition : Catégorie statutaire de regroupement des corps ou cadre d'emplois.
> 
> Nomenclature :
> - A pour catégorie A
> - B pour catégorie B
> - C pour catégorie C

### `motif_depart`

- Type portail : `text`
- Unité : Sans unité
- Dénominateur : `Sans objet`

**Description officielle extraite :**

> Type : Dimension
> 
> Définition : Motif de départ (détaillé) donnant lieu à la liquidation d'une pension.
> 
> Nomenclature : 
> - VAS pour Ancienneté sédentaire
> - VAA pour Ancienneté actif
> - VAC pour Ancienneté carrière longue
> - VFF pour Motifs familiaux
> - INV pour Invalidité

### `sexe`

- Type portail : `text`
- Unité : Sans unité
- Dénominateur : `Sans objet`

**Description officielle extraite :**

> Type : Dimension
> 
> Définition : Qualité de femme ou qualité d'homme du.de la pensionné.e.
> 
> Nomenclature : 
> - F pour Femme
> - H pour Homme

### `effectif`

- Type portail : `int`
- Unité : Nombre de pensions
- Dénominateur : `Sans objet`

**Description officielle extraite :**

> Type : Mesure
> 
> Définition : Nombre de pensions partageant les mêmes caractéristiques (dimensions).

### `age`

- Type portail : `double`
- Unité : Années décimales, somme agrégée
- Dénominateur : `effectif`

**Description officielle extraite :**

> Type : Mesure
> 
> Définition : Âge en décimal des pensionné.e.s à la jouissance initiale de la pension, à diviser par la variable effectif.

### `montant_pension`

- Type portail : `double`
- Unité : Euros mensuels bruts, somme agrégée
- Dénominateur : `effectif`

**Description officielle extraite :**

> Type : Mesure
> 
> Définition : Montant brut mensuel moyen de la pension, inclus le montant principal ainsi que les accessoires et majorations non soumis à condition de ressources, à diviser par la variable effectif.

### `duree_services_retenus`

- Type portail : `double`
- Unité : Trimestres, somme agrégée
- Dénominateur : `effectif`

**Description officielle extraite :**

> Type : Mesure
> 
> Définition : Trimestres de services retenus pour la liquidation après application des règles d'écrêtement, à diviser par la variable effectif.

### `duree_bonifications_retenues`

- Type portail : `double`
- Unité : Trimestres, somme agrégée
- Dénominateur : `effectif`

**Description officielle extraite :**

> Type : Mesure
> 
> Définition : Trimestres de bonifications retenus pour la liquidation après application des règles d'écrêtement, à diviser par la variable effectif.

### `duree_totassur`

- Type portail : `double`
- Unité : Trimestres, somme agrégée
- Dénominateur : `effectif_totassur`

**Description officielle extraite :**

> Type : Mesure
> 
> Définition : Trimestres de services et bonifications tous régimes servant au calcul d'une éventuelle surcote ou décote, à diviser par la variable effectif_totassur.

### `effectif_totassur`

- Type portail : `int`
- Unité : Nombre de pensions
- Dénominateur : `Sans objet`

**Description officielle extraite :**

> Type : Mesure
> 
> Définition : Nombre de pensions pour lesquelles la durée d'assurance tous régimes est connue.

## Modalités observées dans le CSV étudié

- Années : 2015 à 2025.
- Catégories : A, B, C.
- Sexe : F, M.
- Motifs : INV, VAA, VAS, VCL, VFF.

Ces valeurs sont observées et ne constituent pas une nomenclature exhaustive.

## Écarts documentaires à investiguer

- Années : la description mentionne 2013-2019.
- Sexe : la description mentionne H, le CSV contient M.
- Carrière longue : la description mentionne VAC, le CSV contient VCL.

Aucun recodage automatique n'est appliqué.

## Principales règles de contrôle

- Schéma attendu : 11 variables.
- Clé métier : année, catégorie, motif, sexe.
- Unicité des combinaisons de dimensions.
- Effectifs entiers et non négatifs.
- Effectif_totassur inférieur ou égal à effectif.
- Complétude et validité des dimensions.
- Vérification des dénominateurs avant agrégation.
- Investigation des variations temporelles inhabituelles.

## Formules

- Âge moyen : somme(age) / somme(effectif).
- Pension moyenne : somme(montant_pension) / somme(effectif).
- Durée d'assurance moyenne : somme(duree_totassur) / somme(effectif_totassur).

Une moyenne est non calculable si son dénominateur est nul.

## Limites

Les descriptions du portail peuvent différer du fichier diffusé.
Les modalités et les périodes doivent être vérifiées à chaque acquisition.
Les mesures agrégées ne sont pas des observations individuelles.
