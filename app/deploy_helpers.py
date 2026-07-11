import re

ECR_REPOSITORY = "cicd-demo"
APP_NAME = "CI/CD Demo API"
APP_PORT = "8000"
VALID_ENVIRONMENTS = frozenset({"staging", "production"})

IMAGE_TAG_PATTERN = re.compile(r"^[a-zA-Z0-9._-]+$")


def validate_image_tag(tag: str) -> str:
    if not tag or not tag.strip():
        raise ValueError("Image tag cannot be empty")

    normalized = tag.strip()
    if not IMAGE_TAG_PATTERN.match(normalized):
        raise ValueError(f"Invalid image tag: {normalized}")

    return normalized


def validate_environment(environment: str) -> str:
    if environment not in VALID_ENVIRONMENTS:
        raise ValueError(f"Invalid environment: {environment}")

    return environment


def build_image_uri(
    account_id: str,
    region: str,
    repository: str,
    tag: str,
) -> str:
    normalized_tag = validate_image_tag(tag)
    return f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repository}:{normalized_tag}"


def build_source_configuration(
    image_uri: str,
    app_env: str,
    app_version: str,
    access_role_arn: str,
) -> dict:
    validate_environment(app_env)

    return {
        "ImageRepository": {
            "ImageIdentifier": image_uri,
            "ImageRepositoryType": "ECR",
            "ImageConfiguration": {
                "Port": APP_PORT,
                "RuntimeEnvironmentVariables": {
                    "APP_ENV": app_env,
                    "APP_NAME": APP_NAME,
                    "APP_VERSION": app_version,
                },
            },
        },
        "AuthenticationConfiguration": {
            "AccessRoleArn": access_role_arn,
        },
        "AutoDeploymentsEnabled": False,
    }
