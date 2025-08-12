#!/bin/bash

# Script de build optimisé pour l'image alignée sur le standard
# Build rapide et push automatique

set -e

echo "🚀 Build optimisé de l'image Triton Demo Notebook v4.0"

# Configuration
IMAGE_NAME="triton-demo-notebook"
TAG="latest"
REGISTRY="quay.io/mouachan"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

# Build optimisé
echo "📦 Build de l'image..."
podman build \
    --tag="${FULL_IMAGE}" \
    --file=Containerfile \
    --format=docker \
    --progress=plain \
    .

# Test rapide de l'image
echo "🧪 Test rapide de l'image..."
podman run --rm "${FULL_IMAGE}" python -c "
import jupyter, jupyterlab, elyra, numpy, pandas, sklearn, matplotlib, kfp
print('✅ Tous les packages principaux sont installés')
print(f'JupyterLab: {jupyterlab.__version__}')
print(f'Elyra: {elyra.__version__}')
print(f'KFP: {kfp.__version__}')
print(f'NumPy: {numpy.__version__}')
print(f'Pandas: {pandas.__version__}')
print(f'Scikit-learn: {sklearn.__version__}')
"

# Push automatique
echo "📤 Push de l'image..."
podman push "${FULL_IMAGE}"

echo "✅ Build et push terminés avec succès!"
echo "🔄 Image disponible: ${FULL_IMAGE}"
echo "💡 Pour déployer: kubectl rollout restart deployment/triton-workbench -n triton-demo"
