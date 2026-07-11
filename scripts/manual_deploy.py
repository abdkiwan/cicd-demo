#!/usr/bin/env python3

import json
import os
import subprocess
import sys

from app.deploy_helpers import (
    build_image_uri,
    build_source_configuration,
    validate_environment,
    validate_image_tag,
)


def run_aws_command(args: list[str]) -> str:
    result = subprocess.run(
        ["aws", *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def main() -> int:
    environment = validate_environment(os.environ["ENVIRONMENT"])
    image_tag = validate_image_tag(os.environ["IMAGE_TAG"])
    service_arn = os.environ["SERVICE_ARN"]
    region = os.environ["AWS_REGION"]
    repository = os.environ["ECR_REPOSITORY"]

    account_id = run_aws_command(
        ["sts", "get-caller-identity", "--query", "Account", "--output", "text"]
    )
    image_uri = build_image_uri(account_id, region, repository, image_tag)

    access_role_arn = run_aws_command(
        [
            "apprunner",
            "describe-service",
            "--service-arn",
            service_arn,
            "--query",
            "Service.SourceConfiguration.AuthenticationConfiguration.AccessRoleArn",
            "--output",
            "text",
        ]
    )

    source_configuration = build_source_configuration(
        image_uri=image_uri,
        app_env=environment,
        app_version=image_tag,
        access_role_arn=access_role_arn,
    )

    print(f"Deploying {image_uri} to {environment}...")
    run_aws_command(
        [
            "apprunner",
            "update-service",
            "--service-arn",
            service_arn,
            "--source-configuration",
            json.dumps(source_configuration),
        ]
    )

    print(f"Successfully deployed {image_tag} to {environment}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
