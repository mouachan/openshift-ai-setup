#!/bin/bash
# Script pour nettoyer l'ancien Model Registry et tester la nouvelle structure

echo "🧹 NETTOYAGE DE L'ANCIEN MODEL REGISTRY"
echo "======================================"

# 1. Supprimer le Model Registry existant
echo "📋 Suppression du ModelRegistry existant..."
oc delete modelregistry default-model-registry -n rhoai-model-registries --ignore-not-found=true

# 2. Supprimer les composants de l'ancienne structure
echo "📋 Suppression des anciens composants..."
oc delete deployment mysql -n rhoai-model-registries --ignore-not-found=true
oc delete deployment minio -n rhoai-model-registries --ignore-not-found=true
oc delete service mysql -n rhoai-model-registries --ignore-not-found=true
oc delete service minio-api -n rhoai-model-registries --ignore-not-found=true
oc delete service minio-console -n rhoai-model-registries --ignore-not-found=true

# 3. Nettoyer les anciens RBAC complexes
echo "📋 Suppression des anciens RBAC complexes..."
oc delete serviceaccount dashboard-restart -n rhoai-model-registries --ignore-not-found=true
oc delete serviceaccount model-registry-http-fix -n rhoai-model-registries --ignore-not-found=true
oc delete role dashboard-restart -n rhoai-model-registries --ignore-not-found=true
oc delete role model-registry-http-fix -n rhoai-model-registries --ignore-not-found=true
oc delete rolebinding dashboard-restart -n rhoai-model-registries --ignore-not-found=true
oc delete rolebinding model-registry-http-fix -n rhoai-model-registries --ignore-not-found=true

# 4. Nettoyer les jobs ArgoCD hooks
echo "📋 Suppression des anciens jobs ArgoCD..."
oc delete job pre-sync-dashboard-restart -n rhoai-model-registries --ignore-not-found=true
oc delete job post-sync-http-annotation -n rhoai-model-registries --ignore-not-found=true

echo ""
echo "🚀 DÉPLOIEMENT DE LA NOUVELLE STRUCTURE"
echo "======================================="

# 5. Synchroniser l'application ArgoCD pour déployer la nouvelle structure
echo "📋 Synchronisation ArgoCD..."
oc patch application openshift-ai-complete -n openshift-gitops -p '{"operation":{"sync":{"syncStrategy":{"apply":{"force":true}}}}}' --type merge

echo ""
echo "✅ NETTOYAGE ET REDÉPLOIEMENT TERMINÉS"
echo "======================================"
echo ""
echo "📋 Vérification recommandée :"
echo "oc get modelregistry -A"
echo "oc get pods -n rhoai-model-registries"
echo "oc get applications.argoproj.io -n openshift-gitops"
echo ""
echo "🎯 La nouvelle structure simplifiée suit les patterns RH AI Services BU !"
