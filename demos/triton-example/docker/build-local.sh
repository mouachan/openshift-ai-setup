#!/bin/bash
# Script de build local simplifié pour tests rapides

set -e

IMAGE_NAME="triton-demo-notebook"
LOCAL_TAG="localhost/${IMAGE_NAME}:latest"

echo "🔨 Build local de l'image Triton Demo..."
echo "📦 Image: ${LOCAL_TAG}"

# Build sans push
podman build --file Containerfile --tag "${LOCAL_TAG}" .

if [ $? -eq 0 ]; then
    echo "✅ Build réussi: ${LOCAL_TAG}"
    
    # Test rapide
    echo "🧪 Test rapide de l'image..."
    podman run --rm "${LOCAL_TAG}" python -c "
import sys
packages = ['jupyter', 'numpy', 'pandas', 'kfp']
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg}')
    except ImportError:
        print(f'❌ {pkg}')
print('🎉 Test terminé!')
"
    
    echo ""
    echo "🚀 Pour tester l'image localement:"
    echo "   podman run -p 8888:8888 ${LOCAL_TAG}"
    echo ""
    echo "📤 Pour pusher vers Quay.io:"
    echo "   podman tag ${LOCAL_TAG} quay.io/mouachan/triton-demo-notebook:latest"
    echo "   podman push quay.io/mouachan/triton-demo-notebook:latest"
    
else
    echo "❌ Échec du build"
    exit 1
fi