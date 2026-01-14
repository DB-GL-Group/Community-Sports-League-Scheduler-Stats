# 🏆 Community Sports League — Scheduler & Stats

## 📚 Table of Contents

* [ℹ️ Overview](#overview)
* [🧱 Tech Stack](#tech-stack)
* [📁 Repository Structure](#repository-structure)
* [⚡ Quick Start](#quick-start)
* [🗄️ Database](#database)
* [🧠 Backend](#backend)
* [🎨 Frontend](#frontend)
* [🌱 Data Seeding (from backend docker terminal)](#data_seed)
* [🚀​ Release](#release)
* [📖 Documentation](#documentation)

---

<a id="overview"></a>

## ℹ️ Overview

**Community Sports League Scheduler Stats** is a full-stack project designed to manage a sports league with **role-based portals**:

* 👥 Fan
* 🧑‍💼 Manager
* 🧑‍⚖️ Referee
* 🛠️ Admin

Core features include:

* 📅 Match scheduling
* 🧑‍⚖️ Referee availability & assignment
* 🏆 Rankings & statistics
* 🟢 Live match event tracking

This project is developed as part of an academic curriculum and follows **industry best practices** (migrations, containerization, role-based access).

---

<a id="tech-stack"></a>

## 🧱 Tech Stack

* 🎨 **Frontend**: Flutter (Web)
* 🧠 **Backend**: FastAPI (Python)
* 🗄️ **Database**: PostgreSQL
* ⚙️ **Background jobs**: Redis + RQ
* 🧬 **Migrations**: Flyway
* 🐳 **Infrastructure**: Docker & Docker Compose

---

<a id="repository-structure"></a>

## 📁 Repository Structure

```bash
📁 Community-Sports-League-Scheduler-Stats
├── 📁 backend/            # FastAPI app + RQ worker
├── 📁 frontend/           # Flutter web UI
├── 📁 db/
│   └── 📁 migrations/     # Flyway SQL migrations
├── 📁 documents/          # Guides, architecture, SQL samples
├── 🐳 docker-compose.yml  # Development stack
└── Ⓜ️ Makefile            # Common commands
```

---

<a id="quick-start"></a>

## ⚡ Quick Start

### 1️⃣ Clone the repository

```bash
git clone https://github.com/DB-GL-Group/Community-Sports-League-Scheduler-Stats.git
cd Community-Sports-League-Scheduler-Stats
```

### 2️⃣ Environment variables

```bash
cp .env.example .env
```

### 3️⃣ Start database & apply migrations

```bash
make db-start
make db-migrate
```

### 4️⃣ Start backend & worker

```bash
make backend-start
```

### 5️⃣ Flutter setup
```bash
make flutter-setup
```
> 📌 This calls flutter-setup.ps1 (Windows) or flutter-setup.sh (MacOS/Linux). Follow the instructions to fully install flutter.


### 6️⃣ Start frontend (Flutter web)

```bash
cd frontend
flutter run -d chrome
```

---

<a id="database"></a>

## 🗄️ Database

### 📌 Structure & seeds

* Schema migrations: [`db/migrations/`](db/migrations/)
* Default roles: `V1__init.sql`
* Default admin user: `V2__seed_admin.sql`

### 🔧 Useful commands

```bash
make db-start        # Start DB container
make db-migrate      # Apply migrations
make db-status       # Flyway status
make db-stop         # Stop DB + Flyway
make db-reset        # Drop volume + reapply migrations
```

### 🔄 Migration workflow (Flyway)

* All schema changes go through a **new versioned migration**
* Naming convention:

  ```
  V<version>__<description>.sql
  ```
* If two migrations share the same version:

  * 🥇 First pushed wins
  * 🔁 Second must be renumbered
* Flyway runs automatically via `docker-compose`

> 📌 `make db-status` must display: **Database schema is up to date**

---

<a id="backend"></a>

## 🧠 Backend

* 🌐 API base URL: [http://localhost:8000](http://localhost:8000)
* ❤️ Health check: `GET /health`

### 🔐 Authentication

* `/auth/signup`
* `/auth/login`
* `/auth/me`

### ⚙️ Core services

* Scheduler: `/scheduler/run`, `/scheduler/status`
* Role-based APIs: `/user/*`

📄 Full endpoint list & admin actions:
➡️ [`backend/README.md`](backend/README.md)

### 🔧 Commands

```bash
make backend-start      # Start backend and worker
make backend-stop       # Stop backend and worker
make backend-restart    # Restart backend and worker
make backend-db-conn    # Check backend-db connection
```

### 🧪 Smoke tests

```bash
make test-signup        # Signup with .env credentials
make test-login         # Login with .env credentials
make test-auth          # Check authorizations
```

---

<a id="frontend"></a>

## 🎨 Frontend

Flutter web application with dedicated portals:

* 🌍 **Public**: matches, rankings, statistics
* 🧑‍💼 **Manager**: team & roster management
* 🧑‍⚖️ **Referee**: availability & assignments
* 🛠️ **Admin**: console, scheduler, role keys

### 📍 Main routes

* `/` — matches
* `/rankings` — rankings
* `/stats` — statistics
* `/rosters` — manager portal
* `/assignments`, `/availabilities` — referee portal
* `/admin/console`, `/admin/scheduler`, `/admin/role-keys` — admin portal

### ▶️ Run frontend

```bash
make flutter-setup
cd frontend
flutter run -d chrome
```

---

<a id="data_seed"></a>

## 🌱 Data Seeding (from backend docker terminal)

### Teams 

```bash
python -m helper.debug_teams --division <division> --teams <nb_of_teams> --players <nb_of_players>
```

### Matches (Can also be done in admin panel)

```bash
python -m helper.debug_matches --division <division> --count <nb_of_matches> --status <status_of_matches>
```
> 📌 status : in_progress, scheduled, canceled, postponed, finished, tbd

---

<a id="release"></a>

## 🚀 Release

### 🛠️ Prepare the host (backend + proxy)

* Build the web app: `make frontend-build-web`
* Start backend + proxy: `make backend-start`
* Open port 80: `make open-port-80` (run as admin)
* Verify: `http://<HOST_IP>/api/health` must return `{status: "ok"}`

### 📦 Build web
```bash
cd frontend
flutter build web
```

### 🌐 Web access

* Open `http://<HOST_IP>/` in the browser
* The API is accessed through the proxy via `/api` (same origin)

### 📦 Android build

```bash
cd frontend
flutter build apk --release
```

* Generated APK: `app-release.apk`

### 🤖 Android access

* Enter the host URL in the network portal: `http://<HOST_IP>`
  (`/api` is added automatically)
* If needed, verify `http://<HOST_IP>/api/health` from the phone’s browser

### 📡 Network notes

* Clients must be on the same network as the host
* The backend is exposed through the proxy on port 80
  (single URL for both web and mobile app)
* To close port 80: `make close-port-80` (run as admin)


---


<a id="documentation"></a>

## 📖 Documentation

* 📘 User guide: [`documents/User_Guide.md`](documents/User_Guide.md)
* 🏗️ Architecture & data model: [`documents/Architecture_Data.md`](documents/Architecture_Data.md)
* 🧪 Testing strategy: [`documents/Testing.md`](documents/Testing.md)
* 🗃️ SQL samples: [`documents/sql/`](documents/sql/)


