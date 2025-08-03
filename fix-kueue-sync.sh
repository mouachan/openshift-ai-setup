#!/bin/bash
# Script de résolution des problèmes Kueue dans GitOps
# Usage: ./fix-kueue-sync.sh

set -e

echo "🔧 RÉSOLUTION PROBLÈMES KUEUE"
echo "============================="
echo ""

# 1. Vérifier l'état actuel
echo "📋 1. État actuel de l'application"
echo "---------------------------------"

if ! oc get application openshift-ai-simple -n openshift-gitops >/dev/null 2>&1; then
    echo "❌ Application openshift-ai-simple non trouvée"
    echo "💡 Exécutez d'abord: ./install-gitops.sh"
    exit 1
fi

SYNC_STATUS=$(oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.sync.status}')
echo "   Statut de synchronisation: $SYNC_STATUS"

# 2. Analyser les erreurs Kueue spécifiquement
echo ""
echo "📋 2. Analyse des erreurs Kueue"
echo "------------------------------"

echo "🔍 Recherche d'erreurs liées à config.kueue.x-k8s.io/v1beta1..."
KUEUE_ERRORS=$(oc get application openshift-ai-simple -n openshift-gitops -o yaml | grep -i "config.kueue.x-k8s.io.*not found" || true)

if [ -n "$KUEUE_ERRORS" ]; then
    echo "❌ Erreurs Kueue Configuration API détectées"
    echo "   L'API config.kueue.x-k8s.io/v1beta1/Configuration n'est pas disponible"
    echo "   Ceci est normal car Red Hat build of Kueue n'inclut pas cette ressource"
else
    echo "✅ Aucune erreur Kueue Configuration API détectée"
fi

# 3. Vérifier l'opérateur Kueue
echo ""
echo "📋 3. Vérification de l'opérateur Kueue"
echo "--------------------------------------"

if oc get subscription kueue -n openshift-operators >/dev/null 2>&1; then
    KUEUE_SOURCE=$(oc get subscription kueue -n openshift-operators -o jsonpath='{.spec.source}')
    KUEUE_CHANNEL=$(oc get subscription kueue -n openshift-operators -o jsonpath='{.spec.channel}')
    echo "✅ Subscription Kueue trouvée"
    echo "   Source: $KUEUE_SOURCE"
    echo "   Channel: $KUEUE_CHANNEL"
    
    if [ "$KUEUE_SOURCE" = "redhat-operators" ]; then
        echo "✅ Utilise Red Hat build of Kueue (correct)"
    else
        echo "⚠️  Utilise $KUEUE_SOURCE (devrait être redhat-operators)"
    fi
else
    echo "❌ Subscription Kueue non trouvée"
fi

# 4. Vérifier les CRDs Kueue disponibles
echo ""
echo "📋 4. CRDs Kueue disponibles"
echo "---------------------------"

echo "🔍 APIs Kueue disponibles:"
oc api-resources --api-group=kueue.x-k8s.io | grep -v NAME || echo "   Aucune API kueue.x-k8s.io trouvée"

echo ""
echo "🔍 APIs Config Kueue disponibles:"
oc api-resources --api-group=config.kueue.x-k8s.io | grep -v NAME || echo "   Aucune API config.kueue.x-k8s.io trouvée (normal pour Red Hat build)"

# 5. Solutions proposées
echo ""
echo "📋 5. Solutions proposées"
echo "-----------------------"

if [ "$SYNC_STATUS" = "OutOfSync" ]; then
    echo "💡 Solution 1: Forcer la synchronisation (ignorer les erreurs)"
    echo "   oc patch application openshift-ai-simple -n openshift-gitops --type merge -p '{\"spec\":{\"syncPolicy\":{\"syncOptions\":[\"CreateNamespace=true\",\"Replace=true\",\"SkipDryRunOnMissingResource=true\"]}}}'"
    echo ""
    
    echo "💡 Solution 2: Exclure les ressources Configuration Kueue"
    echo "   oc patch application openshift-ai-simple -n openshift-gitops --type merge -p '{\"spec\":{\"syncPolicy\":{\"syncOptions\":[\"CreateNamespace=true\",\"Replace=true\"],\"ignoreDifferences\":[{\"group\":\"config.kueue.x-k8s.io\",\"kind\":\"Configuration\",\"jsonPointers\":[\"/spec\"]}]}}}'"
    echo ""
    
    echo "💡 Solution 3: Supprimer et recréer l'application"
    echo "   oc delete application openshift-ai-simple -n openshift-gitops"
    echo "   ./install-gitops.sh"
    echo ""
    
    echo "🤖 Application automatique de la Solution 1..."
    oc patch application openshift-ai-simple -n openshift-gitops --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true","Replace=true","SkipDryRunOnMissingResource=true"]}}}'
    
    echo "⏳ Attente de la resynchronisation (30s)..."
    sleep 30
    
    NEW_SYNC_STATUS=$(oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.sync.status}')
    echo "   Nouveau statut: $NEW_SYNC_STATUS"
    
    if [ "$NEW_SYNC_STATUS" = "Synced" ]; then
        echo "✅ Problème résolu!"
    else
        echo "⚠️  Problème persiste, essayez la Solution 2 ou 3"
    fi
else
    echo "✅ Application déjà synchronisée, aucune action nécessaire"
fi

# 6. Vérification finale
echo ""
echo "📋 6. Vérification finale"
echo "------------------------"

FINAL_SYNC=$(oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.sync.status}')
FINAL_HEALTH=$(oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.health.status}')

echo "   Sync Status: $FINAL_SYNC"
echo "   Health Status: $FINAL_HEALTH"

if [ "$FINAL_SYNC" = "Synced" ] && [ "$FINAL_HEALTH" = "Healthy" ]; then
    echo ""
    echo "🎉 SUCCESS! Application complètement synchronisée et en bonne santé"
else
    echo ""
    echo "⚠️  L'application nécessite encore une attention:"
    echo "   - Vérifiez les logs: oc logs deployment/openshift-gitops-application-controller -n openshift-gitops"
    echo "   - Diagnostic complet: ./diagnostics-gitops.sh"
fi

echo ""
echo "🎯 Résolution terminée!"
