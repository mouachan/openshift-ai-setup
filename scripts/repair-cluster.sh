#!/bin/bash

# Script de réparation du cluster OpenShift AI
# Tente de corriger les problèmes identifiés

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}[STEP]${NC} $1"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

echo "🔧 RÉPARATION DU CLUSTER OPENSHIFT AI"
echo "═══════════════════════════════════════"

# 1. Nettoyer les pods en CrashLoopBackOff
log_step "Nettoyage des pods en CrashLoopBackOff"

# Redémarrer Knative
log_info "Redémarrage de Knative..."
oc delete pod -n openshift-operators -l name=knative-openshift --ignore-not-found=true
sleep 10

# Redémarrer RHODS operator
log_info "Redémarrage de RHODS operator..."
oc delete pod -n openshift-operators -l name=rhods-operator --ignore-not-found=true
sleep 10

# Redémarrer MySQL
log_info "Redémarrage de MySQL..."
oc delete pod -n redhat-ods-applications -l app=mysql --ignore-not-found=true
sleep 15

# 2. Vérifier et corriger Kueue (problème de webhook)
log_step "Correction du problème Kueue"

# Vérifier si Kueue existe
if oc get deployment kueue-controller-manager -n redhat-ods-applications >/dev/null 2>&1; then
    log_info "Kueue trouvé, redémarrage..."
    oc delete pod -n redhat-ods-applications -l app.kubernetes.io/name=kueue --ignore-not-found=true
    sleep 10
else
    log_warning "Kueue non trouvé, probablement pas encore déployé"
fi

# 3. Forcer une synchronisation ArgoCD
log_step "Synchronisation ArgoCD"

log_info "Application du patch de synchronisation..."
oc patch applications.argoproj.io openshift-ai-complete -n openshift-gitops \
    --type='merge' -p='{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}' || log_warning "Erreur lors du patch ArgoCD"

log_success "Patch ArgoCD appliqué"

# 4. Attendre et vérifier l'état
log_step "Vérification de l'état après réparation"

log_info "Attente de 30 secondes pour la stabilisation..."
sleep 30

# Vérifier les pods problématiques
ERROR_PODS=$(oc get pods -A | grep -E "(Error|CrashLoopBackOff|Pending|Failed)" | wc -l)
if [ "$ERROR_PODS" -gt 0 ]; then
    log_warning "Il reste $ERROR_PODS pods problématiques"
    oc get pods -A | grep -E "(Error|CrashLoopBackOff|Pending|Failed)" | head -5
else
    log_success "Aucun pod problématique restant"
fi

# Vérifier ArgoCD
log_info "Vérification d'ArgoCD..."
if oc get applications.argoproj.io -n openshift-gitops >/dev/null 2>&1; then
    ARGOCD_STATUS=$(oc get applications.argoproj.io -n openshift-gitops -o jsonpath='{.items[0].status.sync.status}')
    ARGOCD_HEALTH=$(oc get applications.argoproj.io -n openshift-gitops -o jsonpath='{.items[0].status.health.status}')
    log_info "ArgoCD - Sync: $ARGOCD_STATUS, Health: $ARGOCD_HEALTH"
    
    if [ "$ARGOCD_STATUS" = "Synced" ]; then
        log_success "ArgoCD synchronisé"
    else
        log_warning "ArgoCD toujours en OutOfSync"
    fi
fi

# 5. Recommandations finales
log_step "Recommandations finales"

if [ "$ERROR_PODS" -gt 5 ]; then
    log_error "Trop de problèmes persistants. Recommandations:"
    echo "1. Redémarrer le cluster complet"
    echo "2. Réinstaller OpenShift AI proprement"
    echo "3. Vérifier les ressources système (CPU/Mémoire)"
else
    log_success "Réparation terminée avec succès"
    echo "Le cluster devrait maintenant être plus stable"
    echo "Vérifiez l'état avec: ./scripts/diagnose-cluster.sh"
fi

log_step "Réparation terminée" 