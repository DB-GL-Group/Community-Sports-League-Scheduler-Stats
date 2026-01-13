# Testing How-To

## Automated tests

This repo currently has no dedicated automated test suite wired into CI.

## Available smoke tests

There are Makefile targets for quick API checks:

```bash
make test-signup
make test-login
make test-auth
```

These use the following environment variables (optional):
- TEST_EMAIL
- TEST_PASSWORD
- TEST_FIRST_NAME
- TEST_LAST_NAME

Example:
```bash
$env:TEST_EMAIL='test.user@example.com'
$env:TEST_PASSWORD='test123'
make test-auth
```

## Test data setup

Use the helper scripts to seed data:

```bash
python backend/helper/players.py
python backend/helper/debug_matches.py --division 1 --count 5 --status in_progress
```

If you change DB structure, reset the DB:
```bash
make db-reset
```
