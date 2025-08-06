#!/bin/bash
set -euo pipefail

# Script pour forcer la synchronisation de l'application ArgoCD

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Variables
ARGOCD_NAMESPACE="openshift-gitops"
APPLICATION_NAME="openshift-ai-complete"

# Fonctions utilitaires
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
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Vérification des prérequis
check_prerequisites() {
    log_step "Vérification des prérequis..."
    
    # Vérifier oc CLI
    if ! command -v oc &> /dev/null; then
        log_error "OpenShift CLI (oc) non trouvé. Veuillez l'installer."
        exit 1
    fi
    
    # Vérifier la connexion au cluster
    if ! oc whoami &> /dev/null; then
        log_error "Non connecté au cluster OpenShift. Veuillez vous connecter avec 'oc login'."
        exit 1
    fi
    
    log_success "Prérequis validés"
}

# Vérification de l'application ArgoCD
check_application() {
    log_step "Vérification de l'application ArgoCD..."
    
    if oc get applications.argoproj.io "$APPLICATION_NAME" -n "$ARGOCD_NAMESPACE" &> /dev/null; then
        log_success "Application ArgoCD trouvée: $APPLICATION_NAME"
        
        # Afficher le statut actuel
        SYNC_STATUS=$(oc get applications.argoproj.io "$APPLICATION_NAME" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        HEALTH_STATUS=$(oc get applications.argoproj.io "$APPLICATION_NAME" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
        
        log_info "Statut actuel - Sync: $SYNC_STATUS, Health: $HEALTH_STATUS"
    else
        log_error "Application ArgoCD non trouvée: $APPLICATION_NAME"
        log_info "Déployez d'abord l'application:"
        log_info "oc apply -f argocd-apps/openshift-ai-application.yaml"
        exit 1
    fi
}

# Forcer la synchronisation
force_sync() {
    log_step "Forçage de la synchronisation..."
    
    log_info "Application: $APPLICATION_NAME"
    log_info "Namespace: $ARGOCD_NAMESPACE"
    
    # Patch pour forcer la synchronisation
    log_info "Application du patch de synchronisation..."
    
    oc patch applications.argoproj.io "$APPLICATION_NAME" -n "$ARGOCD_NAMESPACE" \
        --type='merge' -p='{
            "spec": {
                "syncPolicy": {
                    "automated": {
                        "prune": false,
                        "selfHeal": true
                    }
                }
            }
        }'
    
    if [ $? -eq 0 ]; then
        log_success "Patch appliqué avec succès"
    else
        log_error "Erreur lors de l'application du patch"
        exit 1
    fi
    
    # Forcer une synchronisation manuelle
    log_info "Forçage d'une synchronisation manuelle..."
    oc patch applications.argoproj.io "$APPLICATION_NAME" -n "$ARGOCD_NAMESPACE" \
        --type='merge' -p='{"spec":{"syncPolicy":{"syncOptions":["CreateNamespace=true","ApplyOutOfSyncOnly=true"]}}}'
    
    if [ $? -eq 0 ]; then
        log_success "Synchronisation manuelle déclenchée"
    else
        log_warning "Erreur lors de la synchronisation manuelle"
    fi
}

# Attendre la synchronisation
wait_for_sync() {
    log_step "Attente de la synchronisation..."
    
    log_info "Surveillance de la synchronisation..."
    log_info "Appuyez sur Ctrl+C pour arrêter la surveillance"
    
    # Boucle de surveillance
    while true; do
        SYNC_STATUS=$(oc get applications.argoproj.io "$APPLICATION_NAME" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        HEALTH_STATUS=$(oc get applications.argoproj.io "$APPLICATION_NAME" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
        
        echo -n -e "\r${BLUE}[INFO]${NC} Sync: $SYNC_STATUS, Health: $HEALTH_STATUS"
        
        if [ "$SYNC_STATUS" = "Synced" ]; then
            echo ""
            log_success "Synchronisation terminée !"
            if [ "$HEALTH_STATUS" = "Healthy" ]; then
                log_success "Application en bonne santé"
            else
                log_warning "Application avec des problèmes de santé: $HEALTH_STATUS"
            fi
            break
        fi
        
        sleep 5
    done
}

# Vérification rapide du déploiement
quick_check() {
    log_step "Vérification rapide du déploiement..."
    
    # Vérifier le namespace de la démo
    if oc get namespace triton-demo &> /dev/null; then
        log_success "Namespace triton-demo créé"
        
        # Compter les ressources
        RESOURCES=$(oc get all -n triton-demo --no-headers 2>/dev/null | wc -l)
        log_info "Ressources dans triton-demo: $RESOURCES"
        
        # Vérifier le workbench
        if oc get notebook triton-workbench -n triton-demo &> /dev/null; then
            log_success "Workbench Triton déployé"
        else
            log_warning "Workbench Triton pas encore déployé"
        fi
    else
        log_warning "Namespace triton-demo pas encore créé"
    fi
}

# Affichage des URLs
show_urls() {
    log_step "URLs d'accès..."
    
    echo ""
    echo "🌐 URLs d'accès:"
    echo "═══════════════════════"
    echo ""
    
    # Dashboard OpenShift AI
    DASHBOARD_URL="https://rhods-dashboard-redhat-ods-applications.apps.$(oc get infrastructure cluster -o jsonpath='{.status.apiServerURL}' | sed 's|https://api\.||' | sed 's|:6443||')/projects/triton-demo"
    echo "📊 Dashboard OpenShift AI: $DASHBOARD_URL"
    
    # Workbench
    WORKBENCH_URL="https://triton-workbench-triton-demo.apps.$(oc get infrastructure cluster -o jsonpath='{.status.apiServerURL}' | sed 's|https://api\.||' | sed 's|:6443||')"
    echo "💻 Workbench Jupyter: $WORKBENCH_URL"
    
    # Pipeline UI
    PIPELINE_URL="https://ds-pipeline-ui-triton-demo-pipelines-triton-demo.apps.$(oc get infrastructure cluster -o jsonpath='{.status.apiServerURL}' | sed 's|https://api\.||' | sed 's|:6443||')"
    echo "🔧 Pipeline UI: $PIPELINE_URL"
    
    echo ""
    echo "🔧 Commandes utiles:"
    echo "═══════════════════════"
    echo ""
    echo "• Test complet: ./scripts/test-triton-demo-deployment.sh"
    echo "• Statut global: oc get all -n triton-demo"
    echo "• Logs workbench: oc logs -l app.kubernetes.io/name=triton-workbench -n triton-demo"
    echo ""
}

# Fonction principale
main() {
    echo "🔄 SYNCHRONISATION ARGOCD - TRITON DEMO"
    echo "═══════════════════════════════════════"
    echo ""
    
    check_prerequisites
    check_application
    force_sync
    wait_for_sync
    quick_check
    show_urls
    
    echo "🎉 Synchronisation terminée !"
    echo "═══════════════════════════"
    echo ""
    echo "✅ L'application ArgoCD a été synchronisée"
    echo "✅ La démo Triton devrait être déployée"
    echo "✅ Vérifiez les URLs d'accès ci-dessus"
    echo ""
    echo "🚀 Pour un test complet, exécutez:"
    echo "   ./scripts/test-triton-demo-deployment.sh"
    echo ""
}

# Gestion des arguments
case "${1:-}" in
    "sync")
        main
        ;;
    "check")
        check_prerequisites
        check_application
        quick_check
        show_urls
        ;;
    "urls")
        show_urls
        ;;
    *)
        echo "Usage: $0 {sync|check|urls}"
        echo ""
        echo "Commandes:"
        echo "  sync   - Forcer la synchronisation ArgoCD"
        echo "  check  - Vérification rapide du statut"
        echo "  urls   - Afficher les URLs d'accès"
        exit 1
        ;;
esac 