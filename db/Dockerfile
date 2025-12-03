FROM postgres:18

# Values default, overridden by docker-compose if .env defined
ENV POSTGRES_DB=sports_league
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

# Init SQL scripts (run only on first startup)
COPY init /docker-entrypoint-initdb.d/
