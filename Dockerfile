FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

COPY missing-folder ./app

ENV APP_NAME="CI/CD Demo API"
ENV APP_ENV="local"
ENV APP_VERSION="1.0.0"

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]