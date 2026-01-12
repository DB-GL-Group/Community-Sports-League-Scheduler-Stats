-- Seed a default admin account (replace CHANGE_ME hash before use).
-- Password hash should be generated with passlib argon2 to match backend auth.
WITH existing_user AS (
    SELECT id, person_id
    FROM users
    WHERE email = 'admin@example.com'
),
admin_person AS (
    INSERT INTO persons (first_name, last_name)
    SELECT 'Admin', 'User'
    WHERE NOT EXISTS (SELECT 1 FROM existing_user)
    RETURNING id
),
admin_user AS (
    INSERT INTO users (email, password_hash, person_id)
    SELECT
        'admin@example.com',
        '$argon2i$v=19$m=16,t=2,p=1$c3RiWDR0eGhPQkYwVFNoUA$Doou0Ow/C5BWommcWdUGXg', -- "admin"
        COALESCE(
            (SELECT id FROM admin_person),
            (SELECT person_id FROM existing_user)
        )
    WHERE NOT EXISTS (SELECT 1 FROM existing_user)
    RETURNING id
)
INSERT INTO user_roles (user_id, role_id)
SELECT
    COALESCE((SELECT id FROM admin_user), (SELECT id FROM existing_user)),
    r.id
FROM roles r
WHERE r.name = 'ADMIN'
ON CONFLICT DO NOTHING;
