#!/bin/bash

# Script de test pour le nouveau cluster
# Vérifie l'état du déploiement OpenShift AI + Démo Triton

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

echo "🧪 TEST DU NOUVEAU CLUSTER OPENSHIFT AI"
echo "═══════════════════════════════════════"

# 1. Vérification générale du cluster
log_step "Vérification générale du cluster"

log_info "Nodes du cluster:"
oc get nodes -o wide

log_info "Pods problématiques:"
ERROR_PODS=$(oc get pods -A | grep -E "(Error|CrashLoopBackOff|Pending|Failed)" | wc -l)
if [ "$ERROR_PODS" -gt 0 ]; then
    log_warning "Trouvé $ERROR_PODS pods problématiques"
    oc get pods -A | grep -E "(Error|CrashLoopBackOff|Pending|Failed)" | head -5
else
    log_success "Aucun pod problématique trouvé"
fi

# 2. Vérification des opérateurs
log_step "Vérification des opérateurs"

log_info "Opérateurs dans openshift-operators:"
oc get pods -n openshift-operators | grep -E "(rhods|knative|gitops|pipeline)" | head -5

log_info "Opérateurs dans redhat-ods-operator:"
oc get pods -n redhat-ods-operator 2>/dev/null || log_warning "Namespace redhat-ods-operator non trouvé"

# 3. Vérification de RHOAI
log_step "Vérification de RHOAI"

if oc get namespace redhat-ods-applications >/dev/null 2>&1; then
    log_info "Pods RHOAI:"
    oc get pods -n redhat-ods-applications
    
    log_info "Services RHOAI:"
    oc get services -n redhat-ods-applications | head -5
    
    log_info "Routes RHOAI:"
    oc get routes -n redhat-ods-applications 2>/dev/null || log_warning "Aucune route trouvée"
else
    log_warning "Namespace redhat-ods-applications non trouvé"
fi

# 4. Vérification de la démo Triton
log_step "Vérification de la démo Triton"

if oc get namespace triton-demo >/dev/null 2>&1; then
    log_info "Pods de la démo Triton:"
    oc get pods -n triton-demo
    
    log_info "Ressources de la démo Triton:"
    oc get datasciencepipelinesapplication -n triton-demo 2>/dev/null || log_warning "Aucun pipeline trouvé"
    oc get notebook -n triton-demo 2>/dev/null || log_warning "Aucun notebook trouvé"
    oc get inferenceservice -n triton-demo 2>/dev/null || log_warning "Aucun service d'inférence trouvé"
    
    log_info "Services de la démo:"
    oc get services -n triton-demo 2>/dev/null || log_warning "Aucun service trouvé"
    
    log_info "Routes de la démo:"
    oc get routes -n triton-demo 2>/dev/null || log_warning "Aucune route trouvée"
else
    log_warning "Namespace triton-demo non trouvé"
fi

# 5. Vérification d'ArgoCD
log_step "Vérification d'ArgoCD"

if oc get namespace openshift-gitops >/dev/null 2>&1; then
    log_info "Pods ArgoCD:"
    oc get pods -n openshift-gitops
    
    log_info "Applications ArgoCD:"
    oc get applications.argoproj.io -n openshift-gitops 2>/dev/null || log_warning "Aucune application trouvée"
else
    log_warning "Namespace openshift-gitops non trouvé"
fi

# 6. Vérification des ressources système
log_step "Ressources système"

log_info "Utilisation CPU et mémoire:"
oc adm top nodes | head -5

log_info "PVCs créés:"
oc get pvc -A | grep -E "(triton|redhat-ods)" | head -5

# 7. Recommandations
log_step "Recommandations"

if [ "$ERROR_PODS" -gt 10 ]; then
    log_error "Trop de problèmes détectés. Recommandations:"
    echo "1. Vérifier les ressources du cluster"
    echo "2. Attendre que les opérateurs se stabilisent"
    echo "3. Redémarrer les pods problématiques"
elif [ "$ERROR_PODS" -gt 0 ]; then
    log_warning "Quelques problèmes détectés. Recommandations:"
    echo "1. Attendre que les opérateurs se stabilisent"
    echo "2. Vérifier les logs des pods en erreur"
    echo "3. Relancer le déploiement de la démo"
else
    log_success "Cluster en bon état !"
    echo "✅ Le déploiement semble réussi"
    echo "🎯 Testez la démo Triton via le dashboard RHOAI"
fi

log_step "Test terminé" 