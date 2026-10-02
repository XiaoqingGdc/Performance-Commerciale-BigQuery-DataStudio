-- =============================================================
-- Remplacer `my-project-septembre-2026` par l'identifiant de votre projet
-- Requêtes d'analyse (KPI du tableau de bord)
-- `ventes_etoile` = résultat de 04_jointure_etoile.sql enregistré comme vue
-- =============================================================

-- 1. CA total et panier moyen
SELECT
  ROUND(SUM(chiffre_affaires), 2)            AS ca_total,
  COUNT(*)                                   AS nb_ventes,
  ROUND(SUM(chiffre_affaires) / COUNT(*), 2) AS panier_moyen
FROM `my-project-septembre-2026.boutique.ventes_etoile`;

-- 2. Évolution mensuelle : 2026 vs 2025
SELECT
  mois,
  ROUND(SUM(IF(annee = 2025, chiffre_affaires, NULL)), 2) AS ca_2025,
  ROUND(SUM(IF(annee = 2026, chiffre_affaires, NULL)), 2) AS ca_2026,
  ROUND(100 * (SUM(IF(annee = 2026, chiffre_affaires, NULL))
             / SUM(IF(annee = 2025, chiffre_affaires, NULL)) - 1), 1) AS evolution_pct
FROM `my-project-septembre-2026.boutique.ventes_etoile`
GROUP BY mois
ORDER BY mois;

-- 3. Panier moyen : semaine vs week-end
SELECT
  type_jour,
  COUNT(*)                        AS nb_ventes,
  ROUND(AVG(chiffre_affaires), 2) AS panier_moyen
FROM `my-project-septembre-2026.boutique.ventes_etoile`
GROUP BY type_jour;

-- 4. CA par catégorie et part du total
SELECT
  categorie,
  ROUND(SUM(chiffre_affaires), 2) AS ca,
  ROUND(100 * SUM(chiffre_affaires) / SUM(SUM(chiffre_affaires)) OVER (), 1) AS part_pct
FROM `my-project-septembre-2026.boutique.ventes_etoile`
GROUP BY categorie
ORDER BY ca DESC;

-- 5. CA par canal et catégorie
SELECT canal, categorie, ROUND(SUM(chiffre_affaires), 2) AS ca
FROM `my-project-septembre-2026.boutique.ventes_etoile`
GROUP BY canal, categorie
ORDER BY canal, ca DESC;

-- 6. CA par région
SELECT region, ROUND(SUM(chiffre_affaires), 2) AS ca
FROM `my-project-septembre-2026.boutique.ventes_etoile`
GROUP BY region
ORDER BY ca DESC;

-- 7. Top produits (quantités vendues)
SELECT nom_produit, SUM(quantite) AS quantite
FROM `my-project-septembre-2026.boutique.ventes_etoile`
GROUP BY nom_produit
ORDER BY quantite DESC
LIMIT 5;
