-- 03_referee_assignments.sql
-- What this shows: Assigned referees per match.
-- Sample output:
-- match_id | referee_id | role   | start_time
-- 5        | 4          | center | 2026-01-13 16:00+00

SELECT
  mr.match_id,
  mr.referee_id,
  mr.role,
  s.start_time
FROM match_referees mr
JOIN match_slot ms ON ms.match_id = mr.match_id
JOIN slots s ON s.id = ms.slot_id
ORDER BY s.start_time;
