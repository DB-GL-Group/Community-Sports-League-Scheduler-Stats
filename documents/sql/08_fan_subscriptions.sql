-- 08_fan_subscriptions.sql
-- What this shows: Number of team subscriptions per user.
-- Sample output:
-- user_id | subscriptions
-- 1       | 3

SELECT
  u.id AS user_id,
  COUNT(uts.team_id) AS subscriptions
FROM users u
LEFT JOIN user_team_subscriptions uts ON uts.user_id = u.id
GROUP BY u.id
ORDER BY subscriptions DESC;
