#!/bin/bash
# Script pour construire et pousser l'image Triton Demo vers Quay.io

set -e

# Configuration
IMAGE_NAME="triton-demo-notebook"
IMAGE_TAG="${1:-latest}"
REGISTRY="quay.io/mouachan"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "🚀 Construction et push de l'image Triton Demo"
echo "==============================================="
echo "📦 Image: ${FULL_IMAGE}"
echo "📅 Tag: ${IMAGE_TAG}"
echo ""

# Vérification des prérequis
check_prerequisites() {
    echo "🔍 Vérification des prérequis..."
    
    # Vérifier que podman/docker est installé
    if command -v podman &> /dev/null; then
        CONTAINER_ENGINE="podman"
        echo "✅ Podman détecté"
    elif command -v docker &> /dev/null; then
        CONTAINER_ENGINE="docker"
        echo "✅ Docker détecté"
    else
        echo "❌ Erreur: Podman ou Docker requis"
        exit 1
    fi
    
    # Vérifier la connexion à Quay.io
    if ! ${CONTAINER_ENGINE} login quay.io --get-login &> /dev/null; then
        echo "⚠️ Pas connecté à Quay.io. Connexion requise..."
        echo "💡 Exécutez: ${CONTAINER_ENGINE} login quay.io"
        
        # Tenter de se connecter
        read -p "🔐 Username Quay.io: " QUAY_USERNAME
        read -s -p "🔑 Password/Token: " QUAY_PASSWORD
        echo ""
        
        echo "${QUAY_PASSWORD}" | ${CONTAINER_ENGINE} login quay.io -u "${QUAY_USERNAME}" --password-stdin
        
        if [ $? -eq 0 ]; then
            echo "✅ Connexion réussie à Quay.io"
        else
            echo "❌ Échec de la connexion à Quay.io"
            exit 1
        fi
    else
        echo "✅ Déjà connecté à Quay.io"
    fi
}

# Construction de l'image
build_image() {
    echo ""
    echo "🔨 Construction de l'image..."
    echo "📂 Contexte: $(dirname $0)"
    
    # Se placer dans le répertoire du Dockerfile
    cd "$(dirname "$0")"
    
    # Construire l'image avec Containerfile
    ${CONTAINER_ENGINE} build \
        --file Containerfile \
        --tag "${FULL_IMAGE}" \
        --tag "${REGISTRY}/${IMAGE_NAME}:latest" \
        --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --label "org.opencontainers.image.version=${IMAGE_TAG}" \
        --label "org.opencontainers.image.source=https://github.com/mouachan/openshift-ai-setup" \
        --label "org.opencontainers.image.description=Optimized notebook for Triton inference demos" \
        .
    
    if [ $? -eq 0 ]; then
        echo "✅ Image construite avec succès"
    else
        echo "❌ Échec de la construction"
        exit 1
    fi
}

# Test de l'image
test_image() {
    echo ""
    echo "🧪 Test de l'image..."
    
    # Test rapide pour vérifier que l'image démarre
    ${CONTAINER_ENGINE} run --rm "${FULL_IMAGE}" python3 -c "
import sys
print(f'✅ Python {sys.version}')

# Test des imports critiques
packages = ['numpy', 'pandas', 'sklearn', 'tensorflow', 'kfp', 'tritonclient']
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg}')
    except ImportError as e:
        print(f'❌ {pkg}: {e}')
        sys.exit(1)

print('🎉 Tous les tests passent!')
"
    
    if [ $? -eq 0 ]; then
        echo "✅ Image testée avec succès"
    else
        echo "❌ Échec du test de l'image"
        exit 1
    fi
}

# Push vers Quay.io
push_image() {
    echo ""
    echo "📤 Push vers Quay.io..."
    
    # Push avec le tag spécifique
    ${CONTAINER_ENGINE} push "${FULL_IMAGE}"
    
    # Push du tag latest si ce n'est pas déjà latest
    if [ "${IMAGE_TAG}" != "latest" ]; then
        ${CONTAINER_ENGINE} push "${REGISTRY}/${IMAGE_NAME}:latest"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ Image poussée avec succès"
    else
        echo "❌ Échec du push"
        exit 1
    fi
}

# Affichage des informations finales
show_summary() {
    echo ""
    echo "🎉 Construction et push terminés!"
    echo "================================"
    echo "📦 Image disponible: ${FULL_IMAGE}"
    echo "🌐 Registry: ${REGISTRY}"
    echo "📋 Tags disponibles:"
    echo "   - ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    echo "   - ${REGISTRY}/${IMAGE_NAME}:latest"
    echo ""
    echo "📝 Pour utiliser cette image dans OpenShift AI:"
    echo "   1. Ajouter l'image aux Notebook Images"
    echo "   2. Modifier le workbench.yaml:"
    echo "      image: '${FULL_IMAGE}'"
    echo ""
    echo "⚡ Temps de démarrage attendu: ~30 secondes"
    echo "   (vs 5-10 minutes avec l'installation à chaque fois)"
}

# Exécution principale
main() {
    check_prerequisites
    build_image
    test_image
    push_image
    show_summary
}

# Gestion des arguments
case "${1}" in
    --help|-h)
        echo "Usage: $0 [TAG]"
        echo ""
        echo "Construit et pousse l'image Triton Demo vers Quay.io"
        echo ""
        echo "Arguments:"
        echo "  TAG    Tag de l'image (défaut: latest)"
        echo ""
        echo "Exemples:"
        echo "  $0           # Construit avec le tag 'latest'"
        echo "  $0 v1.0.0    # Construit avec le tag 'v1.0.0'"
        exit 0
        ;;
    *)
        main
        ;;
esac