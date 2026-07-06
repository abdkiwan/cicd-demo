import os

APP_NAME = os.getenv("APP_NAME", "CI/CD Demo API")
APP_ENV = os.getenv("APP_ENV", "local")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")