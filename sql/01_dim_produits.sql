-- =============================================================
-- dim_produits : une ligne par produit (table de dimension)
-- Remplacer `my-project-septembre-2026` par l'identifiant de votre projet
-- =============================================================
-- SELECT DISTINCT ne garde qu'une ligne par produit.
-- Le fichier source ne contient pas d'identifiant produit :
-- DENSE_RANK en fabrique un (1, 2, 3... par ordre alphabétique).
-- En entreprise, on réutiliserait l'identifiant existant.

SELECT
  DENSE_RANK() OVER (ORDER BY Produit) AS id_produit,
  Produit       AS nom_produit,
  Categorie     AS categorie,
  Prix_unitaire AS prix_unitaire,
    CASE
    WHEN Prix_unitaire < 10 THEN 'Petit prix'
    WHEN Prix_unitaire < 20 THEN 'Gamme moyenne'
    ELSE 'Premium'
  END AS gamme_prix
FROM (
  SELECT DISTINCT Produit, Categorie, Prix_unitaire
  FROM `my-project-septembre-2026.boutique.vente_boutique`
)
ORDER BY id_produit
