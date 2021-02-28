#!/bin/bash

# EDIT THESE TO YOUR VALUES
export PROJECT_ID=""
export BILLING_ID="" # Get it at: https://console.cloud.google.com/billing (or in step below)
export LOCATION="europe-north1"

# Repo and Cloud Run service
export REPO_NAME="frontend-logs"
export RUN_SERVICE_NAME="frontend-logs"
export DESCRIPTION="Frontend log collection"
export IMAGE="log-collector"

# Service account
export SERVICE_ACCOUNT_NAME="log-collector-sa"
export DISPLAY_NAME="Cloud Run log collector user"

# Update
gcloud components update

# Create new project and set as current
gcloud projects create $PROJECT_ID
gcloud config set project $PROJECT_ID

# Get project number
gcloud projects list
export PROJECT_NUMBER="" # From above

# Enable billing
gcloud services enable cloudbilling.googleapis.com
gcloud alpha billing accounts list
gcloud alpha billing projects link $PROJECT_ID --billing-account $BILLING_ID

# Enable Google APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sourcerepo.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable clouderrorreporting.googleapis.com

# Create Source Repository
gcloud source repos create $REPO_NAME

# Create Artifact Registry for image
gcloud beta artifacts repositories create $REPO_NAME \
  --repository-format="docker" \
  --location=$LOCATION \
  --description="$DESCRIPTION" \
  --async

# Create a build trigger, working on the master branch
gcloud beta builds triggers create cloud-source-repositories \
  --repo $REPO_NAME \
  --branch-pattern "master" \
  --build-config "cloudbuild.yaml"

# Set permissions for Cloud Build
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/logging.viewer

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/run.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/iam.serviceAccountUser

# Create service account for Cloud Run user
gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
  --display-name ${DISPLAY_NAME}

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/run.invoker

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/errorreporting.writer

# Clean git history
rm -rf .git
git init

# Commit code
gcloud init && git config --global credential.https://source.developers.google.com.helper gcloud.sh
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/$REPO_NAME
git add .
git commit -m "Initial commit"
git push --all google
git push --set-upstream google master