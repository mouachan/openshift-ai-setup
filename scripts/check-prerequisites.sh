#!/bin/bash
# Script de vérification des prérequis pour OpenShift AI 2.22

echo "🔍 Vérification des prérequis OpenShift AI 2.22"
echo "================================================"

# Vérifier la connexion
echo "1. Connexion au cluster:"
oc whoami --show-server 2>/dev/null && echo "  ✅ Connecté" || echo "  ❌ Non connecté - Utilisez 'oc login'"

# Vérifier les permissions
echo "2. Permissions administrateur:"
oc auth can-i create clusterroles 2>/dev/null && echo "  ✅ Admin cluster" || echo "  ❌ Permissions insuffisantes"

# Vérifier la version OpenShift
echo "3. Version OpenShift:"
OCP_VERSION=$(oc version -o json 2>/dev/null | jq -r '.openshiftVersion' 2>/dev/null || echo "unknown")
echo "  Version: $OCP_VERSION"
if [[ "$OCP_VERSION" =~ ^4\.1[2-9] ]] || [[ "$OCP_VERSION" =~ ^4\.[2-9][0-9] ]]; then
    echo "  ✅ Compatible (4.12+)"
else
    echo "  ⚠️  Version recommandée: 4.12+"
fi

# Vérifier les ressources
echo "4. Ressources cluster:"
NODES=$(oc get nodes --no-headers 2>/dev/null | wc -l)
WORKERS=$(oc get nodes --no-headers -l node-role.kubernetes.io/worker 2>/dev/null | wc -l)
echo "  Nodes total: $NODES"
echo "  Workers: $WORKERS"
[[ $WORKERS -ge 3 ]] && echo "  ✅ Suffisant pour OpenShift AI" || echo "  ⚠️  Recommandé: 3+ workers"

echo ""
echo "🎯 Prêt pour l'installation GitOps !"
