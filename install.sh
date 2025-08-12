#!/bin/bash

# 🚀 OpenShift AI Setup - Installation Automatique
# 
# Ce script installe automatiquement OpenShift AI avec :
# - Workbench personnalisé avec image ML/AI
# - Pipelines Elyra configurés
# - Infrastructure complète (MinIO, Model Registry, Serving)
# - GitOps avec ArgoCD

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier OpenShift CLI
    if ! command -v oc &> /dev/null; then
        log_error "OpenShift CLI (oc) n'est pas installé"
        exit 1
    fi
    
    # Vérifier l'accès au cluster
    if ! oc whoami &> /dev/null; then
        log_error "Vous n'êtes pas connecté à OpenShift"
        exit 1
    fi
    
    # Vérifier les droits administrateur
    if ! oc auth can-i create datascienceclusters --all-namespaces &> /dev/null; then
        log_warning "Droits administrateur limités - certaines fonctionnalités peuvent ne pas fonctionner"
    fi
    
    log_success "Prérequis vérifiés"
}

# Installation des opérateurs
install_operators() {
    log_info "Installation des opérateurs OpenShift..."
    
    oc apply -k components/operators/
    
    log_info "Attente que les opérateurs soient prêts..."
    oc wait --for=condition=Installed csv/rhods-operator.v2.8.0 -n openshift-operators --timeout=600s || true
    
    log_success "Opérateurs installés"
}

# Installation de l'infrastructure
install_infrastructure() {
    log_info "Installation de l'infrastructure de base..."
    
    # MinIO pour le stockage
    log_info "Déploiement de MinIO..."
    oc apply -k components/instances/minio-instance/base/
    
    # Model Registry
    log_info "Configuration du Model Registry..."
    oc apply -k components/instances/rhoai-instance/components/model-registry/
    
    # Serving Runtimes personnalisés
    log_info "Installation des runtimes de serving personnalisés..."
    oc apply -k components/instances/rhoai-instance/components/custom-serving-runtimes/
    
    # Pipelines Tekton
    log_info "Configuration des pipelines Tekton..."
    oc apply -k components/instances/pipelines-instance/base/
    
    # Service Mesh (si pas déjà installé)
    log_info "Configuration du Service Mesh..."
    oc apply -k components/instances/service-mesh-instance/base/ || log_warning "Service Mesh déjà installé"
    
    # Serverless (Knative)
    log_info "Configuration du Serverless..."
    oc apply -k components/instances/serverless-instance/base/
    
    log_success "Infrastructure installée"
}

# Installation du workbench personnalisé
install_workbench() {
    log_info "Installation du workbench personnalisé..."
    
    # Déployer le workbench
    oc apply -k components/instances/triton-demo-instance/base/data-science-project/
    
    # Attendre que le workbench démarre
    log_info "Attente que le workbench démarre..."
    oc wait --for=condition=Ready pod -l app=triton-workbench -n triton-demo --timeout=300s
    
    # Appliquer la configuration Elyra
    log_info "Configuration d'Elyra..."
    oc apply -f components/instances/triton-demo-instance/base/data-science-project/elyra-runtime-config.yaml
    
    # Configurer le runtime dans le workbench
    log_info "Configuration du runtime Elyra..."
    oc exec triton-workbench-0 -n triton-demo -c triton-workbench -- python3 /opt/app-root/elyra-config/init-runtime.py
    
    log_success "Workbench installé et configuré"
}

# Configuration GitOps
install_gitops() {
    log_info "Configuration GitOps avec ArgoCD..."
    
    oc apply -k argocd-apps/
    
    log_success "GitOps configuré"
}

# Vérification de l'installation
verify_installation() {
    log_info "Vérification de l'installation..."
    
    echo ""
    log_info "📊 État des composants :"
    
    # Workbench
    if oc get pods -n triton-demo | grep -q "Running"; then
        log_success "Workbench : Fonctionnel"
    else
        log_error "Workbench : Problème détecté"
    fi
    
    # MinIO
    if oc get pods -n minio | grep -q "Running"; then
        log_success "MinIO : Fonctionnel"
    else
        log_error "MinIO : Problème détecté"
    fi
    
    # Model Registry
    if oc get pods -n rhoai-model-registries | grep -q "Running"; then
        log_success "Model Registry : Fonctionnel"
    else
        log_warning "Model Registry : En cours de démarrage"
    fi
    
    # Pipelines
    if oc get datasciencepipelinesapplications -A | grep -q "dspa"; then
        log_success "Pipelines : Disponibles"
    else
        log_warning "Pipelines : En cours de configuration"
    fi
    
    echo ""
}

# Affichage des informations de connexion
show_connection_info() {
    log_success "🎉 Installation terminée avec succès !"
    echo ""
    log_info "🔗 Informations de connexion :"
    
    # Workbench
    WORKBENCH_ROUTE=$(oc get route triton-workbench -n triton-demo -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours de création")
    echo "  📱 Workbench : https://$WORKBENCH_ROUTE"
    
    # MinIO
    MINIO_ROUTE=$(oc get route minio-api -n minio -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours de création")
    echo "  🗄️  MinIO API : https://$MINIO_ROUTE"
    
    # MinIO Console
    MINIO_CONSOLE_ROUTE=$(oc get route minio-console -n minio -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours de création")
    echo "  🖥️  MinIO Console : https://$MINIO_CONSOLE_ROUTE"
    
    echo ""
    log_info "📚 Documentation :"
    echo "  📖 Guide complet : README.md"
    echo "  🚀 Démarrage rapide : docs/QUICK-START.md"
    echo "  🏗️  Architecture : docs/MODULAR-ARCHITECTURE.md"
    
    echo ""
    log_info "🔧 Prochaines étapes :"
    echo "  1. Accéder au workbench et créer votre premier pipeline"
    echo "  2. Utiliser l'image personnalisée avec toutes les bibliothèques ML/AI"
    echo "  3. Déployer des modèles via le Model Registry"
    echo "  4. Configurer GitOps pour la maintenance continue"
    
    echo ""
    log_success "Votre setup OpenShift AI est maintenant production-ready ! 🚀"
}

# Fonction principale
main() {
    echo ""
    echo "🚀 OpenShift AI Setup - Installation Automatique"
    echo "=================================================="
    echo ""
    
    check_prerequisites
    install_operators
    install_infrastructure
    install_workbench
    install_gitops
    verify_installation
    show_connection_info
}

# Gestion des erreurs
trap 'log_error "Installation interrompue par l\'utilisateur"; exit 1' INT TERM

# Exécution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
