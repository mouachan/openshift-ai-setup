#!/bin/bash
set -euo pipefail

# Configuration
VENV_NAME="triton-demo"
PYTHON_VERSION="3.9"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Vérification de Python
check_python() {
    log_info "Vérification de Python..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 non trouvé. Veuillez l'installer."
        exit 1
    fi
    
    local python_version
    python_version=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    log_info "Python version: $python_version"
    
    if ! command -v pip3 &> /dev/null; then
        log_error "pip3 non trouvé. Veuillez l'installer."
        exit 1
    fi
    
    log_success "Python et pip disponibles"
}

# Installation dans un environnement virtuel
setup_venv() {
    log_info "Configuration de l'environnement virtuel..."
    
    # Créer l'environnement virtuel s'il n'existe pas
    if [ ! -d "venv" ]; then
        log_info "Création de l'environnement virtuel..."
        python3 -m venv venv
    fi
    
    # Activer l'environnement virtuel
    source venv/bin/activate
    
    # Mettre à jour pip
    pip install --upgrade pip
    
    log_success "Environnement virtuel configuré"
}

# Installation des dépendances
install_dependencies() {
    log_info "Installation des dépendances Python..."
    
    # S'assurer que l'environnement virtuel est activé
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        source venv/bin/activate
    fi
    
    # Installer les dépendances depuis requirements.txt
    pip install -r requirements.txt
    
    log_success "Dépendances installées"
}

# Installation globale (alternative)
install_global() {
    log_warning "Installation globale des dépendances..."
    
    pip3 install --user -r requirements.txt
    
    log_success "Dépendances installées globalement"
}

# Vérification de l'installation
verify_installation() {
    log_info "Vérification de l'installation..."
    
    local failed=0
    
    # Vérifier les packages principaux
    packages=("kfp" "sklearn" "tensorflow" "pandas" "numpy" "requests")
    
    for package in "${packages[@]}"; do
        if python3 -c "import $package" &> /dev/null; then
            log_success "✓ $package"
        else
            log_error "✗ $package"
            failed=1
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_success "Toutes les dépendances sont installées correctement"
    else
        log_error "Certaines dépendances ont échoué"
        return 1
    fi
}

# Affichage des instructions d'utilisation
show_usage_instructions() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "🎉 INSTALLATION TERMINÉE"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "📋 Prochaines étapes:"
    echo ""
    if [ -d "venv" ]; then
        echo "1. Activer l'environnement virtuel:"
        echo "   source venv/bin/activate"
        echo ""
    fi
    echo "2. Lancer Jupyter Notebook:"
    echo "   jupyter notebook notebooks/"
    echo ""
    echo "3. Ou exécuter le pipeline directement:"
    echo "   python pipelines/iris_classification_pipeline.py"
    echo ""
    echo "4. Déployer le modèle:"
    echo "   ./scripts/deploy.sh deploy"
    echo ""
    echo "5. Tester l'inférence:"
    echo "   python scripts/test_inference.py --url <service-url>"
    echo ""
}

# Fonction principale
main() {
    echo "🔧 INSTALLATION DES DÉPENDANCES TRITON DEMO"
    echo "═══════════════════════════════════════════════"
    
    check_python
    
    case "${1:-venv}" in
        "venv")
            setup_venv
            install_dependencies
            ;;
        "global")
            install_global
            ;;
        *)
            log_error "Option non reconnue: $1"
            echo "Usage: $0 [venv|global]"
            exit 1
            ;;
    esac
    
    verify_installation
    show_usage_instructions
}

# Gérer les arguments
main "$@"
