.PHONY: db-start db-stop db-reset db-migrate db-status

db-start:
	docker compose up -d db

db-stop:
	docker compose down

db-remove-all:
	docker compose down -v --rmi all --remove-orphans

db-migrate:
	docker compose run --rm flyway

db-reset:
	docker compose down -v
	docker compose up -d db
	docker compose run --rm flyway

db-status:
	@echo "🔎 Checking Flyway migration status..."
	@docker compose run --rm flyway info > .flyway_info.tmp
	@if grep -q "Pending" .flyway_info.tmp; then \
		echo "❌ Pending migrations detected. Run: make db-migrate"; \
		rm .flyway_info.tmp; \
		exit 1; \
	else \
		echo "✅ Database schema is up to date."; \
		rm .flyway_info.tmp; \
	fi