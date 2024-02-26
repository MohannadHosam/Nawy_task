# Simple Web Application with CI/CD Pipeline and Terraform Deployment

## Overview

This repository contains a basic "Hello Node" web application in Node.js. The application is containerized using Docker, and a CI/CD pipeline is set up using GitHub Actions. The deployment is managed using Terraform.

## Table of Contents

- [Application Setup](#application-setup)
- [Containerization](#containerization)
- [CI/CD Pipeline with GitHub Actions](#cicd-pipeline-with-github-actions)
- [Deployment with Terraform](#deployment-with-terraform)
  - [Local Deployment (Docker)](#local-deployment-docker)
  - [Cloud Deployment](#cloud-deployment)

## Application Setup

1. Fork this repository to my GitHub account.

2. Clone the forked repository to your local machine.

    ```bash
    git clone https://github.com/your-username/simple-web-app.git
    cd simple-web-app
    ```

3. Install the required dependencies for the Node.js application.

    ```bash
    npm install
    ```    ```

## Containerization

The application is containerized using Docker. To create the Docker image, follow these steps:

1. Create a Dockerfile in the root of the project.

    ```Dockerfile
    # syntax=docker/dockerfile:1
    
    ARG NODE_VERSION=18.0.0
    
    FROM node:${NODE_VERSION}-alpine

    ENV NODE_ENV production
    
    WORKDIR /usr/src/app
    
    # Download dependencies as a separate step to take advantage of Docker's caching.
    # Leverage a cache mount to /root/.npm to speed up subsequent builds.
    # Leverage a bind mounts to package.json and package-lock.json to avoid having to copy them into
    # into this layer.
    RUN --mount=type=bind,source=package.json,target=package.json \
        --mount=type=bind,source=package-lock.json,target=package-lock.json \
        --mount=type=cache,target=/root/.npm \
        npm ci --omit=dev
    
    # Run the application as a non-root user.
    USER node
    
    # Copy the rest of the source files into the image.
    COPY . .
    
    # Expose the port that the application listens on.
    EXPOSE 3000
    
    # Run the application.
    CMD npm start
    ```

2. Build the Docker image (for example, choose any name for the tagging part).

    ```bash
    docker build -t simple-web-app .
    ```

## CI/CD Pipeline with GitHub Actions

The CI/CD pipeline is configured using GitHub Actions. It includes linting, building the Docker container, and pushing the container to Docker Hub.

1. Navigate to the "Actions" tab in your GitHub repository.

2. Click on the "Set up a workflow yourself" option.

3. Copy and paste the content of `.github/workflows/Lint.yml` &`.github/workflows/builderdocke.yml`  from this repository into your new workflow file.

4. Commit and push the changes to trigger the GitHub Actions pipeline.

## Deployment with Terraform

The deployment is managed using Terraform. You can choose to deploy the container locally using the Docker provider or use any cloud provider offering a free tier.

### Local Deployment (Docker)

Ensure you have Docker installed on your machine.

1. Run the Docker container locally.

    ```bash
    docker run -p 3000:3000 simple-web-app
    ```

2. Access the application in your browser at http://localhost:3000.

### Cloud Deployment

Follow the instructions in the Terraform configuration files to deploy the application on a container orchestration platform of your choice (e.g., ECS, Kubernetes).

```bash
cd terraform
terraform init
terraform apply
```

## Table of Contents of new Relic

- [1. Create a New Relic Account](#1-create-a-new-relic-account)
- [2. Obtain License Key](#2-obtain-license-key)
- [3. Install New Relic Node.js Agent](#3-install-new-relic-nodejs-agent)
- [4. Configure newrelic.js](#4-configure-newrelicjs)
- [5. Update npm start Script](#5-update-npm-start-script)
- [6. Verify Integration](#6-verify-integration)

## 1. Create a New Relic Account

If you don't have a New Relic account, sign up for a free account on the [New Relic website](https://newrelic.com/).

## 2. Obtain License Key

After creating the account, obtain the New Relic license key from the New Relic One platform.

## 3. Install New Relic Node.js Agent

Install the New Relic Node.js agent as a dependency:

```bash
npm install newrelic
```

## Then configure the newRelic in the "newrelic.js" file
## Then Update the "start" script in your package.json
## Run the application and verify that it's sending data to New Relic using "npm start"
