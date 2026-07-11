from fastapi import FastAPI

from app.settings import APP_ENV, APP_NAME, APP_VERSION

app = FastAPI(title=APP_NAME)


@app.get("/")
def root():
    return {
        "message": f"Hello from {APP_NAME} - live from the CI/CD sessio.",
        "environment": APP_ENV,
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
    }


@app.get("/version")
def version():
    return {
        "app": APP_NAME,
        "environment": APP_ENV,
        "version": APP_VERSION,
    }
