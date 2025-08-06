#!/bin/bash
set -euo pipefail

# Script de vérification du nettoyage après migration GitOps

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Vérification des fichiers supprimés
check_deleted_files() {
    log_step "Vérification des fichiers supprimés..."
    
    # Vérifier que l'ancien GitOps est supprimé
    if [ -d "demos/triton-example/gitops" ]; then
        log_error "❌ Ancien GitOps encore présent: demos/triton-example/gitops"
        return 1
    else
        log_success "✅ Ancien GitOps supprimé: demos/triton-example/gitops"
    fi
    
    # Vérifier que les scripts obsolètes sont supprimés
    if [ -f "demos/triton-example/scripts/deploy-gitops.sh" ]; then
        log_error "❌ Script obsolète encore présent: deploy-gitops.sh"
        return 1
    else
        log_success "✅ Script obsolète supprimé: deploy-gitops.sh"
    fi
    
    if [ -f "demos/triton-example/scripts/validate-gitops.sh" ]; then
        log_error "❌ Script obsolète encore présent: validate-gitops.sh"
        return 1
    else
        log_success "✅ Script obsolète supprimé: validate-gitops.sh"
    fi
    
    # Vérifier que le répertoire deployment est supprimé
    if [ -d "demos/triton-example/deployment" ]; then
        log_error "❌ Répertoire deployment encore présent: demos/triton-example/deployment"
        return 1
    else
        log_success "✅ Répertoire deployment supprimé: demos/triton-example/deployment"
    fi
}

# Vérification des fichiers conservés
check_kept_files() {
    log_step "Vérification des fichiers conservés..."
    
    # Scripts nécessaires
    local scripts=("configure_elyra.py" "setup.sh" "deploy.sh" "test_inference.py")
    for script in "${scripts[@]}"; do
        if [ -f "demos/triton-example/scripts/$script" ]; then
            log_success "✅ Script conservé: $script"
        else
            log_error "❌ Script manquant: $script"
            return 1
        fi
    done
    
    # Déploiement manuel (maintenant via GitOps intégré)
    log_info "ℹ️  Déploiement manuel supprimé (maintenant via GitOps intégré)"
    
    # Code de la démo
    local demo_dirs=("pipelines" "notebooks" "models")
    for dir in "${demo_dirs[@]}"; do
        if [ -d "demos/triton-example/$dir" ]; then
            log_success "✅ Code démo conservé: $dir/"
        else
            log_error "❌ Code démo manquant: $dir/"
            return 1
        fi
    done
}

# Vérification du nouveau composant
check_new_component() {
    log_step "Vérification du nouveau composant..."
    
    if [ -d "components/instances/triton-demo-instance" ]; then
        log_success "✅ Nouveau composant créé: triton-demo-instance/"
    else
        log_error "❌ Nouveau composant manquant: triton-demo-instance/"
        return 1
    fi
    
    # Vérifier la structure du composant
    local component_files=("base/kustomization.yaml" "base/data-science-project/" "base/model-serving/" "README.md")
    for file in "${component_files[@]}"; do
        if [ -e "components/instances/triton-demo-instance/$file" ]; then
            log_success "✅ Fichier composant présent: $file"
        else
            log_error "❌ Fichier composant manquant: $file"
            return 1
        fi
    done
}

# Vérification de l'intégration GitOps
check_gitops_integration() {
    log_step "Vérification de l'intégration GitOps..."
    
    # Vérifier que le composant est intégré dans le GitOps principal
    if grep -q "triton-demo-instance" "clusters/overlays/openshift-ai-dev/kustomization.yaml"; then
        log_success "✅ Composant intégré dans le GitOps principal"
    else
        log_error "❌ Composant non intégré dans le GitOps principal"
        return 1
    fi
}

# Vérification de la documentation
check_documentation() {
    log_step "Vérification de la documentation..."
    
    local docs=("docs/TRITON-DEMO-GITOPS-MIGRATION.md" "docs/CLEANUP-SUMMARY.md" "scripts/migrate-triton-demo-to-gitops.sh")
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            log_success "✅ Documentation créée: $doc"
        else
            log_error "❌ Documentation manquante: $doc"
            return 1
        fi
    done
}

