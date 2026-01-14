.PHONY: db-start db-stop db-reset db-migrate db-status db-remove-all flutter-setup backend-start backend-stop backend-restart backend-reset open-port-80 close-port-80 frontend-build-web

ifeq ($(OS),Windows_NT)
BACKEND_START_CMD = powershell -NoProfile -ExecutionPolicy Bypass -File scripts/backend-start.ps1
else
BACKEND_START_CMD = bash scripts/backend-start.sh
endif

# Database management
db-start:
	docker compose up -d db

db-stop:
	docker compose down db flyway

db-remove:
	docker compose down -v db flyway

db-migrate:
	docker compose run --rm flyway

db-restart:
	$(MAKE) db-stop
	$(MAKE) db-start
	$(MAKE) db-migrate

db-reset:
	$(MAKE) db-remove
	$(MAKE) db-start
	$(MAKE) db-migrate

db-status:
	@powershell -NoLogo -NoProfile -Command \
	"Write-Host 'Checking Flyway migration status...';" \
	"docker compose run --rm flyway info | Tee-Object -FilePath .flyway_info.tmp | Out-Null;" \
	"if (Select-String -Path .flyway_info.tmp -Pattern 'Pending') { Write-Host 'Pending migrations detected. Run: make db-migrate'; Remove-Item .flyway_info.tmp; exit 1 } else { Write-Host 'Database schema is up to date.'; Remove-Item .flyway_info.tmp }"

# Backend management
backend-start:
	$(BACKEND_START_CMD)
	docker compose up -d proxy

backend-stop:
	docker compose down backend redis worker proxy

backend-remove:
	docker compose down backend redis worker proxy --remove-orphans --rmi local


backend-restart:
	$(MAKE) backend-stop
	$(MAKE) backend-start

backend-reset:
	$(MAKE) backend-remove
	$(MAKE) backend-start

backend-db-conn:
	curl http://localhost:8000/health

open-port-80:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/open-port-80.ps1
else
	bash scripts/open-port-80.sh
endif

close-port-80:
ifeq ($(OS),Windows_NT)
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/close-port-80.ps1
else
	bash scripts/close-port-80.sh
endif

# Flutter setup
flutter-setup:
	@OS=$$(uname -s); \
	if [ "$$OS" = "Darwin" ]; then \
		bash scripts/flutter-setup.sh; \
	else \
		if command -v pwsh >/dev/null 2>&1; then \
			pwsh -NoProfile -File scripts/flutter-setup.ps1; \
		else \
			powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter-setup.ps1; \
		fi; \
	fi

frontend-build-web:
	cd frontend && flutter build web

# Some test requests
test-signup:
	powershell -NoProfile -Command "$$email = $$env:TEST_EMAIL; if (-not $$email) { $$email = 'test.user@example.com' }; $$password = $$env:TEST_PASSWORD; if (-not $$password) { $$password = 'test123' }; $$first = $$env:TEST_FIRST_NAME; if (-not $$first) { $$first = 'Test' }; $$last = $$env:TEST_LAST_NAME; if (-not $$last) { $$last = 'User' }; $$body = @{ first_name = $$first; last_name = $$last; email = $$email; password = $$password; roles = @('FAN') } | ConvertTo-Json; Invoke-RestMethod -Method Post -Uri http://localhost:8000/auth/signup -ContentType 'application/json' -Body $$body | ConvertTo-Json -Depth 5"

test-login:
	powershell -NoProfile -Command "$$email = $$env:TEST_EMAIL; if (-not $$email) { $$email = 'test.user@example.com' }; $$password = $$env:TEST_PASSWORD; if (-not $$password) { $$password = 'test123' }; $$body = @{ email = $$email; password = $$password } | ConvertTo-Json; Invoke-RestMethod -Method Post -Uri http://localhost:8000/auth/login -ContentType 'application/json' -Body $$body | ConvertTo-Json -Depth 5"

test-auth:
	powershell -NoProfile -Command "$$email = $$env:TEST_EMAIL; if (-not $$email) { $$email = 'test.user@example.com' }; $$password = $$env:TEST_PASSWORD; if (-not $$password) { $$password = 'test123' }; $$body = @{ email = $$email; password = $$password } | ConvertTo-Json; $$login = Invoke-RestMethod -Method Post -Uri http://localhost:8000/auth/login -ContentType 'application/json' -Body $$body; $$token = $$login.access_token; Invoke-RestMethod -Method Get -Uri http://localhost:8000/auth/me -Headers @{ Authorization = \"Bearer $$token\" } | ConvertTo-Json -Depth 5"
