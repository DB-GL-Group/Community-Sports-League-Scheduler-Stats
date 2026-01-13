-- 06_top_scorers.sql
-- What this shows: Top scorers across finished matches.
-- Sample output:
-- player_id | first_name | last_name | goals
-- 12        | Noah       | Brez      | 4

SELECT
  g.player_id,
  p.first_name,
  p.last_name,
  COUNT(*) AS goals
FROM goals g
JOIN persons p ON p.id = g.player_id
JOIN matches m ON m.id = g.match_id
WHERE m.status = 'finished'
GROUP BY g.player_id, p.first_name, p.last_name
ORDER BY goals DESC;
