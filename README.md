# 🏆 Community Sports League

## Table of Contents

* [ℹ️ General Information](#general-information)
* [📁 Structure](#structure)
* [📦 Setup](#setup)
* [🛠 Useful Commands](#useful-commands)
* [🔄 Workflow to Update the DB](#workflow-to-update-the-db)
* [🔗 Database Access](#database-access)
* [✍️ Modify the Database](#modify-the-database)
* [🔥 Managing Flyway Version Conflicts](#managing-flyway-version-conflicts)
* [💾 Reset Local DB (dev ONLY)](#reset-local-db-dev-only)
* [🧪 Test Migrations](#test-migrations)

<a id="general-information"></a>

## ℹ️ General Information

### Description

Community Sports League is a student project at HESSO Valais-Wallis. The objectives are as follows:

* Database management
* ORM
* Application with portals (admin, fan, manager, referee, public)

### Prerequisites

* Docker + Docker Compose
* Git

### Docker Images Used

* Postgres:18
* Flyway:11

### External Tools

* Visualization: [dbdiagram.io](https://dbdiagram.io/home)

<a id="structure"></a>

## 📁 Structure

```bash
📁 COMMUNITY-SPORTS-LEAGUE-SCHEDULER-STATS
├── 📝 CONTRIBUTING.md
├── 📄 LICENSE
├── Ⓜ️ Makefile
├── 📝 PSQL_CheatSheet.md
├── 📝 README.md
├── 📁 app
│   ├── 📁 backend
│   └── 📁 frontend
├── 📁 db
│   └── 📁 migrations
│       └── 📚 V1__init.sql
├── 🐳 docker-compose.yml
└── 📁 documents
    ├── 📝 DB_leagues_diagram.pdf
    └── 📝 DB_leagues_diagram_new.pdf
```

<a id="setup"></a>

## 📦 Setup

**1) Clone the repository**

```bash
git clone https://github.com/DB-GL-Group/Community-Sports-League-Scheduler-Stats.git
cd Community-Sports-League-Scheduler-Stats
```

**2) Environment variables (Required)**

```bash
cp .env.example .env # Modify variables if needed
```

<a id="useful-commands"></a>

## 🛠 Useful Commands

| Action                  | Command              |
| ----------------------- | -------------------- |
| Start Postgres          | `make db-start`      |
| Apply migrations        | `make db-migrate`    |
| Check status            | `make db-status`     |
| Stop the DB             | `make db-stop`       |
| Delete data             | `make db-remove-all` |
| Reset (⚠️ deletes data) | `make db-reset`      |

<a id="workflow-to-update-the-db"></a>

## 🔄 Workflow to Update the DB

1️⃣ Pull updated code:

```
git pull --rebase
```

2️⃣ Start Postgres (if needed):

```
make db-start
```

3️⃣ Apply existing migrations (if necessary):

```
make db-migrate
make db-status
```

> 📌 Must display: `Database schema is up to date.`

> 📌 IMPORTANT: Any evolution goes through **a new versioned migration**.

<a id="database-access"></a>

## 🔗 Database Access

The PostgreSQL database is accessible on the port defined in the `.env` file (default `5432`).

A PostgreSQL client (such as `psql`, DBeaver, or Beekeeper studio) is required to connect with the credentials defined in the `.env` file.

### Examples

1. **`psql`**

   ```bash
   docker exec -it sports-league-db psql -U <user> -d sports_league 
   ```

2. **`Beekeeper Studio`**

   * Host: `localhost`
   * Port: `5432` (or the one defined in `.env`)
   * User: `<user>` (defined in `.env`)
   * Password: `<password>` (defined in `.env`)
   * Database: `sports_league` (defined in `.env`)

<a id="modify-the-database"></a>

## ✍️ Modify the Database

Any modification to the structure must be added in a SQL file in the `db/migrations/` folder. 
Files follow the following naming convention:

1. **Add a migration**

   ```
   "V<version>__<description>.sql"
   ```

2. **"Delete" a migration**

   ```
   db/migrations/U<version>__<description>.sql
   ```

> 📌 At container startup, all SQL scripts in this folder will be executed automatically to initialize the database.

> 📌 From Beekeeper Studio, these are the queries executed.

<a id="managing-flyway-version-conflicts"></a>

## 🔥 Managing Flyway Version Conflicts

**Conflicting case:**
Two migration files with the same version `V012__xxx.sql` and `V012__yyy.sql`.

**Rules:**
➡️ The first push wins.
➡️ The second must renumber.

**Solution:**

1. Rebase:

```
git pull --rebase
```

2. Find the latest number:

```
ls db/migrations
```

3. Rename your migration:

```
mv db/migrations/V012__mine.sql db/migrations/V013__mine.sql
```

4. Commit + push

<br>

> 🎯 No content modification required

<a id="reset-local-db-dev-only"></a>

## 💾 Reset Local DB (dev ONLY)

To start fresh (🛑 deletes all your local data):

```
make db-reset
```

This:

* deletes the Postgres volume
* recreates the empty DB
* reapplies **all** migrations in order

<a id="test-migrations"></a>

## 🧪 Test Migrations

Best practices:

* Test the migration on a new DB:

  ```
  make db-reset
  ```
* Verify there is **nothing pending**:

  ```
  m
  ```
