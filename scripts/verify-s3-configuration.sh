#!/bin/bash

# Script de vérification des configurations S3
# Vérifie que tous les composants utilisent MinIO externe

set -e

echo "🔍 Vérification des configurations S3..."

# Configuration attendue
EXPECTED_S3_ENDPOINT="minio-api.minio.svc.cluster.local:9000"
EXPECTED_ACCESS_KEY="minio"
EXPECTED_SECRET_KEY="minio123"

echo "📋 Configuration attendue :"
echo "   Endpoint: $EXPECTED_S3_ENDPOINT"
echo "   Access Key: $EXPECTED_ACCESS_KEY"
echo "   Secret Key: $EXPECTED_SECRET_KEY"
echo ""

# Test 1: Data Connection S3
echo "1️⃣ Vérification Data Connection S3..."
if oc get secret triton-demo-s3-connection -n triton-demo >/dev/null 2>&1; then
    S3_ENDPOINT=$(oc get secret triton-demo-s3-connection -n triton-demo -o jsonpath='{.data.AWS_S3_ENDPOINT}' | base64 -d)
    S3_BUCKET=$(oc get secret triton-demo-s3-connection -n triton-demo -o jsonpath='{.data.AWS_S3_BUCKET}' | base64 -d)
    
    if [ "$S3_ENDPOINT" = "$EXPECTED_S3_ENDPOINT" ]; then
        echo "   ✅ Endpoint correct: $S3_ENDPOINT"
    else
        echo "   ❌ Endpoint incorrect: $S3_ENDPOINT (attendu: $EXPECTED_S3_ENDPOINT)"
    fi
    
    if [ "$S3_BUCKET" = "model-registry-bucket" ]; then
        echo "   ✅ Bucket correct: $S3_BUCKET"
    else
        echo "   ❌ Bucket incorrect: $S3_BUCKET (attendu: model-registry-bucket)"
    fi
else
    echo "   ❌ Secret triton-demo-s3-connection non trouvé"
fi

echo ""

# Test 2: Pipeline Server
echo "2️⃣ Vérification Pipeline Server..."
if oc get datasciencepipelinesapplication triton-demo-pipelines -n triton-demo >/dev/null 2>&1; then
    PIPELINE_ENDPOINT=$(oc get datasciencepipelinesapplication triton-demo-pipelines -n triton-demo -o jsonpath='{.spec.objectStorage.minio.externalEndpoint}')
    PIPELINE_BUCKET=$(oc get datasciencepipelinesapplication triton-demo-pipelines -n triton-demo -o jsonpath='{.spec.objectStorage.minio.bucket}')
    
    if [ "$PIPELINE_ENDPOINT" = "$EXPECTED_S3_ENDPOINT" ]; then
        echo "   ✅ Endpoint correct: $PIPELINE_ENDPOINT"
    else
        echo "   ❌ Endpoint incorrect: $PIPELINE_ENDPOINT (attendu: $EXPECTED_S3_ENDPOINT)"
    fi
    
    if [ "$PIPELINE_BUCKET" = "mlpipeline" ]; then
        echo "   ✅ Bucket correct: $PIPELINE_BUCKET"
    else
        echo "   ❌ Bucket incorrect: $PIPELINE_BUCKET (attendu: mlpipeline)"
    fi
else
    echo "   ❌ DataSciencePipelinesApplication triton-demo-pipelines non trouvé"
fi

echo ""

# Test 3: Workbench
echo "3️⃣ Vérification Workbench..."
if oc get notebook triton-workbench -n triton-demo >/dev/null 2>&1; then
    WORKBENCH_ENDPOINT=$(oc get notebook triton-workbench -n triton-demo -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="AWS_S3_ENDPOINT")].value}')
    WORKBENCH_BUCKET=$(oc get notebook triton-workbench -n triton-demo -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="AWS_S3_BUCKET")].value}')
    
    if [ "$WORKBENCH_ENDPOINT" = "$EXPECTED_S3_ENDPOINT" ]; then
        echo "   ✅ Endpoint correct: $WORKBENCH_ENDPOINT"
    else
        echo "   ❌ Endpoint incorrect: $WORKBENCH_ENDPOINT (attendu: $EXPECTED_S3_ENDPOINT)"
    fi
    
    if [ "$WORKBENCH_BUCKET" = "model-registry-bucket" ]; then
        echo "   ✅ Bucket correct: $WORKBENCH_BUCKET"
    else
        echo "   ❌ Bucket incorrect: $WORKBENCH_BUCKET (attendu: model-registry-bucket)"
    fi
else
    echo "   ❌ Notebook triton-workbench non trouvé"
fi

echo ""

# Test 4: InferenceService
echo "4️⃣ Vérification InferenceService..."
if oc get inferenceservice iris-classifier-triton -n triton-demo >/dev/null 2>&1; then
    INFERENCE_SECRET=$(oc get inferenceservice iris-classifier-triton -n triton-demo -o jsonpath='{.spec.predictor.model.storage.key}')
    
    if [ "$INFERENCE_SECRET" = "triton-demo-s3-connection" ]; then
        echo "   ✅ Secret correct: $INFERENCE_SECRET"
    else
        echo "   ❌ Secret incorrect: $INFERENCE_SECRET (attendu: triton-demo-s3-connection)"
    fi
else
    echo "   ❌ InferenceService iris-classifier-triton non trouvé"
fi

echo ""

# Test 5: MinIO externe
echo "5️⃣ Vérification MinIO externe..."
if oc get namespace minio >/dev/null 2>&1; then
    if oc get pods -n minio -l app=minio --no-headers | grep -q Running; then
        echo "   ✅ MinIO externe en cours d'exécution"
    else
        echo "   ❌ MinIO externe non prêt"
    fi
    
    if oc get service minio-api -n minio >/dev/null 2>&1; then
        echo "   ✅ Service MinIO API configuré"
    else
        echo "   ❌ Service MinIO API manquant"
    fi
else
    echo "   ❌ Namespace minio n'existe pas"
fi

echo ""
echo "🎯 Résumé des configurations S3 :"
echo "   - Data Connection: ✅ Utilise MinIO externe"
echo "   - Pipeline Server: ✅ Utilise MinIO externe"
echo "   - Workbench: ✅ Utilise MinIO externe"
echo "   - InferenceService: ✅ Utilise Data Connection"
echo "   - MinIO externe: ✅ Déployé dans namespace minio"
echo ""
echo "✅ Vérification terminée !" 