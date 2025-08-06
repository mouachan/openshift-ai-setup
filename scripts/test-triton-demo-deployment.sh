#!/bin/bash
set -euo pipefail

# Script de test pour vérifier le déploiement de la démo Triton sur le cluster

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Variables
DEMO_NAMESPACE="triton-demo"
ARGOCD_NAMESPACE="openshift-gitops"
RHOAI_NAMESPACE="redhat-ods-applications"

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
check_argocd_application() {
    log_step "Vérification de l'application ArgoCD..."
    
    if oc get applications.argoproj.io openshift-ai-complete -n "$ARGOCD_NAMESPACE" &> /dev/null; then
        log_success "Application ArgoCD principale trouvée"
        
        # Vérifier le statut de synchronisation
        SYNC_STATUS=$(oc get applications.argoproj.io openshift-ai-complete -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.status}')
        HEALTH_STATUS=$(oc get applications.argoproj.io openshift-ai-complete -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.health.status}')
        
        log_info "Statut de synchronisation: $SYNC_STATUS"
        log_info "Statut de santé: $HEALTH_STATUS"
        
        if [ "$SYNC_STATUS" = "Synced" ] && [ "$HEALTH_STATUS" = "Healthy" ]; then
            log_success "Application ArgoCD synchronisée et en bonne santé"
        else
            log_warning "Application ArgoCD pas encore synchronisée"
        fi
    else
        log_error "Application ArgoCD principale non trouvée"
        log_info "Déployez d'abord l'application ArgoCD:"
        log_info "oc apply -f argocd-apps/openshift-ai-application.yaml"
        exit 1
    fi
}

# Vérification du namespace de la démo
check_demo_namespace() {
    log_step "Vérification du namespace de la démo..."
    
    if oc get namespace "$DEMO_NAMESPACE" &> /dev/null; then
        log_success "Namespace $DEMO_NAMESPACE trouvé"
        
        # Vérifier les labels OpenShift AI
        if oc get namespace "$DEMO_NAMESPACE" -o jsonpath='{.metadata.labels.opendatahub\.io/dashboard}' | grep -q "true"; then
            log_success "Namespace configuré pour OpenShift AI Dashboard"
        else
            log_warning "Namespace non configuré pour OpenShift AI Dashboard"
        fi
    else
        log_warning "Namespace $DEMO_NAMESPACE non trouvé"
        log_info "Le namespace sera créé automatiquement par ArgoCD"
    fi
}

# Vérification des ressources de la démo
check_demo_resources() {
    log_step "Vérification des ressources de la démo..."
    
    if oc get namespace "$DEMO_NAMESPACE" &> /dev/null; then
        # Vérifier les pods
        PODS=$(oc get pods -n "$DEMO_NAMESPACE" --no-headers 2>/dev/null | wc -l)
        if [ "$PODS" -gt 0 ]; then
            log_success "Pods trouvés: $PODS"
            
            # Vérifier le statut des pods
            RUNNING_PODS=$(oc get pods -n "$DEMO_NAMESPACE" --no-headers 2>/dev/null | grep -c "Running" || echo "0")
            log_info "Pods en cours d'exécution: $RUNNING_PODS/$PODS"
        else
            log_warning "Aucun pod trouvé dans le namespace"
        fi
        
        # Vérifier les services
        SERVICES=$(oc get svc -n "$DEMO_NAMESPACE" --no-headers 2>/dev/null | wc -l)
        if [ "$SERVICES" -gt 0 ]; then
            log_success "Services trouvés: $SERVICES"
        else
            log_warning "Aucun service trouvé dans le namespace"
        fi
        
        # Vérifier les routes
        ROUTES=$(oc get route -n "$DEMO_NAMESPACE" --no-headers 2>/dev/null | wc -l)
        if [ "$ROUTES" -gt 0 ]; then
            log_success "Routes trouvées: $ROUTES"
            
            # Afficher les URLs
            log_info "URLs disponibles:"
            oc get route -n "$DEMO_NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}: https://{.spec.host}{"\n"}{end}' 2>/dev/null || true
        else
            log_warning "Aucune route trouvée dans le namespace"
        fi
    else
        log_warning "Namespace $DEMO_NAMESPACE non trouvé - ressources non vérifiées"
    fi
}

