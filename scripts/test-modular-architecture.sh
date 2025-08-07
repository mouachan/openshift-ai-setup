#!/bin/bash

# Script de test pour l'architecture modulaire
# Teste MinIO, MySQL et Model Registry dans leurs namespaces respectifs

set -e

echo "🔍 Test de l'architecture modulaire..."

# Test MinIO
echo "📦 Test MinIO dans le namespace 'minio'..."
if oc get namespace minio >/dev/null 2>&1; then
    echo "✅ Namespace minio existe"
    
    # Test des pods MinIO
    if oc get pods -n minio -l app=minio --no-headers | grep -q Running; then
        echo "✅ Pods MinIO en cours d'exécution"
    else
        echo "❌ Pods MinIO non prêts"
        oc get pods -n minio
    fi
    
    # Test du service MinIO
    if oc get service minio-api -n minio >/dev/null 2>&1; then
        echo "✅ Service MinIO API configuré"
    else
        echo "❌ Service MinIO API manquant"
    fi
    
    # Test des buckets
    if oc get job minio-bucket-init -n minio --no-headers | grep -q Complete; then
        echo "✅ Buckets S3 initialisés"
    else
        echo "⚠️  Initialisation des buckets en cours..."
    fi
else
    echo "❌ Namespace minio n'existe pas"
fi

echo ""

# Test MySQL
echo "🗄️  Test MySQL dans le namespace 'db-ai'..."
if oc get namespace db-ai >/dev/null 2>&1; then
    echo "✅ Namespace db-ai existe"
    
    # Test des pods MySQL
    if oc get pods -n db-ai -l app=mysql --no-headers | grep -q Running; then
        echo "✅ Pods MySQL en cours d'exécution"
    else
        echo "❌ Pods MySQL non prêts"
        oc get pods -n db-ai
    fi
    
    # Test du service MySQL
    if oc get service mysql -n db-ai >/dev/null 2>&1; then
        echo "✅ Service MySQL configuré"
    else
        echo "❌ Service MySQL manquant"
    fi
    
    # Test de l'initialisation
    if oc get job mysql-user-init -n db-ai --no-headers | grep -q Complete; then
        echo "✅ Base de données MySQL initialisée"
    else
        echo "⚠️  Initialisation MySQL en cours..."
    fi
else
    echo "❌ Namespace db-ai n'existe pas"
fi

echo ""

# Test Model Registry
echo "📋 Test Model Registry dans le namespace 'rhoai-model-registries'..."
if oc get namespace rhoai-model-registries >/dev/null 2>&1; then
    echo "✅ Namespace rhoai-model-registries existe"
    
    # Test des secrets
    if oc get secret model-registry-secret -n rhoai-model-registries >/dev/null 2>&1; then
        echo "✅ Secret Model Registry configuré"
    else
        echo "❌ Secret Model Registry manquant"
    fi
    
    # Test des ConfigMaps
    if oc get configmap model-registry-db-parameters -n rhoai-model-registries >/dev/null 2>&1; then
        echo "✅ ConfigMap Model Registry configuré"
    else
        echo "❌ ConfigMap Model Registry manquant"
    fi
else
    echo "❌ Namespace rhoai-model-registries n'existe pas"
fi

echo ""

# Test de connectivité
echo "🔗 Test de connectivité entre les services..."

# Test MinIO -> MySQL
echo "Test MinIO vers MySQL..."
if oc run test-connectivity --image=busybox --rm -i --restart=Never -n minio -- sh -c "
    echo 'Testing MinIO connectivity...'
    wget -q --spider http://minio-api:9000/minio/health/live && echo 'MinIO API accessible'
    echo 'Testing MySQL connectivity...'
    wget -q --spider http://mysql.db-ai.svc.cluster.local:3306 && echo 'MySQL accessible'
" 2>/dev/null; then
    echo "✅ Connectivité entre services OK"
else
    echo "❌ Problème de connectivité"
fi

echo ""

# Test RHOAI
echo "🤖 Test RHOAI..."
if oc get datasciencecluster default-dsc -n redhat-ods-applications >/dev/null 2>&1; then
    echo "✅ DataScienceCluster existe"
    
    # Test ModelRegistryReady
    MODEL_REGISTRY_STATUS=$(oc get datasciencecluster default-dsc -n redhat-ods-applications -o jsonpath='{.status.conditions[?(@.type=="ModelRegistryReady")].status}' 2>/dev/null || echo "Unknown")
    echo "📋 ModelRegistryReady: $MODEL_REGISTRY_STATUS"
    
    # Test KserveReady
    KSERVE_STATUS=$(oc get datasciencecluster default-dsc -n redhat-ods-applications -o jsonpath='{.status.conditions[?(@.type=="KserveReady")].status}' 2>/dev/null || echo "Unknown")
    echo "🔧 KserveReady: $KSERVE_STATUS"
    
    # Test ModelMeshServingReady
    MODELMESH_STATUS=$(oc get datasciencecluster default-dsc -n redhat-ods-applications -o jsonpath='{.status.conditions[?(@.type=="ModelMeshServingReady")].status}' 2>/dev/null || echo "Unknown")
    echo "📦 ModelMeshServingReady: $MODELMESH_STATUS"
else
    echo "❌ DataScienceCluster n'existe pas"
fi

echo ""
echo "🎯 Résumé de l'architecture modulaire :"
echo "   - MinIO (S3) dans namespace 'minio'"
echo "   - MySQL dans namespace 'db-ai'"
echo "   - Model Registry dans namespace 'rhoai-model-registries'"
echo "   - Services réutilisables par d'autres applications"
echo ""
echo "✅ Test terminé !" 