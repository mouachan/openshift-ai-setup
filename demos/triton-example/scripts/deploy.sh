#!/bin/bash
set -euo pipefail

# Configuration
DEMO_NAME="triton-example"
NAMESPACE="rhods-notebooks"
MODEL_NAME="iris-classifier-triton"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
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
    
    # Vérifier le namespace
    if ! oc get namespace "$NAMESPACE" &> /dev/null; then
        log_warning "Namespace $NAMESPACE non trouvé. Création..."
        oc create namespace "$NAMESPACE" || {
            log_error "Impossible de créer le namespace $NAMESPACE"
            exit 1
        }
    fi
    
    log_success "Prérequis validés"
}

# Déploiement du modèle
deploy_model() {
    log_info "Déploiement du modèle Iris Triton..."
    
    # Appliquer les configurations Kustomize
    oc apply -k deployment/ -n "$NAMESPACE"
    
    log_success "Configuration appliquée"
}

# Attendre que le déploiement soit prêt
wait_for_deployment() {
    log_info "Attente du déploiement du modèle..."
    
    local timeout=300  # 5 minutes
    local count=0
    
    while [ $count -lt $timeout ]; do
        if oc get inferenceservice "$MODEL_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
            log_success "Modèle déployé et prêt!"
            return 0
        fi
        
        echo -n "."
        sleep 5
        count=$((count + 5))
    done
    
    log_error "Timeout: Le modèle n'est pas prêt après $timeout secondes"
    return 1
}

# Obtenir l'URL du service
get_service_url() {
    log_info "Récupération de l'URL du service..."
    
    local url
    url=$(oc get inferenceservice "$MODEL_NAME" -n "$NAMESPACE" -o jsonpath='{.status.url}')
    
    if [ -n "$url" ]; then
        log_success "URL du service: $url"
        echo "$url"
    else
        log_error "Impossible de récupérer l'URL du service"
        return 1
    fi
}

# Test d'inférence
test_inference() {
    local service_url="$1"
    
    log_info "Test d'inférence..."
    
    # Vérifier si Python et les dépendances sont disponibles
    if command -v python3 &> /dev/null; then
        if python3 -c "import requests" &> /dev/null; then
            log_info "Lancement du test d'inférence avec Python..."
            python3 scripts/test_inference.py --url "$service_url"
        else
            log_warning "Module 'requests' non disponible. Test d'inférence Python ignoré."
            log_info "Pour installer: pip install requests"
        fi
    else
        log_warning "Python3 non disponible. Test d'inférence ignoré."
    fi
    
    # Test basique avec curl
    log_info "Test de santé avec curl..."
    if command -v curl &> /dev/null; then
        local health_url="${service_url}/v2/health/ready"
        if curl -s "$health_url" | grep -q "true\|ready"; then
            log_success "Service accessible et prêt"
        else
            log_warning "Service non prêt ou inaccessible"
        fi
    fi
}

# Affichage des informations de déploiement
show_deployment_info() {
    local service_url="$1"
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "🎉 DÉPLOIEMENT TRITON DEMO TERMINÉ"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "📋 Informations de déploiement:"
    echo "   • Modèle: $MODEL_NAME"
    echo "   • Namespace: $NAMESPACE"
    echo "   • URL: $service_url"
    echo ""
    echo "🔧 Commandes utiles:"
    echo "   • Statut: oc get inferenceservice $MODEL_NAME -n $NAMESPACE"
    echo "   • Logs: oc logs -l app.kubernetes.io/name=iris-classifier -n $NAMESPACE"
    echo "   • Events: oc get events -n $NAMESPACE --sort-by='.lastTimestamp'"
    echo ""
    echo "🧪 Test d'inférence:"
    echo "   python3 scripts/test_inference.py --url $service_url"
    echo ""
    echo "🌐 OpenShift AI Console:"
    echo "   Allez dans Data Science Projects > $NAMESPACE > Models"
    echo ""
}

# Nettoyage en cas d'erreur
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "Erreur détectée. Nettoyage..."
        oc delete inferenceservice "$MODEL_NAME" -n "$NAMESPACE" 2>/dev/null || true
    fi
}

# Configuration du trap pour le nettoyage
trap cleanup EXIT

# Fonction principale
main() {
    echo "🚀 DÉPLOIEMENT DEMO TRITON INFERENCE"
    echo "══════════════════════════════════════"
    
    check_prerequisites
    deploy_model
    
    if wait_for_deployment; then
        local service_url
        service_url=$(get_service_url)
        test_inference "$service_url"
        show_deployment_info "$service_url"
    else
        log_error "Échec du déploiement"
        exit 1
    fi
}

# Gestion des arguments
case "${1:-}" in
    "deploy")
        main
        ;;
    "undeploy")
        log_info "Suppression du déploiement..."
        oc delete -k deployment/ -n "$NAMESPACE" || true
        log_success "Déploiement supprimé"
        ;;
    "status")
        log_info "Statut du déploiement:"
        oc get inferenceservice "$MODEL_NAME" -n "$NAMESPACE" -o wide
        ;;
    "logs")
        log_info "Logs du déploiement:"
        oc logs -l app.kubernetes.io/name=iris-classifier -n "$NAMESPACE" --tail=100
        ;;
    "test")
        service_url=$(oc get inferenceservice "$MODEL_NAME" -n "$NAMESPACE" -o jsonpath='{.status.url}')
        if [ -n "$service_url" ]; then
            test_inference "$service_url"
        else
            log_error "Service non déployé ou URL non disponible"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {deploy|undeploy|status|logs|test}"
        echo ""
        echo "Commandes:"
        echo "  deploy   - Déploie le modèle Iris Triton"
        echo "  undeploy - Supprime le déploiement"
        echo "  status   - Affiche le statut du déploiement"
        echo "  logs     - Affiche les logs"
        echo "  test     - Lance le test d'inférence"
        exit 1
        ;;
esac
