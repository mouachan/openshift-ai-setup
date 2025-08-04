#!/bin/bash

# Deploy Model Registry with MySQL and MinIO for OpenShift AI 2.22
# This script deploys the complete Model Registry infrastructure via GitOps

set -e

echo "🚀 Deploying Model Registry with MySQL and MinIO S3 for OpenShift AI 2.22..."

# Check if cluster is available
if ! oc whoami &> /dev/null; then
    echo "❌ Error: Please login to OpenShift cluster first"
    echo "Run: oc login <cluster-url>"
    exit 1
fi

# Get cluster info
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
CLUSTER_DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')

echo "📊 Cluster: $CLUSTER_NAME"
echo "🌐 Domain: $CLUSTER_DOMAIN"

# Deploy via GitOps (ArgoCD will handle the deployment)
echo "📦 Deploying Model Registry infrastructure via GitOps..."
oc apply -k clusters/overlays/openshift-ai-dev

# Wait for namespace to be ready
echo "⏳ Waiting for namespace to be ready..."
oc wait --for=condition=Ready namespace/rhoai-model-registries --timeout=60s

# Wait for MySQL to be ready
echo "🗄️ Waiting for MySQL to be ready..."
oc wait --for=condition=Available deployment/mysql -n rhoai-model-registries --timeout=300s

# Wait for MinIO to be ready
echo "📦 Waiting for MinIO to be ready..."
oc wait --for=condition=Available deployment/minio -n rhoai-model-registries --timeout=300s

# Check if MinIO bucket initialization completed
echo "🪣 Checking MinIO bucket initialization..."
oc wait --for=condition=Complete job/minio-bucket-init -n rhoai-model-registries --timeout=120s

# Get MinIO console URL
MINIO_CONSOLE_URL=$(oc get route minio-console -n rhoai-model-registries -o jsonpath='{.spec.host}')

# Check Model Registry status
echo "📋 Checking Model Registry status..."
sleep 30  # Give it time to initialize

if oc get modelregistry default-model-registry -n rhoai-model-registries &> /dev/null; then
    echo "✅ Model Registry created successfully"
    
    # Get Model Registry route if available
    if oc get route -n rhoai-model-registries | grep -q "model-registry"; then
        MODEL_REGISTRY_URL=$(oc get route -n rhoai-model-registries -o jsonpath='{.items[?(@.metadata.labels.app=="model-registry")].spec.host}')
        echo "🔗 Model Registry URL: https://$MODEL_REGISTRY_URL"
    fi
else
    echo "⚠️  Model Registry not yet created, will be handled by OpenShift AI operator"
fi

echo ""
echo "✅ Model Registry infrastructure deployment complete!"
echo ""
echo "📋 Summary:"
echo "  • MySQL Database: ✅ Running in rhoai-model-registries namespace"
echo "  • MinIO S3 Storage: ✅ Running with bucket 'model-registry'"
echo "  • Model Registry Config: ✅ Applied"
echo ""
echo "🔗 Access URLs:"
echo "  • MinIO Console: https://$MINIO_CONSOLE_URL"
echo "    - Username: minioadmin"
echo "    - Password: minioadmin123"
echo ""
echo "🔧 Next Steps:"
echo "  1. Check OpenShift AI dashboard for Model Registry status"
echo "  2. Verify Model Registry is showing as 'Ready' in the dashboard"
echo "  3. Start creating and registering your ML models"
echo ""
echo "📊 Check status with:"
echo "  oc get all -n rhoai-model-registries"
echo "  oc get modelregistry -n rhoai-model-registries"
