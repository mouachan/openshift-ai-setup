#!/bin/bash
set -euo pipefail

# Script de migration de la démo Triton vers le GitOps intégré
# Migration depuis demos/triton-example/gitops/ vers components/instances/triton-demo-instance/

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Variables
OLD_GITOPS_DIR="demos/triton-example/gitops"
NEW_GITOPS_DIR="components/instances/triton-demo-instance"
ARGOCD_NAMESPACE="openshift-gitops"
DEMO_NAMESPACE="triton-demo"

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
    log_step "Vérification des prérequis de migration..."
    
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
    
    # Vérifier que le nouveau GitOps existe
    if [ ! -d "$NEW_GITOPS_DIR" ]; then
        log_error "Nouveau GitOps non trouvé: $NEW_GITOPS_DIR"
        exit 1
    fi
    
    # Vérifier que l'ancien GitOps existe
    if [ ! -d "$OLD_GITOPS_DIR" ]; then
        log_warning "Ancien GitOps non trouvé: $OLD_GITOPS_DIR"
        log_info "Migration non nécessaire - nouveau GitOps déjà en place"
        exit 0
    fi
    
    log_success "Prérequis validés"
}

# Sauvegarde de l'ancien GitOps
backup_old_gitops() {
    log_step "Sauvegarde de l'ancien GitOps..."
    
    BACKUP_DIR="backup/triton-demo-gitops-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp -r "$OLD_GITOPS_DIR" "$BACKUP_DIR/"
    log_success "Sauvegarde créée: $BACKUP_DIR"
}

# Vérification du statut actuel
check_current_status() {
    log_step "Vérification du statut actuel..."
    
    # Vérifier si l'ancien GitOps est déployé
    if oc get namespace "$DEMO_NAMESPACE" &> /dev/null; then
        log_info "Namespace $DEMO_NAMESPACE existe"
        
        # Vérifier les ressources déployées
        RESOURCES=$(oc get all -n "$DEMO_NAMESPACE" --no-headers | wc -l)
        log_info "Ressources déployées: $RESOURCES"
        
        # Vérifier l'application ArgoCD
        if oc get application openshift-ai-complete -n "$ARGOCD_NAMESPACE" &> /dev/null; then
            log_info "Application ArgoCD principale trouvée"
        else
            log_warning "Application ArgoCD principale non trouvée"
        fi
    else
        log_info "Namespace $DEMO_NAMESPACE n'existe pas encore"
    fi
}

# Migration des données (si nécessaire)
migrate_data() {
    log_step "Migration des données..."
    
    # Vérifier s'il y a des données importantes à migrer
    if oc get pvc -n "$DEMO_NAMESPACE" &> /dev/null; then
        log_info "PVCs trouvés - les données seront préservées"
        
        # Lister les PVCs
        oc get pvc -n "$DEMO_NAMESPACE"
    else
        log_info "Aucun PVC trouvé - pas de données à migrer"
    fi
}

# Suppression de l'ancien GitOps
remove_old_gitops() {
    log_step "Suppression de l'ancien GitOps..."
    
    read -p "Voulez-vous supprimer l'ancien GitOps ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Suppression de l'ancien GitOps..."
        
        # Supprimer les ressources de l'ancien GitOps
        if oc delete -k "$OLD_GITOPS_DIR" --ignore-not-found=true; then
            log_success "Ancien GitOps supprimé"
        else
            log_warning "Erreur lors de la suppression de l'ancien GitOps"
        fi
        
        # Supprimer le répertoire local
        rm -rf "$OLD_GITOPS_DIR"
        log_success "Répertoire local supprimé"
    else
        log_info "Suppression annulée - ancien GitOps conservé"
    fi
}

