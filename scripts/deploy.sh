#!/bin/bash

# EDIT THESE TO YOUR VALUES
export REGION="europe-north1"
export SERVICE_NAME="log-collector"
export SERVICE_ACCOUNT_NAME="log-collector-sa"

gcloud beta run deploy $SERVICE_NAME \
  --region $REGION \
  --platform managed \
  --memory 2Gi \
  --source . \
  --tag latest \
  --no-use-http2 \
  --max-instances 5 \
  --allow-unauthenticated \
  --service-account $SERVICE_ACCOUNT_NAME