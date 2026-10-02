-- =============================================================
-- 04_jointure_etoile : modèle en étoile joint en une seule requête
-- Remplacer `my-project-septembre-2026` par l'identifiant de votre projet
-- =============================================================
-- Équivalent SQL de la combinaison « Combiner les données » de Looker Studio.
--
-- Requête autonome : fact_ventes, dim_produits et dim_dates sont définies
-- dans le WITH (CTE), puis reliées par des LEFT JOIN.
-- Aucune table intermédiaire n'est nécessaire.
--
-- Utilisation :
--   1. Dans Looker Studio : source « ventes_flat », ensuite figée avec
--      le connecteur « Extraire des données » (source « ventes_snapshot ») :
--      le dashboard ne requête plus BigQuery à chaque affichage.
--   2. Dans BigQuery : enregistrée comme vue, utilisée par 05_analyses_kpi.sql :
--      CREATE OR REPLACE VIEW `my-project-septembre-2026.boutique.ventes_etoile` AS
--      <requête ci-dessous, sans le ORDER BY final>
-- =============================================================

WITH

-- -------------------------------------------------------------
-- Table de faits : une ligne = une vente
-- -------------------------------------------------------------
fact_ventes AS (
  SELECT
    -- Clé primaire : fixe le grain de la table.
    -- Sans elle, une fusion regroupe les ventes identiques et fausse le panier moyen.
    ROW_NUMBER() OVER (ORDER BY Date, Produit, Region, Canal) AS id_vente,

    -- Clés étrangères vers les dimensions
    Date AS id_date,
    DENSE_RANK() OVER (ORDER BY Produit) AS id_produit,  -- même règle que dim_produits

    -- Libellé de région normalisé (accents) pour l'affichage et les filtres
    REPLACE(REPLACE(Region, 'Rhone', 'Rhône'), 'Ile-de', 'Île-de') AS region,

    -- Code ISO 3166-2 : géolocalisation fiable sur la carte (sans problème d'accents)
    CASE Region
      WHEN 'Ile-de-France'              THEN 'FR-IDF'
      WHEN 'Auvergne-Rhone-Alpes'       THEN 'FR-ARA'
      WHEN 'Bretagne'                   THEN 'FR-BRE'
      WHEN 'Hauts-de-France'            THEN 'FR-HDF'
      WHEN 'Occitanie'                  THEN 'FR-OCC'
      WHEN 'Pays-de-la-Loire'           THEN 'FR-PDL'
      WHEN "Provence-Alpes-Cote d'Azur" THEN 'FR-PAC'  -- guillemets doubles : apostrophe dans le nom
      WHEN 'Nouvelle-Aquitaine'         THEN 'FR-NAQ'
      WHEN 'Grand Est'                  THEN 'FR-GES'
      WHEN 'Normandie'                  THEN 'FR-NOR'
      WHEN 'Bourgogne-Franche-Comte'    THEN 'FR-BFC'
      WHEN 'Centre-Val de Loire'        THEN 'FR-CVL'
      WHEN 'Corse'                      THEN 'FR-20R'
    END AS code_region,

    -- Mesures
    Canal            AS canal,
    Quantite         AS quantite,
    Chiffre_affaires AS chiffre_affaires
  FROM `my-project-septembre-2026.boutique.vente_boutique`
),

-- -------------------------------------------------------------
-- Dimension produits : une ligne par produit
-- -------------------------------------------------------------
dim_produits AS (
  SELECT
    -- Clé de substitution : le fichier source n'a pas d'identifiant produit
    DENSE_RANK() OVER (ORDER BY Produit) AS id_produit,
    Produit       AS nom_produit,
    Categorie     AS categorie,
    Prix_unitaire AS prix_unitaire,
    -- Segmentation par gamme de prix
    CASE
      WHEN Prix_unitaire < 10 THEN 'Petit prix'
      WHEN Prix_unitaire < 20 THEN 'Gamme moyenne'
      ELSE 'Premium'
    END AS gamme_prix
  FROM (
    -- DISTINCT : une ligne par produit.
    -- Un produit doit avoir une seule catégorie et un seul prix,
    -- sinon la jointure duplique ses ventes (voir le contrôle d'unicité).
    SELECT DISTINCT Produit, Categorie, Prix_unitaire
    FROM `my-project-septembre-2026.boutique.vente_boutique`
  )
),

-- -------------------------------------------------------------
-- Dimension dates : attributs calendaires des jours de vente
-- -------------------------------------------------------------
dim_dates AS (
  SELECT DISTINCT
    Date AS id_date,
    EXTRACT(YEAR FROM Date)                 AS annee,
    CAST(EXTRACT(YEAR FROM Date) AS STRING) AS annee_txt,  -- série du graphique 2026 vs 2025
    EXTRACT(MONTH FROM Date)                AS mois,
    FORMAT_DATE('%m', Date)                 AS mois_txt,   -- axe X '01' … '12' (tri correct en texte)
    CASE EXTRACT(MONTH FROM Date)
      WHEN 1 THEN 'janvier' WHEN 2 THEN 'février' WHEN 3 THEN 'mars'
      WHEN 4 THEN 'avril' WHEN 5 THEN 'mai' WHEN 6 THEN 'juin'
      WHEN 7 THEN 'juillet' WHEN 8 THEN 'août' WHEN 9 THEN 'septembre'
      WHEN 10 THEN 'octobre' WHEN 11 THEN 'novembre' WHEN 12 THEN 'décembre'
    END AS nom_mois,
    -- DAYOFWEEK : 1 = dimanche … 7 = samedi
    CASE WHEN EXTRACT(DAYOFWEEK FROM Date) IN (1, 7) THEN 'Week-end' ELSE 'Semaine' END AS type_jour
  FROM `my-project-septembre-2026.boutique.vente_boutique`
)

-- -------------------------------------------------------------
-- Jointure : la table de faits au centre, reliée à ses dimensions.
-- LEFT JOIN : toutes les ventes sont conservées, même si une clé
-- ne trouvait pas de correspondance dans une dimension.
-- -------------------------------------------------------------
SELECT
  f.id_vente,
  f.id_date,
  d.annee, d.annee_txt, d.mois, d.mois_txt, d.nom_mois, d.type_jour,
  f.region, f.code_region, f.canal,
  p.nom_produit, p.categorie, p.gamme_prix,
  f.quantite,
  f.chiffre_affaires
FROM fact_ventes f
LEFT JOIN dim_produits p ON f.id_produit = p.id_produit
LEFT JOIN dim_dates    d ON f.id_date    = d.id_date
ORDER BY f.id_vente;

-- -------------------------------------------------------------
-- Contrôle : le résultat doit être identique à la table source
-- Attendu : 3 433 lignes et 202 616,50 €
-- SELECT COUNT(*), ROUND(SUM(chiffre_affaires), 2) FROM ( <requête ci-dessus> );
-- -------------------------------------------------------------