# Déploiement du nouveau GitOps
deploy_new_gitops() {
    log_step "Déploiement du nouveau GitOps intégré..."
    
    # Vérifier que l'application ArgoCD principale existe
    if oc get application openshift-ai-complete -n "$ARGOCD_NAMESPACE" &> /dev/null; then
        log_info "Application ArgoCD principale trouvée - synchronisation..."
        
        # Forcer la synchronisation
        oc patch application openshift-ai-complete -n "$ARGOCD_NAMESPACE" \
            --type='merge' -p='{"spec":{"syncPolicy":{"automated":{"prune":false,"selfHeal":true}}}}'
        
        log_success "Synchronisation ArgoCD déclenchée"
    else
        log_warning "Application ArgoCD principale non trouvée"
        log_info "Déploiement manuel du nouveau GitOps..."
        
        # Déploiement manuel
        oc apply -k "$NEW_GITOPS_DIR/base/"
        log_success "Nouveau GitOps déployé manuellement"
    fi
}

# Vérification du nouveau déploiement
verify_new_deployment() {
    log_step "Vérification du nouveau déploiement..."
    
    # Attendre que le namespace soit créé
    log_info "Attente de la création du namespace..."
    timeout 60 bash -c 'until oc get namespace triton-demo &> /dev/null; do sleep 5; done'
    
    # Vérifier les ressources
    log_info "Vérification des ressources..."
    oc get all -n "$DEMO_NAMESPACE"
    
    # Vérifier les pods
    log_info "Vérification des pods..."
    oc get pods -n "$DEMO_NAMESPACE"
    
    # Vérifier les services
    log_info "Vérification des services..."
    oc get svc -n "$DEMO_NAMESPACE"
    
    log_success "Vérification terminée"
}

# Affichage des informations post-migration
show_post_migration_info() {
    log_step "Informations post-migration..."
    
    echo ""
    echo "🎉 MIGRATION TERMINÉE"
    echo "═══════════════════════════════════════"
    echo ""
    echo "✅ Ancien GitOps: $OLD_GITOPS_DIR"
    echo "✅ Nouveau GitOps: $NEW_GITOPS_DIR"
    echo "✅ Intégré dans: clusters/overlays/openshift-ai-dev/"
    echo ""
    echo "🌐 URLs d'accès:"
    echo "   • Workbench: https://triton-workbench-triton-demo.apps.cluster.local"
    echo "   • Pipelines: https://ds-pipeline-ui-triton-demo-pipelines-triton-demo.apps.cluster.local"
    echo "   • Dashboard: https://rhods-dashboard-redhat-ods-applications.apps.cluster.local/projects/triton-demo"
    echo ""
    echo "🔧 Commandes utiles:"
    echo "   • Statut: oc get all -n triton-demo"
    echo "   • Logs: oc logs -l app.kubernetes.io/name=triton-demo -n triton-demo"
    echo "   • ArgoCD: oc get applications.argoproj.io -n openshift-gitops"
    echo ""
    echo "📚 Documentation:"
    echo "   • Composant: $NEW_GITOPS_DIR/README.md"
    echo "   • Démo: demos/triton-example/README.md"
    echo ""
}

# Fonction principale
main() {
    echo "🔄 MIGRATION TRITON DEMO VERS GITOPS INTÉGRÉ"
    echo "═══════════════════════════════════════════════════"
    echo ""
    
    check_prerequisites
    check_current_status
    backup_old_gitops
    migrate_data
    remove_old_gitops
    deploy_new_gitops
    verify_new_deployment
    show_post_migration_info
}

# Gestion des arguments
case "${1:-}" in
    "migrate")
        main
        ;;
    "backup")
        check_prerequisites
        backup_old_gitops
        ;;
    "status")
        check_current_status
        ;;
    "deploy")
        check_prerequisites
        deploy_new_gitops
        verify_new_deployment
        ;;
    "cleanup")
        check_prerequisites
        remove_old_gitops
        ;;
    *)
        echo "Usage: $0 {migrate|backup|status|deploy|cleanup}"
        echo ""
        echo "Commandes:"
        echo "  migrate  - Migration complète vers le GitOps intégré"
        echo "  backup   - Sauvegarde de l'ancien GitOps"
        echo "  status   - Vérification du statut actuel"
        echo "  deploy   - Déploiement du nouveau GitOps"
        echo "  cleanup  - Suppression de l'ancien GitOps"
        exit 1
        ;;
esac 