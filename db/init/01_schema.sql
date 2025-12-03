-- =========================================================
--  CORE DOMAIN: PERSONS & ROLES METIER
-- =========================================================

CREATE TABLE persons (
    id          SERIAL PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(255),
    phone       VARCHAR(50)
);

CREATE TABLE seasons (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL
);

CREATE TABLE divisions (
    id          SERIAL PRIMARY KEY,
    season_id   INTEGER NOT NULL REFERENCES seasons(id),
    name        VARCHAR(100) NOT NULL,
    UNIQUE (season_id, name)
);

CREATE TABLE players (
    person_id   INTEGER PRIMARY KEY REFERENCES persons(id)
);

CREATE TABLE managers (
    person_id   INTEGER PRIMARY KEY REFERENCES persons(id)
);

CREATE TABLE referees (
    person_id   INTEGER PRIMARY KEY REFERENCES persons(id)
);

CREATE TABLE teams (
    id              SERIAL PRIMARY KEY,
    division_id     INTEGER NOT NULL REFERENCES divisions(id),
    name            VARCHAR(100) NOT NULL,
    manager_id      INTEGER REFERENCES managers(person_id),
    short_name      VARCHAR(20),
    color_primary   VARCHAR(50),
    color_secondary VARCHAR(50),
    UNIQUE (division_id, name)
);

CREATE TABLE player_team (
    player_id    INTEGER NOT NULL REFERENCES players(person_id),
    team_id      INTEGER NOT NULL REFERENCES teams(id),
    shirt_number INTEGER,
    active       BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (player_id, team_id)
);

-- =========================================================
--  VENUES / COURTS / SLOTS / MATCHES
-- =========================================================

CREATE TABLE venues (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    address VARCHAR(255)
);

CREATE TABLE courts (
    id       SERIAL PRIMARY KEY,
    venue_id INTEGER NOT NULL REFERENCES venues(id),
    name     VARCHAR(100),
    surface  VARCHAR(50),
    UNIQUE (venue_id, name)
);

CREATE TABLE slots (
    id         SERIAL PRIMARY KEY,
    court_id   INTEGER NOT NULL REFERENCES courts(id),
    start_time TIMESTAMPTZ NOT NULL,
    end_time   TIMESTAMPTZ NOT NULL,
    UNIQUE (court_id, start_time)
);

CREATE TABLE matches (
    id              SERIAL PRIMARY KEY,
    division_id     INTEGER NOT NULL REFERENCES divisions(id),
    slot_id         INTEGER NOT NULL UNIQUE REFERENCES slots(id),
    home_team_id    INTEGER NOT NULL REFERENCES teams(id),
    away_team_id    INTEGER NOT NULL REFERENCES teams(id),
    main_referee_id INTEGER REFERENCES referees(person_id),
    status          VARCHAR(20) NOT NULL DEFAULT 'scheduled', -- scheduled, finished, postponed...
    home_score      INTEGER,
    away_score      INTEGER,
    notes           TEXT,
    CONSTRAINT chk_match_teams_different CHECK (home_team_id <> away_team_id)
);

CREATE TABLE match_referees (
    match_id   INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    referee_id INTEGER NOT NULL REFERENCES referees(person_id),
    role       VARCHAR(30) NOT NULL,   -- 'center', 'assistant_1', ...
    PRIMARY KEY (match_id, referee_id)
);

CREATE TABLE ref_dispos (
    referee_id INTEGER NOT NULL REFERENCES referees(person_id),
    slot_id    INTEGER NOT NULL REFERENCES slots(id),
    PRIMARY KEY (referee_id, slot_id)
);

-- =========================================================
--  MATCHDAY: LINEUPS & EVENTS
-- =========================================================

CREATE TABLE lineups (
    match_id     INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    team_id      INTEGER NOT NULL REFERENCES teams(id),
    player_id    INTEGER NOT NULL REFERENCES players(person_id),
    is_starter   BOOLEAN NOT NULL DEFAULT TRUE,
    position     VARCHAR(20),
    shirt_number INTEGER,
    PRIMARY KEY (match_id, player_id)
);

