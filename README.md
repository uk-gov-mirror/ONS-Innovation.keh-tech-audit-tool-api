
# Tech Audit Tool - API

A Flask and flask-restx API for the tech audit tool.

This service is a dependency for the [Tech Audit Tool UI](https://github.com/ONS-Innovation/keh-tech-audit-tool) which **must** be deployed first due to using the UI's Terraform state to control API access.

## Contents

- [Tech Audit Tool - API](#tech-audit-tool---api)
  - [Contents](#contents)
  - [Setting up \& Running Locally](#setting-up--running-locally)
  - [Testing](#testing)
  - [Testing with Postman](#testing-with-postman)
  - [MkDocs Documentation](#mkdocs-documentation)
    - [Running the MkDocs locally](#running-the-mkdocs-locally)
    - [Deploying the MkDocs](#deploying-the-mkdocs)
      - [Deployment GitHub Action](#deployment-github-action)
      - [Manual Deployment](#manual-deployment)
  - [API Reference](#api-reference)
    - [Get user email](#get-user-email)
    - [Get new ID token from refresh token](#get-new-id-token-from-refresh-token)
    - [Get all user projects](#get-all-user-projects)
    - [Get a specific user project](#get-a-specific-user-project)
    - [Create a new project](#create-a-new-project)
    - [Get autocomplete from string \[REMOVED\]](#get-autocomplete-from-string-removed)
    - [Get filtered projects](#get-filtered-projects)
    - [Edit a project](#edit-a-project)
  - [Authorization with Cognito and API Gateway](#authorization-with-cognito-and-api-gateway)
    - [Deployment with Concourse](#deployment-with-concourse)
      - [Allowlisting your IP](#allowlisting-your-ip)
      - [Setting up a pipeline](#setting-up-a-pipeline)
      - [Prod deployment](#prod-deployment)
      - [Triggering a pipeline](#triggering-a-pipeline)
      - [Destroying a pipeline](#destroying-a-pipeline)


## Setting up & Running Locally

Clone the project

```bash
git clone https://github.com/ONS-Innovation/keh-tech-audit-tool-api.git
```

Install dependencies

```bash
make install
```

Install dev dependencies to run linting tools

```bash
make install-dev
```

Sign in with AWS SSO, and export the correct profile for this service:

```bash
aws sso login

export AWS_PROFILE=keh-tech-audit-tool-api
```

This allows you to assume the AWS IAM role for the service, enabling the most secure development experience. This also means you will have limited permissions until you exit out of the profile.

**Note:** See the Developer Onboarding Guide on the "Using AWS SSO for Local Development" page on Confluence to set up service profile selection on your local machine.

Set environment variables:

```bash
export TECH_AUDIT_DATA_BUCKET='<sdp-dev-tech-audit-tool-api-testing/sdp-dev-tech-audit-tool-api>' # The latter bucket should be used in production
export TECH_AUDIT_SECRET_MANAGER='sdp-dev-tech-audit-tool-api/secrets'
export AWS_COGNITO_TOKEN_URL='https://tech-audit-tool-api-sdp-dev.auth.eu-west-2.amazoncognito.com/oauth2/token'
export AWS_DEFAULT_REGION='eu-west-2'
export REDIRECT_URI='http://localhost:8000'
```

Go to the aws_lambda_script directory

```bash
cd aws_lambda_script
```

Run the project locally (with UI)
```bash
make run-local
```
or
```bash
poetry run flask --app app run --port=5000
```
This will run the API on port 5000, to which the UI can now access

Run the project locally (without UI)
```bash
make run-no-ui
```
or
```bash
poetry run flask --app app run --port=8000
```

## Testing

This repo utilises PyTest for the testing. Please make sure you have installed dev dependencies before running tests.

Local tests now mock AWS Secrets Manager, Cognito settings and Teams alert configuration in `testing/conftest.py`, so a real AWS session or Cognito token is not required for `pytest`.

If you want to override the default mocked user in tests, set:

```bash
export MOCK_USER_EMAIL=<email>
```

`MOCK_TOKEN` is optional for local tests and defaults to `local-test-token`.

Make sure dev dependencies are installed:
```bash
make install-dev
```

When in root directory, run the testing command. If you are in `aws_lambda_script` it will fail.
```bash
make pytest
```

Once you have finished testing, clean the temp files with:
```bash
make clean
```

## Testing with Postman

View the Postman workspace for this project [here](https://www.postman.com/science-pilot-55892832/workspace/keh-tech-audit-tool-api/collection/38871441-e42f661e-6430-4f46-8182-083e9e0fd4ad?action=share&creator=38871441&active-environment=38871441-7c5e3795-74f5-46b3-9034-637561aba746).

Please read the description or README to understand how to use this workspace. Postman requests still require a real Cognito ID token in the `Authorization` header.

## MkDocs Documentation

### Running the MkDocs locally

To install the dependencies for the MkDocs, run the following command:

```bash
make install-docs
```

Then run the following command to run the MkDocs:

```bash
make mkdocs
```

### Deploying the MkDocs

#### Deployment GitHub Action

The MkDocs documentation is automatically deployed to the `gh-pages` branch of the repository using a GitHub Action. The action is triggered on every push to the `main` branch. This action is defined within `./.github/workflows/deploy_mkdocs.yml`.

#### Manual Deployment

Deploying the MkDocs is done by running the following command:

```bash
make mkdocs-deploy
```

This will build the MkDocs documentation and deploy it to the `gh-pages` branch of the repository. The documentation will be available at [https://ons-innovation.github.io/keh-tech-audit-tool-api](https://ons-innovation.github.io/keh-tech-audit-tool-api).

## API Reference

Before calling the API manually, use a valid Cognito ID token in the `Authorization` header. Local `pytest` runs mock authentication automatically.

| Header | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `Authorization` | `string` | **Required**. ID Token (Not access) |
 
### Get user email

```http
GET /api/v1/user
```

Get's the users email.

### Get new ID token from refresh token

```http
POST /api/v1/refresh
```

| Body | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `refresh_token`      | `string` | **Required**. The refresh token |

Get's a new id_token from a refresh token. Old id_token is killed, refresh_token
can be used multiple times to get a new id_token.

### Get all user projects

```http
GET /api/v1/projects
```

Gets all projects currently stored by the API.

### Get a specific user project

```http
GET /api/v1/projects/<project_name>
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `<project_name>`      | `string` | **Required**. The project you want to get |


Gets a specific project by name.

### Create a new project

```http
POST /api/v1/projects/
```

Send JSON in this format:
```JSON
{
    "user": [
      {
        "email": "Email",
        "roles": ["Technical Contact"],
        "grade": "Grade"
      },
      {
        "email": "Email",
        "roles": ["Delivery Manager Contact"],
        "grade": "Grade"
      }
    ],
    "details":[ 
      {
        "name": "Name",
        "short_name": "Short Name",
        "documentation_link": ["List of strings"],
        "project_description": "Description"
      }]
    ,
    "developed": ["In-house"],
    "source_control": [
      {
        "type": "GitHub",
        "links": [
          {
            "description": "Description",
            "url": "URL"
          }
        ]
      }
    ],
    "architecture": {
      "hosting": {
        "type": ["Hybrid"],
        "details": ["List of strings"]
      },
      "database": {
        "main": [],
        "others": ["List of strings"]
      },
      "languages": {
        "main": ["List of strings"],
        "others": ["List of strings"]
      },
      "frameworks": {
        "main": [],
        "others": ["List of strings"]
      },
      "cicd": {
        "main": [],
        "others": ["List of strings"]
      },
      "environments": {
        "dev": "Boolean",
        "int": "Boolean",
        "uat": "Boolean",
        "preprod": "Boolean",
        "prod": "Boolean",
        "postprod": "Boolean",
      },
      "infrastructure": {
        "main": [],
        "others": ["List of strings"]
      },
      "publishing": {
        "main": [],
        "others": ["List of strings"]
      }
    },
    "stage":"Development",
    "supporting_tools": {
          "code_editors": {
            "main": [],
            "others": [
              "List of strings"
              ]
          },
          "user_interface": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "diagrams": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "project_tracking": "string",
          "documentation": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "communication": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "collaboration": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "incident_management": "string",
          "miscellaneous": []
        }
  }
```
Creates a project. If the languages, database, frameworks, cicd, infrastructure or source control is not in the `array_data.json` bucket, then it is added.


### Get autocomplete from string [REMOVED]

```http
GET /api/v1/autocomplete
```
Removed as autocomplete is processed on front-end.


### Get filtered projects 

```http
GET /api/v1/projects/filter
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `<filter>`      | `string` | **Required**. The specific filter. Multiple filter seperated by a comma (,) |
| `<return>`      | `string` | What you want returned from the project. Multiple return filter seperated by a comma (,) |


Gets projects using one or more query filters.

Filter can be one or more of: email, roles, name, developed, source_control, hosting, database, languages, frameworks, cicd, environments, infrastructure, publishing.

Return can be one or more of: user, details, developed, source_control, architecture.


### Edit a project

```http
PUT /api/v1/projects/{project_name}
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `<project_name>`      | `string` | **Required**. The project you want to get |


Send JSON in this format:
```JSON
{
    "user": [
      {
        "email": "Email",
        "roles": ["Technical Contact"],
        "grade": "Grade"
      },
      {
        "email": "Email",
        "roles": ["Delivery Manager Contact"],
        "grade": "Grade"
      }
    ],
    "details":[ 
      {
        "name": "Name",
        "short_name": "Short Name",
        "documentation_link": ["List of strings"],
        "project_description": "Description"
      }]
    ,
    "developed": ["In-house"],
    "source_control": [
      {
        "type": "GitHub",
        "links": [
          {
            "description": "Description",
            "url": "URL"
          }
        ]
      }
    ],
    "architecture": {
      "hosting": {
        "type": ["Hybrid"],
        "details": ["List of strings"]
      },
      "database": {
        "main": [],
        "others": ["List of strings"]
      },
      "languages": {
        "main": ["List of strings"],
        "others": ["List of strings"]
      },
      "frameworks": {
        "main": [],
        "others": ["List of strings"]
      },
      "cicd": {
        "main": [],
        "others": ["List of strings"]
      },
      "environments": {
        "dev": "Boolean",
        "int": "Boolean",
        "uat": "Boolean",
        "preprod": "Boolean",
        "prod": "Boolean",
        "postprod": "Boolean",
      },
      "infrastructure": {
        "main": [],
        "others": ["List of strings"]
      },
      "publishing": {
        "main": [],
        "others": ["List of strings"]
      }
    },
    "stage":"Development",
    "supporting_tools": {
          "code_editors": {
            "main": [],
            "others": [
              "List of strings"
              ]
          },
          "user_interface": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "diagrams": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "project_tracking": "string",
          "documentation": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "communication": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "collaboration": {
            "main": [],
            "others": [
              "List of strings"
            ]
          },
          "incident_management": "string",
          "miscellaneous": []
        }
  }
```
Edits a project by checking if the languages, database, frameworks, cicd, environments, infrastructure, publishing or source control are missing from the `array_data.json` bucket. If any are missing, they are added.


## Authorization with Cognito and API Gateway

Visiting the Cognito UI and successfully logging in, will redirect you to:

```bash
/api/v1/verify?code=<code>
```

This returns your token, which you can use in testing the authentication on the API. Use this token in the Authorization header to authenticate your requests.

The /api/v1/verify route get's the client keys and redirect uri from the bucket.

### Deployment with Concourse

#### Allowlisting your IP

To setup the deployment pipeline with concourse, you must first allowlist your IP address on the Concourse server. IP addresses are flushed everyday at 00:00 so this must be done at the beginning of every working day whenever the deployment pipeline needs to be used.

Instructions on this are available within **KEH's Confluence Space**.

All pipelines run within the `sdp-pipeline-prod` AWS account, whereas `sdp-pipeline-dev` is the account used for testing changes to the Concourse instance itself (i.e. configuration changes, not pipeline changes).

#### Setting up a pipeline

Our pipelines use an IAM role within AWS to interact with our infrastructure.
Credentials/secrets for pipelines are stored within AWS Secrets Manager on the `sdp-pipeline-prod` account, so you do not need to set up anything yourself.

To set the pipeline, run the following script:

```bash
chmod u+x ./concourse/scripts/set_pipeline.sh
./concourse/scripts/set_pipeline.sh
```

**Note:** You only have to run `chmod` the first time running the script in order to give permissions.

This script will set the branch and pipeline name to whatever branch you are currently on.
It will also set the image tag on ECR to 7 characters of the current branch name if running on a branch other than `main`.
For `main`, the ECR tag will be the latest release tag on the repository that has semantic versioning(vX.Y.Z).

The pipeline name itself will usually follow a pattern as follows:

- `keh-tech-audit-tool-api-<branch-name>` for any non-main branch.
  - When following our branching strategy, pipelines are normally postfixed with the Jira ticket number, e.g. `keh-tech-audit-tool-api-KEH-1234`.
- `keh-tech-audit-tool-api` for the main/master branch.

#### Prod deployment

To deploy to prod, it is required that a Github Release is made on Github. The release is required to follow semantic versioning of vX.Y.Z.

A manual trigger is to be made on the pipeline name `keh-tech-audit-tool-api > deploy-after-github-release` job through the Concourse CI UI. This will create a resource that is required on the `keh-tech-audit-tool-api > release-build-and-push-prod` job. Then the prod deployment job is also through a manual trigger ensuring that prod is only deployed using the latest GitHub release tag in the form of vX.Y.Z and is manually controlled.

More information on our typical deployment patterns in Concourse can be found in our Confluence space.

#### Triggering a pipeline

Once the pipeline has been set, you can manually trigger a dev build on the Concourse UI, or run the following command for non-main branch deployment:

```bash
fly -t aws-sdp trigger-job -j keh-tech-audit-tool-api-<branch-name>/deploy-after-github-release-dev
```

and for main branch deployment:

```bash
fly -t aws-sdp trigger-job -j keh-tech-audit-tool-api/deploy-after-github-release-dev
```

#### Destroying a pipeline

To destroy the pipeline, run the following command:

```bash
fly -t aws-sdp destroy-pipeline -p keh-tech-audit-tool-api-<branch-name>
```

**It is unlikely that you will need to destroy a pipeline, but the command is here if needed.**

**Note:** This will not destroy any resources created by Terraform. You must manually destroy these resources using Terraform.

