-- 04_referee_availability.sql
-- What this shows: Availability count per referee.
-- Sample output:
-- referee_id | slots_available
-- 3          | 5
-- 4          | 2

SELECT
  referee_id,
  COUNT(*) AS slots_available
FROM ref_dispos
GROUP BY referee_id
ORDER BY slots_available DESC;
