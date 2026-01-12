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
	docker compose up -d --build backend worker

backend-stop:
	docker compose down backend redis worker

backend-restart: 
	backend-stop 
	backend-start

backend-reset:
	docker compose down -v backend redis worker
	docker compose up -d --build backend worker

backend-db-conn:
	curl http://localhost:8000/health

# Flutter setup
flutter-setup:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter-setup.ps1

# Some test requests
test-signup:
	powershell -NoProfile -Command "$$email = $$env:TEST_EMAIL; if (-not $$email) { $$email = 'test.user@example.com' }; $$password = $$env:TEST_PASSWORD; if (-not $$password) { $$password = 'test123' }; $$first = $$env:TEST_FIRST_NAME; if (-not $$first) { $$first = 'Test' }; $$last = $$env:TEST_LAST_NAME; if (-not $$last) { $$last = 'User' }; $$body = @{ first_name = $$first; last_name = $$last; email = $$email; password = $$password; roles = @('FAN') } | ConvertTo-Json; Invoke-RestMethod -Method Post -Uri http://localhost:8000/auth/signup -ContentType 'application/json' -Body $$body | ConvertTo-Json -Depth 5"

test-login:
	powershell -NoProfile -Command "$$email = $$env:TEST_EMAIL; if (-not $$email) { $$email = 'test.user@example.com' }; $$password = $$env:TEST_PASSWORD; if (-not $$password) { $$password = 'test123' }; $$body = @{ email = $$email; password = $$password } | ConvertTo-Json; Invoke-RestMethod -Method Post -Uri http://localhost:8000/auth/login -ContentType 'application/json' -Body $$body | ConvertTo-Json -Depth 5"

test-auth:
	powershell -NoProfile -Command "$$email = $$env:TEST_EMAIL; if (-not $$email) { $$email = 'test.user@example.com' }; $$password = $$env:TEST_PASSWORD; if (-not $$password) { $$password = 'test123' }; $$body = @{ email = $$email; password = $$password } | ConvertTo-Json; $$login = Invoke-RestMethod -Method Post -Uri http://localhost:8000/auth/login -ContentType 'application/json' -Body $$body; $$token = $$login.access_token; Invoke-RestMethod -Method Get -Uri http://localhost:8000/auth/me -Headers @{ Authorization = \"Bearer $$token\" } | ConvertTo-Json -Depth 5"
