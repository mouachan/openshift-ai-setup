#!/bin/bash

# Check Model Registry deployment status

echo "🔍 Model Registry Deployment Status Check"
echo "=========================================="

# Check if logged in
if ! oc whoami &> /dev/null; then
    echo "❌ Error: Please login to OpenShift cluster first"
    exit 1
fi

echo "👤 Logged in as: $(oc whoami)"
echo ""

# Check namespace
echo "📁 Namespace Status:"
if oc get namespace rhoai-model-registries &> /dev/null; then
    echo "  ✅ rhoai-model-registries namespace exists"
else
    echo "  ❌ rhoai-model-registries namespace not found"
    exit 1
fi

echo ""
echo "🗄️ MySQL Database Status:"
if oc get deployment mysql -n rhoai-model-registries &> /dev/null; then
    MYSQL_STATUS=$(oc get deployment mysql -n rhoai-model-registries -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
    if [ "$MYSQL_STATUS" = "True" ]; then
        echo "  ✅ MySQL deployment is available"
        MYSQL_REPLICAS=$(oc get deployment mysql -n rhoai-model-registries -o jsonpath='{.status.readyReplicas}')
        echo "  📊 Ready replicas: $MYSQL_REPLICAS/1"
    else
        echo "  ⚠️  MySQL deployment not ready"
    fi
else
    echo "  ❌ MySQL deployment not found"
fi

echo ""
echo "📦 MinIO S3 Storage Status:"
if oc get deployment minio -n rhoai-model-registries &> /dev/null; then
    MINIO_STATUS=$(oc get deployment minio -n rhoai-model-registries -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
    if [ "$MINIO_STATUS" = "True" ]; then
        echo "  ✅ MinIO deployment is available"
        MINIO_REPLICAS=$(oc get deployment minio -n rhoai-model-registries -o jsonpath='{.status.readyReplicas}')
        echo "  📊 Ready replicas: $MINIO_REPLICAS/1"
        
        # Check MinIO console route
        if oc get route minio-console -n rhoai-model-registries &> /dev/null; then
            MINIO_URL=$(oc get route minio-console -n rhoai-model-registries -o jsonpath='{.spec.host}')
            echo "  🔗 Console URL: https://$MINIO_URL"
        fi
    else
        echo "  ⚠️  MinIO deployment not ready"
    fi
else
    echo "  ❌ MinIO deployment not found"
fi

echo ""
echo "🪣 MinIO Bucket Initialization:"
if oc get job minio-bucket-init -n rhoai-model-registries &> /dev/null; then
    JOB_STATUS=$(oc get job minio-bucket-init -n rhoai-model-registries -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}')
    if [ "$JOB_STATUS" = "True" ]; then
        echo "  ✅ Bucket initialization completed"
    else
        echo "  ⚠️  Bucket initialization not completed"
        echo "  📋 Job status:"
        oc get job minio-bucket-init -n rhoai-model-registries
    fi
else
    echo "  ❌ Bucket initialization job not found"
fi

echo ""
echo "📋 Model Registry Status:"
if oc get modelregistry -n rhoai-model-registries &> /dev/null; then
    echo "  ✅ ModelRegistry custom resources found:"
    oc get modelregistry -n rhoai-model-registries -o custom-columns="NAME:.metadata.name,PHASE:.status.conditions[?(@.type=='Available')].status,AGE:.metadata.creationTimestamp"
else
    echo "  ⚠️  No ModelRegistry custom resources found"
    echo "     This may be normal if OpenShift AI operator hasn't created them yet"
fi

echo ""
echo "🔐 Secrets Status:"
echo "  MySQL credentials:"
if oc get secret mysql-credentials -n rhoai-model-registries &> /dev/null; then
    echo "    ✅ mysql-credentials secret exists"
else
    echo "    ❌ mysql-credentials secret not found"
fi

echo "  MinIO credentials:"
if oc get secret minio-credentials -n rhoai-model-registries &> /dev/null; then
    echo "    ✅ minio-credentials secret exists"
else
    echo "    ❌ minio-credentials secret not found"
fi

echo "  Model Registry DB config:"
if oc get secret model-registry-db-config -n rhoai-model-registries &> /dev/null; then
    echo "    ✅ model-registry-db-config secret exists"
else
    echo "    ❌ model-registry-db-config secret not found"
fi

echo ""
echo "💾 Storage Status:"
echo "  PersistentVolumeClaims:"
oc get pvc -n rhoai-model-registries 2>/dev/null || echo "    ❌ No PVCs found"

echo ""
echo "🌐 Services and Routes:"
echo "  Services:"
oc get svc -n rhoai-model-registries 2>/dev/null || echo "    ❌ No services found"
echo "  Routes:"
oc get route -n rhoai-model-registries 2>/dev/null || echo "    ❌ No routes found"

echo ""
echo "📊 All Resources Summary:"
oc get all -n rhoai-model-registries 2>/dev/null || echo "❌ No resources found in namespace"

echo ""
echo "🔧 Quick Commands:"
echo "  • View all resources: oc get all -n rhoai-model-registries"
echo "  • Check MySQL logs: oc logs deployment/mysql -n rhoai-model-registries"
echo "  • Check MinIO logs: oc logs deployment/minio -n rhoai-model-registries"
echo "  • Check bucket init logs: oc logs job/minio-bucket-init -n rhoai-model-registries"
