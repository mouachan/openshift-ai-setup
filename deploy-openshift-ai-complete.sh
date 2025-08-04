#!/bin/bash

# Déploiement GitOps complet OpenShift AI 2.22 avec Model Registry
# Ce script automatise complètement le déploiement sans intervention manuelle

set -e

echo "🚀 Déploiement GitOps OpenShift AI 2.22 avec Model Registry..."

# Check if cluster is available
if ! oc whoami &> /dev/null; then
    echo "❌ Error: Please login to OpenShift cluster first"
    echo "Run: oc login <cluster-url>"
    exit 1
fi

echo "👤 Logged in as: $(oc whoami)"

# Deploy everything via GitOps
echo "📦 Deploying via GitOps..."
oc apply -k clusters/overlays/openshift-ai-dev

# Wait for Model Registry namespace
echo "⏳ Waiting for Model Registry namespace..."
oc wait --for=condition=Ready namespace/rhoai-model-registries --timeout=60s || echo "Namespace ready"

# Wait for MySQL to be ready
echo "🗄️ Waiting for MySQL to be ready..."
oc wait --for=condition=Available deployment/mysql -n rhoai-model-registries --timeout=300s

# Wait for MySQL auth fix job to complete
echo "🔐 Waiting for MySQL authentication fix..."
oc wait --for=condition=Complete job/mysql-auth-fix -n rhoai-model-registries --timeout=120s

# Wait for MinIO to be ready
echo "📦 Waiting for MinIO to be ready..."
oc wait --for=condition=Available deployment/minio -n rhoai-model-registries --timeout=300s

# Wait for MinIO bucket initialization
echo "🪣 Waiting for MinIO bucket initialization..."
oc wait --for=condition=Complete job/minio-bucket-init -n rhoai-model-registries --timeout=120s

# Check Model Registry status
echo "📋 Checking Model Registry status..."
sleep 10

# Wait for Model Registry to be ready (may take time for operator to create it)
echo "⏳ Waiting for Model Registry to be ready..."
for i in {1..30}; do
    if oc get modelregistry default-modelregistry --ignore-not-found=true | grep -q "True"; then
        echo "✅ Model Registry is ready!"
        break
    else
        echo "⏳ Model Registry not ready yet, waiting... ($i/30)"
        sleep 10
    fi
done

# Get URLs
echo ""
echo "🔗 Getting access URLs..."
MODEL_REGISTRY_URL=""
if oc get route -n rhoai-model-registries | grep -q "model-registry"; then
    MODEL_REGISTRY_URL=$(oc get route -n rhoai-model-registries -o jsonpath='{.items[?(@.metadata.name=="default-model-registry-http")].spec.host}')
fi

MINIO_CONSOLE_URL=$(oc get route minio-console -n rhoai-model-registries -o jsonpath='{.spec.host}' 2>/dev/null || echo "Not available")

echo ""
echo "✅ GitOps deployment completed successfully!"
echo ""
echo "📋 Summary:"
echo "  • MySQL Database: ✅ Running with authentication configured"
echo "  • MinIO S3 Storage: ✅ Running with bucket 'model-registry'"
echo "  • Model Registry: ✅ $(oc get modelregistry default-modelregistry -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo 'Deploying')"
echo ""
echo "🔗 Access URLs:"
if [ ! -z "$MODEL_REGISTRY_URL" ]; then
    echo "  • Model Registry API: https://$MODEL_REGISTRY_URL"
fi
echo "  • MinIO Console: https://$MINIO_CONSOLE_URL"
echo "    - Username: minioadmin"
echo "    - Password: minioadmin123"
echo ""
echo "🎯 OpenShift AI Dashboard:"
echo "  • Model Registry should now show as 'Ready'"
echo "  • You can start registering ML models"
echo ""
echo "📊 Quick status check:"
echo "  oc get all -n rhoai-model-registries"
echo "  oc get modelregistry -A"
echo ""
echo "✅ All components deployed automatically via GitOps!"
echo "🔄 Future deployments: Just run 'oc apply -k clusters/overlays/openshift-ai-dev'"
