.PHONY: db-start db-stop db-reset db-migrate db-status db-remove-all flutter-setup

# Database management
db-start:
	docker compose up -d db

db-stop:
	docker compose down db flyway

db-remove-all:
	docker compose down -v --rmi all --remove-orphans

db-migrate:
	docker compose run --rm flyway

db-restart:
	db-stop
	db-start
	db-migrate

db-reset:
	docker compose down -v db flyway
	docker compose up -d db
	docker compose run --rm flyway

db-status:
	@powershell -NoLogo -NoProfile -Command \
	"Write-Host 'Checking Flyway migration status...';" \
	"docker compose run --rm flyway info | Tee-Object -FilePath .flyway_info.tmp | Out-Null;" \
	"if (Select-String -Path .flyway_info.tmp -Pattern 'Pending') { Write-Host 'Pending migrations detected. Run: make db-migrate'; Remove-Item .flyway_info.tmp; exit 1 } else { Write-Host 'Database schema is up to date.'; Remove-Item .flyway_info.tmp }"

# Backend management
backend-start:
	docker compose up -d --build backend

backend-stop:
	docker compose down backend

backend-restart: 
	backend-stop 
	backend-start

backend-db-conn:
	curl http://localhost:8000/health

# Flutter setup
flutter-setup:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter-setup.ps1
