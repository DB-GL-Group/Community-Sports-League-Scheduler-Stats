# 🐘 PostgreSQL — psql Cheat Sheet

> Les commandes `psql` commencent par une barre oblique inverse `\`.
> Elles ne se terminent **pas** par un point-virgule.

---

## 🔌 Connexion & gestion des bases

| Commande | Description |
|--------|--------------|
| `psql -U <user> -d <db>` | Se connecter à une base |
| `\l` | Lister toutes les bases |
| `\c <db>` | Se connecter à une autre base |
| `\conninfo` | Infos de connexion actuelle |
| `\q` | Quitter `psql |

---

## 📦 Tables, schémas & structure

| Commande | Description |
|---------|---------------|
| `\dt` | Lister les tables du schéma public |
| `\dt *.*` | Lister toutes les tables (tous schémas) |
| `\d <table>` | Description d'une table (colonnes, contraintes) |
| `\d+ <table>` | Détails + stockage + index |
| `\di` | Liste des index |
| `\dn` | Liste des schémas |
| `\df` | Liste des fonctions |
| `\du` | Liste des rôles (utilisateurs) |

---

## 🔎 Navigation & affichage

| Commande | Description |
|----------|----------------|
| `\x` | Mode affichage étendu (colonnes verticales) |
| `\pset border 2` | Bordures lisibles |
| `\timing on` | Affiche le temps d’exécution |
| `\! clear` | Efface l'écran (Linux/macOS) |

---

## 🔪 Requêtes utiles

```sql
SELECT NOW();
SELECT * FROM table LIMIT 5;
SELECT COUNT(*) FROM table;
```

---

## 📦 Maintenance

| Commande | Description |
|----------|----------------|
| `TRUNCATE table;` | Vide la table **sans logs** |
| `VACUUM ANALYZE;` | Optimisation de la base |
| `SHOW search_path;` | Voir les schémas utilisés |

---

## 🔑 Import / Export

| Commande | Description |
|---------|---------------|
| `\i script.sql` | Exécute un fichier SQL |
| `\copy table TO 'file.csv' CSV HEADER` | Export CSV |
| `\copy table FROM 'file.csv' CSV` | Import CSV |

Exemple :

```sql
\copy teams TO '/tmp/teams.csv' CSV HEADER;
```

---

## 📌 Consultation système

| Commande | Description |
|---------|---------------|
| `SELECT * FROM pg_stat_activity;` | Voir les connexions |
| `SELECT version();` | Version PostgreSQL|
| `SELECT * FROM pg_tables;` | Liste toutes les tables visibles |
| `\set VERBOSITY verbose` | Logs détaillés déerreurs |

---

### 🌯 Les indispensables à connaîre

| Commande | Usage |
|---------|-------|
| `\dt` | Voir les tables |
| `\d table` | Comprendre une table |
| `\x` | Lire les données facilement |
| `\c db` | Changer de base |
| `\q` | Quitter |

---

## 🚀 Tip DevOps

Pour activer automatiquement le mode lisible :

```bash
echo '\pset border 2' >> ~/.psqlrc
echo '\x auto' >> ~/.psqlrc
```

---

🧀 **Astuce**: Les commandes psql n'utilisent **pas** de `;`, tandis que les requêtes SQL **doivent** en avoir un.

