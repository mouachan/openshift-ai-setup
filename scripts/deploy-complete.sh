#!/bin/bash
# Déploiement complet OpenShift AI 2.22 via GitOps

set -e

echo "🚀 Déploiement OpenShift AI 2.22 via GitOps"
echo "============================================="

# Vérifications initiales
./scripts/check-prerequisites.sh

echo ""
read -p "Continuer avec l'installation ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation annulée."
    exit 0
fi

# Étape 1: GitOps si pas installé
echo ""
echo "📋 Étape 1/3: Vérification/Installation GitOps"
if ! oc get csv -n openshift-operators | grep -q "gitops.*Succeeded"; then
    echo "🔧 Installation GitOps nécessaire..."
    ./scripts/install-gitops.sh
else
    echo "✅ GitOps déjà installé"
fi

# Étape 2: Déploiement OpenShift AI
echo ""
echo "📋 Étape 2/3: Déploiement OpenShift AI"
echo "🚀 Création de l'application ArgoCD..."
oc apply -f argocd/openshift-ai-application.yaml

echo "✅ Application ArgoCD créée !"

# Étape 3: Monitoring et vérification
echo ""
echo "📋 Étape 3/3: Monitoring du déploiement"
echo "⏳ Déploiement en cours... (peut prendre 10-15 minutes)"

# Fonction de monitoring
monitor_deployment() {
    local timeout=900  # 15 minutes
    local elapsed=0
    local interval=30
    
    while [ $elapsed -lt $timeout ]; do
        echo ""
        echo "⏱️  Temps écoulé: $((elapsed/60))m $((elapsed%60))s"
        
        # Vérifier l'application ArgoCD
        APP_STATUS=$(oc get application openshift-ai-main -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        APP_HEALTH=$(oc get application openshift-ai-main -n openshift-gitops -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
        echo "📱 Application ArgoCD: Sync=$APP_STATUS, Health=$APP_HEALTH"
        
        # Vérifier les opérateurs
        OPERATORS_READY=$(oc get csv -n openshift-operators --no-headers 2>/dev/null | grep -E "(rhods|servicemesh|serverless|pipelines|kueue)" | grep Succeeded | wc -l)
        OPERATORS_TOTAL=$(oc get csv -n openshift-operators --no-headers 2>/dev/null | grep -E "(rhods|servicemesh|serverless|pipelines|kueue)" | wc -l)
        echo "🔧 Opérateurs: $OPERATORS_READY/$OPERATORS_TOTAL prêts"
        
        # Vérifier OpenShift AI
        if oc get dsc >/dev/null 2>&1; then
            DSC_STATUS=$(oc get dsc -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
            echo "🎯 OpenShift AI: $DSC_STATUS"
            
            if [[ "$DSC_STATUS" == "Ready" ]]; then
                echo ""
                echo "🎉 DÉPLOIEMENT RÉUSSI !"
                return 0
            fi
        else
            echo "🎯 OpenShift AI: En cours d'installation..."
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    echo ""
    echo "⚠️  Timeout atteint. Vérifiez manuellement le déploiement."
    return 1
}

# Lancer le monitoring
monitor_deployment

# Afficher les URLs finales
echo ""
echo "🌐 URLs d'accès:"
ARGOCD_URL=$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "non-disponible")
RHOAI_URL=$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null || echo "en-cours-installation")

echo "  ArgoCD: https://$ARGOCD_URL"
echo "  OpenShift AI: https://$RHOAI_URL"

echo ""
echo "📚 Commandes utiles:"
echo "  make status    # Vérifier le statut"
echo "  make verify    # Tests complets"
echo "  make clean     # Supprimer l'application"

echo ""
echo "🎯 Installation terminée !"
