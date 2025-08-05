#!/bin/bash
# Fix Model Registry Dashboard Configuration
# This script configures the OpenShift AI dashboard to connect to our Model Registry

echo "🔧 Configuring Model Registry in OpenShift AI Dashboard..."

# Get the Model Registry service URL
MODEL_REGISTRY_URL="https://$(oc get route default-model-registry-http -n rhoai-model-registries -o jsonpath='{.spec.host}')"

echo "Model Registry URL: $MODEL_REGISTRY_URL"

# Patch the dashboard config to include Model Registry settings
oc patch odhdashboardconfig odh-dashboard-config -n redhat-ods-applications --type='merge' -p='
{
  "spec": {
    "dashboardConfig": {
      "modelRegistrySettings": [
        {
          "name": "default-modelregistry",
          "url": "'$MODEL_REGISTRY_URL'",
          "description": "Default Model Registry for OpenShift AI",
          "username": "",
          "password": ""
        }
      ]
    }
  }
}'

echo "✅ Model Registry configured in OpenShift AI dashboard"
echo "🔄 Please refresh the OpenShift AI interface"