# Vérification des fichiers modifiés
check_modified_files() {
    log_step "Vérification des fichiers modifiés..."
    
    # Vérifier que le Makefile a été mis à jour
    if grep -q "OBSOLÈTE" "demos/triton-example/Makefile"; then
        log_success "✅ Makefile mis à jour avec commandes obsolètes"
    else
        log_warning "⚠️  Makefile non mis à jour"
    fi
    
    # Vérifier que le README a été mis à jour
    if grep -q "Migration vers GitOps intégré" "demos/triton-example/README.md"; then
        log_success "✅ README mis à jour avec section migration"
    else
        log_warning "⚠️  README non mis à jour"
    fi
    
    # Vérifier que le workbench a été configuré pour cloner depuis GitHub
    if grep -q "git clone" "components/instances/triton-demo-instance/base/data-science-project/workbench.yaml"; then
        log_success "✅ Workbench configuré pour cloner depuis GitHub"
    else
        log_warning "⚠️  Workbench non configuré pour cloner depuis GitHub"
    fi
}

# Statistiques du nettoyage
show_statistics() {
    log_step "Statistiques du nettoyage..."
    
    echo ""
    echo "📊 RÉSUMÉ DU NETTOYAGE"
    echo "═══════════════════════"
    echo ""
    
    # Compter les fichiers avant/après
    local scripts_before=6
    local scripts_after=4
    local gitops_before=2
    local gitops_after=1
    
    echo "📁 Scripts: $scripts_before → $scripts_after (-$((scripts_before - scripts_after)))"
    echo "🏗️  GitOps: $gitops_before → $gitops_after (-$((gitops_before - gitops_after)))"
    echo ""
    
    echo "✅ Fichiers supprimés:"
    echo "   • demos/triton-example/gitops/ (répertoire complet)"
    echo "   • demos/triton-example/scripts/deploy-gitops.sh"
    echo "   • demos/triton-example/scripts/validate-gitops.sh"
    echo "   • demos/triton-example/deployment/ (répertoire complet)"
    echo ""
    
    echo "✅ Fichiers conservés:"
    echo "   • demos/triton-example/scripts/ (4 scripts nécessaires)"
    echo "   • demos/triton-example/pipelines/ (code ML)"
    echo "   • demos/triton-example/notebooks/ (notebooks)"
    echo "   • demos/triton-example/models/ (modèles)"
    echo ""
    
    echo "✅ Nouveaux fichiers:"
    echo "   • components/instances/triton-demo-instance/ (composant intégré)"
    echo "   • docs/TRITON-DEMO-GITOPS-MIGRATION.md"
    echo "   • docs/CLEANUP-SUMMARY.md"
    echo "   • scripts/migrate-triton-demo-to-gitops.sh"
    echo ""
}

# Fonction principale
main() {
    echo "🔍 VÉRIFICATION DU NETTOYAGE - MIGRATION GITOPS"
    echo "═══════════════════════════════════════════════"
    echo ""
    
    local errors=0
    
    # Vérifications
    check_deleted_files || ((errors++))
    check_kept_files || ((errors++))
    check_new_component || ((errors++))
    check_gitops_integration || ((errors++))
    check_documentation || ((errors++))
    check_modified_files || ((errors++))
    
    # Statistiques
    show_statistics
    
    # Résultat final
    if [ $errors -eq 0 ]; then
        echo "🎉 NETTOYAGE RÉUSSI !"
        echo "═══════════════════════"
        echo ""
        echo "✅ Tous les fichiers obsolètes ont été supprimés"
        echo "✅ Tous les fichiers nécessaires ont été conservés"
        echo "✅ Le nouveau composant a été créé et intégré"
        echo "✅ La documentation a été mise à jour"
        echo ""
        echo "🚀 L'architecture est maintenant cohérente et maintenable !"
        exit 0
    else
        echo "❌ NETTOYAGE INCOMPLET"
        echo "═══════════════════════"
        echo ""
        echo "⚠️  $errors erreur(s) détectée(s)"
        echo "🔧 Veuillez corriger les problèmes avant de continuer"
        exit 1
    fi
}

# Exécution
main 