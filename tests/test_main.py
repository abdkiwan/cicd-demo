from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check_returns_ok():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_version_endpoint_contains_environment():
    response = client.get("/version")

    assert response.status_code == 200
    body = response.json()

    assert "app" in body
    assert "environment" in body
    assert "version" in body