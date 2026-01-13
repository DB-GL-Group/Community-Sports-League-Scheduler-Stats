-- 01_team_rankings.sql
-- What this shows: Current points and goal difference by team for a division.
-- Sample output:
-- team_id | team_name | points | goal_diff
-- 1       | Suisse    | 9      | 6
-- 2       | Espagne   | 6      | 2

SELECT
  t.id AS team_id,
  t.name AS team_name,
  SUM(CASE
        WHEN m.home_team_id = t.id AND m.home_score > m.away_score THEN 3
        WHEN m.away_team_id = t.id AND m.away_score > m.home_score THEN 3
        WHEN m.home_score = m.away_score THEN 1
        ELSE 0
      END) AS points,
  SUM(CASE
        WHEN m.home_team_id = t.id THEN m.home_score - m.away_score
        WHEN m.away_team_id = t.id THEN m.away_score - m.home_score
        ELSE 0
      END) AS goal_diff
FROM teams t
LEFT JOIN matches m
  ON (m.home_team_id = t.id OR m.away_team_id = t.id)
  AND m.status = 'finished'
WHERE t.division = 1
GROUP BY t.id, t.name
ORDER BY points DESC, goal_diff DESC;
