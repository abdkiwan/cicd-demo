import json

import pytest

from app.deploy_helpers import (
    build_image_uri,
    build_source_configuration,
    validate_environment,
    validate_image_tag,
)


def test_validate_image_tag_accepts_common_tags():
    assert validate_image_tag("abc123") == "abc123"
    assert validate_image_tag("  v1.2.3  ") == "v1.2.3"
    assert validate_image_tag("feature_branch-1.0") == "feature_branch-1.0"


@pytest.mark.parametrize(
    "tag",
    ["", "   ", "tag with spaces", "tag/slash", "tag:colon"],
)
def test_validate_image_tag_rejects_invalid_values(tag):
    with pytest.raises(ValueError):
        validate_image_tag(tag)


def test_validate_environment_accepts_staging_and_production():
    assert validate_environment("staging") == "staging"
    assert validate_environment("production") == "production"


def test_validate_environment_rejects_unknown_values():
    with pytest.raises(ValueError, match="Invalid environment"):
        validate_environment("development")


def test_build_image_uri_formats_ecr_uri():
    uri = build_image_uri(
        account_id="123456789012",
        region="eu-central-1",
        repository="cicd-demo",
        tag="abc123",
    )

    assert uri == "123456789012.dkr.ecr.eu-central-1.amazonaws.com/cicd-demo:abc123"


def test_build_source_configuration_matches_apprunner_contract():
    config = build_source_configuration(
        image_uri="123456789012.dkr.ecr.eu-central-1.amazonaws.com/cicd-demo:abc123",
        app_env="staging",
        app_version="abc123",
        access_role_arn="arn:aws:iam::123456789012:role/access-role",
    )

    assert config["ImageRepository"]["ImageIdentifier"].endswith(":abc123")
    assert config["ImageRepository"]["ImageConfiguration"]["Port"] == "8000"
    assert (
        config["ImageRepository"]["ImageConfiguration"]["RuntimeEnvironmentVariables"][
            "APP_ENV"
        ]
        == "staging"
    )
    assert config["AuthenticationConfiguration"]["AccessRoleArn"].endswith(
        "access-role"
    )
    assert config["AutoDeploymentsEnabled"] is False


def test_build_source_configuration_is_json_serializable():
    config = build_source_configuration(
        image_uri="123456789012.dkr.ecr.eu-central-1.amazonaws.com/cicd-demo:abc123",
        app_env="production",
        app_version="abc123",
        access_role_arn="arn:aws:iam::123456789012:role/access-role",
    )

    serialized = json.dumps(config)
    assert "production" in serialized
