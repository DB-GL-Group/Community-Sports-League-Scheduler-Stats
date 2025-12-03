# Community Sports League – Dev Environment

## Prérequis

- Docker + Docker Compose
- Git

## Setup

### Cloner le dépôt 
```bash
git clone https://github.com/DB-GL-Group/Community-Sports-League-Scheduler-Stats.git
cd Community-Sports-League-Scheduler-Stats
```

### Lancer la base de données PostgreSQL
```bash
cp .env.example .env # Modifier les variables si besoin
docker compose up -d --build
```


## Accès à la base de données
La base de données PostgreSQL sera accessible sur le port défini dans le fichier `.env` (par défaut `5432`). \
Utilise un client PostgreSQL (comme `psql`, DBeaver, ou Beekeeper studio) pour te connecter avec les informations d'identification définies dans le fichier `.env`. 

### Exemple avec `psql` :

```bash
docker exec -it sports-league-db psql -U <user> -d sports_league 
```

### Exemple avec `Beekeeper Studio` :
- Host: `localhost`
- Port: `5432` (ou celui défini dans `.env`)
- User: `<user>` (défini dans `.env`)
- Password: `<password>` (défini dans `.env`)
- Database: `sports_league` (défini dans `.env`)

## Modifier la base de données
Toute modification de la structure doit être ajoutée dans un fichier SQL dans le dossier `db/init/`. \
Au démarrage du conteneur, tous les scripts SQL dans ce dossier seront exécutés automatiquement pour initialiser la base de données. \
Depuis Beekeeper Studio, il s'agit des queries éxécutées.
