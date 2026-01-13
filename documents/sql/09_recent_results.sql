-- 09_recent_results.sql
-- What this shows: Latest finished matches by division.
-- Sample output:
-- match_id | division | home_team | away_team | score
-- 5        | 1        | Suisse    | Espagne   | 2-1

SELECT
  m.id AS match_id,
  m.division,
  ht.name AS home_team,
  at.name AS away_team,
  CONCAT(m.home_score, '-', m.away_score) AS score,
  s.start_time
FROM matches m
JOIN teams ht ON ht.id = m.home_team_id
JOIN teams at ON at.id = m.away_team_id
LEFT JOIN match_slot ms ON ms.match_id = m.id
LEFT JOIN slots s ON s.id = ms.slot_id
WHERE m.status = 'finished'
ORDER BY s.start_time DESC NULLS LAST
LIMIT 10;
