-- 02_match_schedule.sql
-- What this shows: Match schedule with slot and venue details.
-- Sample output:
-- match_id | start_time           | venue           | home_team | away_team
-- 5        | 2026-01-13 16:00+00  | Rocks The Lakes | Suisse    | Espagne

SELECT
  m.id AS match_id,
  s.start_time,
  v.name AS venue,
  ht.name AS home_team,
  at.name AS away_team,
  m.status
FROM matches m
JOIN match_slot ms ON ms.match_id = m.id
JOIN slots s ON s.id = ms.slot_id
JOIN courts c ON c.id = s.court_id
JOIN venues v ON v.id = c.venue_id
JOIN teams ht ON ht.id = m.home_team_id
JOIN teams at ON at.id = m.away_team_id
ORDER BY s.start_time;