CREATE TABLE goals (
    id          SERIAL PRIMARY KEY,
    match_id    INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    team_id     INTEGER NOT NULL REFERENCES teams(id),
    player_id   INTEGER REFERENCES players(person_id),
    minute      INTEGER,
    is_own_goal BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE cards (
    id        SERIAL PRIMARY KEY,
    match_id  INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    team_id   INTEGER NOT NULL REFERENCES teams(id),
    player_id INTEGER NOT NULL REFERENCES players(person_id),
    minute    INTEGER,
    card_type VARCHAR(10) NOT NULL,  -- 'Y', 'Y2R', 'R'
    reason    VARCHAR(255)
);

CREATE TABLE substitutions (
    id            SERIAL PRIMARY KEY,
    match_id      INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    team_id       INTEGER NOT NULL REFERENCES teams(id),
    player_out_id INTEGER NOT NULL REFERENCES players(person_id),
    player_in_id  INTEGER NOT NULL REFERENCES players(person_id),
    minute        INTEGER
);

-- =========================================================
--  DISCIPLINE : SUSPENSIONS & FINES
-- =========================================================

CREATE TABLE suspensions (
    id               SERIAL PRIMARY KEY,
    player_id        INTEGER NOT NULL REFERENCES players(person_id),
    start_match_id   INTEGER NOT NULL REFERENCES matches(id),
    matches_to_serve INTEGER NOT NULL CHECK (matches_to_serve > 0),
    served_matches   INTEGER NOT NULL DEFAULT 0,
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    reason           VARCHAR(255)
);

CREATE TABLE fines (
    id         SERIAL PRIMARY KEY,
    match_id   INTEGER REFERENCES matches(id),
    team_id    INTEGER REFERENCES teams(id),
    player_id  INTEGER REFERENCES players(person_id),
    reason     TEXT NOT NULL,
    amount     NUMERIC(10,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
--  AUTH / USERS / ROLES
-- =========================================================

CREATE TABLE users (
    id            SERIAL PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    person_id     INTEGER REFERENCES persons(id)
);

CREATE TABLE user_identities (
    id       SERIAL PRIMARY KEY,
    user_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50)  NOT NULL,    -- 'local', 'google', ...
    subject  VARCHAR(255) NOT NULL,    -- sub / id du provider
    UNIQUE (provider, subject)
);

CREATE TABLE roles (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE   -- 'FAN', 'MANAGER', 'REFEREE', 'ADMIN', ...
);

CREATE TABLE user_roles (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- =========================================================
--  USER FEATURES: FAVORITES / SUBSCRIPTIONS / NOTIFICATIONS
-- =========================================================

CREATE TABLE user_favorite_teams (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, team_id)
);

CREATE TABLE user_team_subscriptions (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, team_id)
);

CREATE TABLE user_player_subscriptions (
    user_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    player_id INTEGER NOT NULL REFERENCES players(person_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, player_id)
);

CREATE TABLE notification_settings (
    user_id             INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    email_enabled       BOOLEAN NOT NULL DEFAULT TRUE,
    push_enabled        BOOLEAN NOT NULL DEFAULT FALSE,
    notify_match_start  BOOLEAN NOT NULL DEFAULT TRUE,
    notify_match_result BOOLEAN NOT NULL DEFAULT TRUE,
    notify_team_news    BOOLEAN NOT NULL DEFAULT FALSE
);

-- =========================================================
--  INDEXES
-- =========================================================

-- Matches (accès rapide par équipe / status)
CREATE INDEX idx_matches_home_team ON matches(home_team_id);
CREATE INDEX idx_matches_away_team ON matches(away_team_id);
CREATE INDEX idx_matches_division_status ON matches(division_id, status);

-- Events
CREATE INDEX idx_goals_match ON goals(match_id);
CREATE INDEX idx_cards_match ON cards(match_id);
CREATE INDEX idx_subs_match ON substitutions(match_id);

-- Lineups (détection de conflits joueurs)
CREATE INDEX idx_lineups_player_match ON lineups(player_id, match_id);

-- User / roles / subscriptions / favorites
CREATE INDEX idx_user_roles_role
    ON user_roles(role_id);

CREATE INDEX idx_user_favorite_teams_team
    ON user_favorite_teams(team_id);

CREATE INDEX idx_user_team_subscriptions_team
    ON user_team_subscriptions(team_id);

CREATE INDEX idx_user_player_subscriptions_player
    ON user_player_subscriptions(player_id);

-- =========================================================
--  INITIAL DATA
-- =========================================================

INSERT INTO roles (name) VALUES ('FAN'), ('MANAGER'), ('REFEREE'), ('ADMIN');
