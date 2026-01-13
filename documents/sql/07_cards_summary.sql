-- 07_cards_summary.sql
-- What this shows: Cards per team.
-- Sample output:
-- team_name | yellows | reds
-- Suisse    | 2       | 0

SELECT
  t.name AS team_name,
  SUM(CASE WHEN c.card_type IN ('Y', 'Y2R') THEN 1 ELSE 0 END) AS yellows,
  SUM(CASE WHEN c.card_type = 'R' THEN 1 ELSE 0 END) AS reds
FROM cards c
JOIN teams t ON t.id = c.team_id
GROUP BY t.name
ORDER BY reds DESC, yellows DESC;
