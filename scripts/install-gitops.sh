#!/bin/bash
# Installation d'OpenShift GitOps sur cluster clean

echo "🚀 Installation OpenShift GitOps"
echo "================================"

# Cloner le repository si pas déjà fait
if [ ! -d "openshift-ai-setup" ]; then
    echo "📥 Clonage du repository..."
    git clone https://github.com/mouachan/openshift-ai-setup.git
    cd openshift-ai-setup
else
    echo "📁 Repository déjà présent"
    cd openshift-ai-setup
fi

# Installer GitOps
echo "🔧 Installation de l'opérateur GitOps..."
oc apply -f components/operators/openshift-gitops-operator/base/subscription.yaml

echo "⏳ Attente de l'installation GitOps (2-3 minutes)..."
sleep 30

# Vérifier l'installation
echo "🔍 Vérification de l'installation..."
for i in {1..12}; do
    if oc get csv -n openshift-operators | grep -q "gitops.*Succeeded"; then
        echo "✅ GitOps installé avec succès !"
        break
    fi
    echo "  Tentative $i/12 - En attente..."
    sleep 15
done

# Vérifier ArgoCD
echo "🌐 Vérification d'ArgoCD..."
for i in {1..8}; do
    if oc get route argocd-server -n openshift-gitops >/dev/null 2>&1; then
        ARGOCD_URL=$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}')
        echo "✅ ArgoCD disponible sur: https://$ARGOCD_URL"
        break
    fi
    echo "  Tentative $i/8 - ArgoCD en cours de démarrage..."
    sleep 15
done

echo ""
echo "🎯 GitOps prêt ! Vous pouvez maintenant déployer OpenShift AI."
