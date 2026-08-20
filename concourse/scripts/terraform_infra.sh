#!/bin/sh
set -eu

domain=$(echo "$secrets" | jq -r .domain)
service_subdomain=$(echo "$secrets" | jq -r .service_subdomain)
ecr_repository=$(echo "$secrets" | jq -r .ecr_repository)
azure_secret_name=$(echo "$secrets" | jq -r .azure_secret_name)
aws_account_name=$(echo "$secrets" | jq -r .aws_account_name)
branch_name=$branch

git config --global url."https://x-access-token:$github_access_token@github.com/".insteadOf "https://github.com/"

if [[ ${env} != "prod" ]]; then
    env="dev"
fi

cd resource-repo/terraform/storage

terraform init -backend-config=env/${env}/backend-${env}.tfbackend -reconfigure
terraform apply \
-var "domain=$domain" \
-auto-approve

cd ../lambda

terraform init -backend-config=env/${env}/backend-${env}.tfbackend -reconfigure
terraform apply \
-var "domain=$domain" \
-var "service_subdomain=$service_subdomain" \
-var "container_ver=${tag}" \
-var "ecr_repository=$ecr_repository" \
-var "azure_secret_name=$azure_secret_name" \
-var "branch_name=$branch_name" \
-var "aws_account_name=$aws_account_name" \
-auto-approve

cd ../api_gateway

terraform init -backend-config=env/${env}/backend-${env}.tfbackend -reconfigure
terraform apply \
-var "domain=$domain" \
-auto-approve
