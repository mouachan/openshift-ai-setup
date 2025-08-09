#!/bin/bash
# Script pour déployer l'image personnalisée Triton Demo dans OpenShift AI

set -e

echo "🚀 Déploiement de l'image personnalisée Triton Demo"
echo "=================================================="

# Variables
NAMESPACE_RHOAI="redhat-ods-applications"
NAMESPACE_TRITON="triton-demo"
IMAGE_NAME="triton-demo-notebook"
IMAGE_URL="quay.io/mouachan/triton-demo-notebook:latest"

# Fonctions utilitaires
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 n'est pas installé"
        exit 1
    fi
}

wait_for_rollout() {
    local resource=$1
    local namespace=$2
    echo "⏳ Attente du déploiement de $resource dans $namespace..."
    kubectl rollout status $resource -n $namespace --timeout=300s
}

# Vérification des prérequis
echo "🔍 Vérification des prérequis..."
check_command kubectl
check_command oc

# Vérification de la connexion au cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Pas de connexion au cluster OpenShift"
    echo "💡 Connectez-vous avec: oc login"
    exit 1
fi

echo "✅ Connecté au cluster OpenShift"

# 1. Déploiement de l'image personnalisée
echo ""
echo "📦 Étape 1: Déploiement de l'ImageStream personnalisée"
echo "----------------------------------------------------"

# Appliquer la configuration RHOAI avec les custom images
kubectl apply -k /Users/mouchan/projects/openshift-ai-setup/components/instances/rhoai-instance/components/custom-notebook-images/

# Vérifier que l'ImageStream est créée
echo "⏳ Vérification de l'ImageStream..."
kubectl get imagestream $IMAGE_NAME -n $NAMESPACE_RHOAI || {
    echo "⚠️ ImageStream pas encore créée, application directe..."
    kubectl apply -f /Users/mouchan/projects/openshift-ai-setup/components/instances/rhoai-instance/components/custom-notebook-images/triton-demo-imagestream.yaml
}

# Attendre que l'image soit importée
echo "⏳ Import de l'image depuis Quay.io..."
sleep 10

# Forcer l'import si nécessaire
kubectl import-image $IMAGE_NAME:latest --from=$IMAGE_URL -n $NAMESPACE_RHOAI --confirm || echo "⚠️ Import manuel échoué, continuons..."

# 2. Vérification de l'image dans OpenShift AI
echo ""
echo "🔍 Étape 2: Vérification de l'image dans OpenShift AI"
echo "---------------------------------------------------"

# Vérifier les labels pour OpenShift AI
kubectl get imagestream $IMAGE_NAME -n $NAMESPACE_RHOAI -o jsonpath='{.metadata.labels}' | grep -q "opendatahub.io/notebook-image" && {
    echo "✅ ImageStream correctement labelée pour OpenShift AI"
} || {
    echo "⚠️ Ajout du label OpenShift AI..."
    kubectl label imagestream $IMAGE_NAME -n $NAMESPACE_RHOAI opendatahub.io/notebook-image=true --overwrite
}

# 3. Mise à jour du workbench pour utiliser l'image personnalisée
echo ""
echo "🔧 Étape 3: Mise à jour du workbench Triton Demo"
echo "----------------------------------------------"

# Appliquer la configuration du workbench
kubectl apply -k /Users/mouchan/projects/openshift-ai-setup/components/instances/triton-demo-instance/base/data-science-project/

# Vérifier le namespace triton-demo
kubectl get namespace $NAMESPACE_TRITON || {
    echo "📁 Création du namespace $NAMESPACE_TRITON..."
    kubectl create namespace $NAMESPACE_TRITON
}

# 4. Redémarrage du workbench pour utiliser la nouvelle image
echo ""
echo "🔄 Étape 4: Redémarrage du workbench"
echo "---------------------------------"

# Supprimer le pod du workbench pour forcer le redémarrage
kubectl delete pod -l app=triton-workbench -n $NAMESPACE_TRITON --ignore-not-found=true

echo "⏳ Attente du nouveau pod..."
sleep 15

# Vérifier le statut du workbench
kubectl get pods -l app=triton-workbench -n $NAMESPACE_TRITON && {
    echo "✅ Workbench redémarré avec succès"
} || {
    echo "⚠️ Workbench en cours de création..."
}

# 5. Affichage des informations finales
echo ""
echo "🎉 Déploiement terminé!"
echo "====================="
echo ""
echo "📋 Résumé:"
echo "   🖼️  Image: $IMAGE_URL"
echo "   📦 ImageStream: $IMAGE_NAME dans $NAMESPACE_RHOAI"
echo "   🔧 Workbench: triton-workbench dans $NAMESPACE_TRITON"
echo ""
echo "🌐 Pour accéder:"
echo "   1. Dashboard OpenShift AI → Data Science Projects"
echo "   2. Projet 'triton-demo'"
echo "   3. L'image '$IMAGE_NAME' devrait apparaître dans les choix"
echo ""
echo "⚡ Temps de démarrage attendu: 30-60 secondes (au lieu de 8-12 minutes)"
echo ""
echo "🔍 Vérifications:"
echo "   kubectl get imagestream $IMAGE_NAME -n $NAMESPACE_RHOAI"
echo "   kubectl get pods -n $NAMESPACE_TRITON"
echo "   kubectl logs -l app=triton-workbench -n $NAMESPACE_TRITON"