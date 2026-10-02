-- =============================================================
-- dim_dates : calendrier complet, un jour par ligne
-- =============================================================
-- GENERATE_DATE_ARRAY génère tous les jours entre la première vente
-- et aujourd'hui (GREATEST / CURRENT_DATE) : aucun trou dans les
-- analyses temporelles, et le calendrier s'étend tout seul.
-- UNNEST transforme le tableau de dates en lignes.

SELECT
  d AS id_date,
  FORMAT_DATE('%m', d)                 AS mois_txt,   -- '01' … '12'
  CAST(EXTRACT(YEAR FROM d) AS STRING) AS annee_txt,  -- '2025', '2026'
  EXTRACT(YEAR FROM d)    AS annee,
  EXTRACT(QUARTER FROM d) AS trimestre,
  EXTRACT(MONTH FROM d)   AS mois,
  CASE EXTRACT(MONTH FROM d)
    WHEN 1 THEN 'janvier' WHEN 2 THEN 'février' WHEN 3 THEN 'mars'
    WHEN 4 THEN 'avril' WHEN 5 THEN 'mai' WHEN 6 THEN 'juin'
    WHEN 7 THEN 'juillet' WHEN 8 THEN 'août' WHEN 9 THEN 'septembre'
    WHEN 10 THEN 'octobre' WHEN 11 THEN 'novembre' WHEN 12 THEN 'décembre'
  END AS nom_mois,
  EXTRACT(DAY FROM d)       AS jour,
  EXTRACT(DAYOFWEEK FROM d) AS jour_semaine,   -- 1 = dimanche … 7 = samedi
  CASE EXTRACT(DAYOFWEEK FROM d)
    WHEN 1 THEN 'dimanche' WHEN 2 THEN 'lundi' WHEN 3 THEN 'mardi'
    WHEN 4 THEN 'mercredi' WHEN 5 THEN 'jeudi' WHEN 6 THEN 'vendredi'
    WHEN 7 THEN 'samedi'
  END AS nom_jour,
  EXTRACT(ISOWEEK FROM d) AS num_semaine,
  CASE WHEN EXTRACT(DAYOFWEEK FROM d) IN (1,7) THEN 1 ELSE 0 END AS est_weekend,
  CASE WHEN EXTRACT(DAYOFWEEK FROM d) IN (1,7) THEN 'Week-end' ELSE 'Semaine' END AS type_jour
FROM (
  SELECT GENERATE_DATE_ARRAY(MIN(Date), GREATEST(MAX(Date), CURRENT_DATE()), INTERVAL 1 DAY) AS jours
  FROM `my-project-septembre-2026.boutique.vente_boutique`
), UNNEST(jours) AS d
ORDER BY id_date
