-- 05_team_roster.sql
-- What this shows: Roster list for a team.
-- Sample output:
-- team_name | player_id | first_name | last_name | shirt_number
-- Suisse    | 12        | Noah       | Brez      | 2

SELECT
  t.name AS team_name,
  p.id AS player_id,
  p.first_name,
  p.last_name,
  pt.shirt_number
FROM player_team pt
JOIN teams t ON t.id = pt.team_id
JOIN persons p ON p.id = pt.player_id
WHERE t.id = 1
ORDER BY p.last_name, p.first_name;
