-- =============================================================
-- fact_ventes : une ligne par vente (table de faits)
-- =============================================================
-- Ne garde que les mesures et les clés vers les dimensions :
-- le nom du produit et son prix vivent désormais dans dim_produits.
-- id_produit est recalculé avec exactement le même DENSE_RANK
-- que dans dim_produits : même produit, même numéro des deux côtés.
-- id_vente fixe le grain de la table (une ligne = une vente) : sans lui,
-- une fusion Looker Studio regroupe les ventes identiques et fausse le panier moyen.
-- region est normalisée (accents) et code_region (ISO 3166-2) sert à la carte.

SELECT
  ROW_NUMBER() OVER (ORDER BY Date, Produit, Region, Canal) AS id_vente,
  Date AS id_date,
  DENSE_RANK() OVER (ORDER BY Produit) AS id_produit,
  REPLACE(REPLACE(Region, 'Rhone', 'Rhône'), 'Ile-de', 'Île-de') AS region,
  CASE Region
    WHEN 'Ile-de-France'              THEN 'FR-IDF'
    WHEN 'Auvergne-Rhone-Alpes'       THEN 'FR-ARA'
    WHEN 'Bretagne'                   THEN 'FR-BRE'
    WHEN 'Hauts-de-France'            THEN 'FR-HDF'
    WHEN 'Occitanie'                  THEN 'FR-OCC'
    WHEN 'Pays-de-la-Loire'           THEN 'FR-PDL'
    WHEN "Provence-Alpes-Cote d'Azur" THEN 'FR-PAC'
    WHEN 'Nouvelle-Aquitaine'         THEN 'FR-NAQ'
    WHEN 'Grand Est'                  THEN 'FR-GES'
    WHEN 'Normandie'                  THEN 'FR-NOR'
    WHEN 'Bourgogne-Franche-Comte'    THEN 'FR-BFC'
    WHEN 'Centre-Val de Loire'        THEN 'FR-CVL'
    WHEN 'Corse'                      THEN 'FR-20R'
  END AS code_region,
  Canal AS canal,
  Quantite AS quantite,
  Chiffre_affaires AS chiffre_affaires
FROM `my-project-septembre-2026.boutique.vente_boutique`
ORDER BY id_vente
