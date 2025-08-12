#!/bin/bash

# Script pour vérifier le statut GitOps et ArgoCD

set -e

echo "🔍 Vérification du statut GitOps et ArgoCD"

# Vérifier le statut git
echo "📊 Statut Git local..."
git status --porcelain

# Vérifier le dernier commit
echo "💾 Dernier commit:"
git log --oneline -1

# Vérifier le statut ArgoCD
echo "🔄 Statut ArgoCD..."
if command -v argocd &> /dev/null; then
    echo "📋 Applications ArgoCD:"
    argocd app list
else
    echo "⚠️ CLI ArgoCD non installé, vérifiez via l'UI"
fi

# Vérifier le statut du cluster
echo "📱 Statut du cluster..."
echo "Namespace triton-demo:"
oc get namespace triton-demo 2>/dev/null || echo "❌ Namespace non trouvé"

echo "DSPA:"
oc get dspa -n triton-demo 2>/dev/null || echo "❌ DSPA non trouvé"

echo "Workbench:"
oc get pods -n triton-demo -l app=triton-workbench 2>/dev/null || echo "❌ Workbench non trouvé"

# Vérifier les routes
echo "🛣️ Routes:"
oc get routes -n triton-demo 2>/dev/null || echo "❌ Routes non trouvées"

echo "✅ Vérification terminée!"
