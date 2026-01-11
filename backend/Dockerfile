FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir fastapi  "uvicorn[standard]" \
                                        "psycopg[binary]" \
                                        "psycopg_pool[binary]" \
                                        "pydantic[email]" \
                                        "passlib[argon2]" \
                                        "PyJWT" \
                                        "rq" \
                                        "redis"

COPY . /app

CMD ["uvicorn", "api.app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