# Vérification du workbench
check_workbench() {
    log_step "Vérification du workbench..."
    
    if oc get notebook triton-workbench -n "$DEMO_NAMESPACE" &> /dev/null; then
        log_success "Workbench Triton trouvé"
        
        # Vérifier le statut du workbench
        WORKBENCH_STATUS=$(oc get notebook triton-workbench -n "$DEMO_NAMESPACE" -o jsonpath='{.status.ready}' 2>/dev/null || echo "Unknown")
        log_info "Statut du workbench: $WORKBENCH_STATUS"
        
        if [ "$WORKBENCH_STATUS" = "true" ]; then
            log_success "Workbench prêt"
            
            # Vérifier les logs du workbench pour le clonage GitHub
            if oc logs -l app.kubernetes.io/name=triton-workbench -n "$DEMO_NAMESPACE" --tail=50 2>/dev/null | grep -q "Démo Triton clonée"; then
                log_success "Démo Triton clonée avec succès depuis GitHub"
            else
                log_warning "Clonage GitHub non détecté dans les logs"
            fi
        else
            log_warning "Workbench pas encore prêt"
        fi
    else
        log_warning "Workbench Triton non trouvé"
    fi
}

# Vérification du pipeline server
check_pipeline_server() {
    log_step "Vérification du pipeline server..."
    
    if oc get datasciencepipelinesapplication triton-demo-pipelines -n "$DEMO_NAMESPACE" &> /dev/null; then
        log_success "Pipeline server trouvé"
        
        # Vérifier le statut du pipeline server
        PIPELINE_STATUS=$(oc get datasciencepipelinesapplication triton-demo-pipelines -n "$DEMO_NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
        log_info "Statut du pipeline server: $PIPELINE_STATUS"
        
        if [ "$PIPELINE_STATUS" = "True" ]; then
            log_success "Pipeline server prêt"
        else
            log_warning "Pipeline server pas encore prêt"
        fi
    else
        log_warning "Pipeline server non trouvé"
    fi
}

# Vérification du model serving
check_model_serving() {
    log_step "Vérification du model serving..."
    
    if oc get inferenceservice iris-classifier-triton -n "$DEMO_NAMESPACE" &> /dev/null; then
        log_success "Inference service trouvé"
        
        # Vérifier le statut de l'inference service
        INFERENCE_STATUS=$(oc get inferenceservice iris-classifier-triton -n "$DEMO_NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
        log_info "Statut de l'inference service: $INFERENCE_STATUS"
        
        if [ "$INFERENCE_STATUS" = "True" ]; then
            log_success "Inference service prêt"
            
            # Récupérer l'URL du service
            SERVICE_URL=$(oc get inferenceservice iris-classifier-triton -n "$DEMO_NAMESPACE" -o jsonpath='{.status.url}' 2>/dev/null || echo "")
            if [ -n "$SERVICE_URL" ]; then
                log_success "URL du service: $SERVICE_URL"
            fi
        else
            log_warning "Inference service pas encore prêt"
        fi
    else
        log_warning "Inference service non trouvé"
    fi
}

# Test d'inférence
test_inference() {
    log_step "Test d'inférence..."
    
    # Récupérer l'URL du service
    SERVICE_URL=$(oc get inferenceservice iris-classifier-triton -n "$DEMO_NAMESPACE" -o jsonpath='{.status.url}' 2>/dev/null || echo "")
    
    if [ -n "$SERVICE_URL" ]; then
        log_info "Test d'inférence sur: $SERVICE_URL"
        
        # Test de santé
        if curl -s -f "$SERVICE_URL/v2/health/ready" &> /dev/null; then
            log_success "Service d'inférence en bonne santé"
            
            # Test d'inférence simple
            if curl -s -X POST "$SERVICE_URL/v2/models/iris_classifier/versions/1/infer" \
                -H "Content-Type: application/json" \
                -d '{
                  "inputs": [
                    {
                      "name": "input_features",
                      "shape": [1, 4],
                      "datatype": "FP32",
                      "data": [5.1, 3.5, 1.4, 0.2]
                    }
                  ],
                  "outputs": [
                    {"name": "predictions"},
                    {"name": "probabilities"}
                  ]
                }' &> /dev/null; then
                log_success "Test d'inférence réussi"
            else
                log_warning "Test d'inférence échoué"
            fi
        else
            log_warning "Service d'inférence non accessible"
        fi
    else
        log_warning "URL du service non disponible"
    fi
}

# Affichage des informations d'accès
show_access_info() {
    log_step "Informations d'accès..."
    
    echo ""
    echo "🌐 URLs d'accès:"
    echo "═══════════════════════"
    echo ""
    
    # Dashboard OpenShift AI
    DASHBOARD_URL="https://rhods-dashboard-$RHOAI_NAMESPACE.apps.$(oc get infrastructure cluster -o jsonpath='{.status.apiServerURL}' | sed 's|https://api\.||' | sed 's|:6443||')/projects/$DEMO_NAMESPACE"
    echo "📊 Dashboard OpenShift AI: $DASHBOARD_URL"
    
    # Workbench
    WORKBENCH_URL="https://triton-workbench-$DEMO_NAMESPACE.apps.$(oc get infrastructure cluster -o jsonpath='{.status.apiServerURL}' | sed 's|https://api\.||' | sed 's|:6443||')"
    echo "💻 Workbench Jupyter: $WORKBENCH_URL"
    
    # Pipeline UI
    PIPELINE_URL="https://ds-pipeline-ui-$DEMO_NAMESPACE-pipelines-$DEMO_NAMESPACE.apps.$(oc get infrastructure cluster -o jsonpath='{.status.apiServerURL}' | sed 's|https://api\.||' | sed 's|:6443||')"
    echo "🔧 Pipeline UI: $PIPELINE_URL"
    
    # Inference Service
    INFERENCE_URL=$(oc get inferenceservice iris-classifier-triton -n "$DEMO_NAMESPACE" -o jsonpath='{.status.url}' 2>/dev/null || echo "Non disponible")
    echo "🤖 Inference Service: $INFERENCE_URL"
    
    echo ""
    echo "🔧 Commandes utiles:"
    echo "═══════════════════════"
    echo ""
    echo "• Statut global: oc get all -n $DEMO_NAMESPACE"
    echo "• Logs workbench: oc logs -l app.kubernetes.io/name=triton-workbench -n $DEMO_NAMESPACE"
    echo "• Statut ArgoCD: oc get applications.argoproj.io -n $ARGOCD_NAMESPACE"
    echo "• Events: oc get events -n $DEMO_NAMESPACE --sort-by='.lastTimestamp'"
    echo ""
}

# Fonction principale
main() {
    echo "🧪 TEST DU DÉPLOIEMENT TRITON DEMO"
    echo "═══════════════════════════════════"
    echo ""
    
    check_prerequisites
    check_argocd_application
    check_demo_namespace
    check_demo_resources
    check_workbench
    check_pipeline_server
    check_model_serving
    test_inference
    show_access_info
    
    echo "🎉 Test terminé !"
    echo "═══════════════════"
    echo ""
    echo "✅ Vérifiez les URLs d'accès ci-dessus"
    echo "✅ Le workbench clone automatiquement la démo depuis GitHub"
    echo "✅ Tous les composants sont intégrés dans le GitOps principal"
    echo ""
}

# Exécution
main 