#!/bin/bash
# Script pour créer une image de notebook optimisée avec tous les packages pré-installés

echo "🚀 Création d'une image notebook optimisée pour Triton Demo"
echo "================================================"

# Configuration
IMAGE_NAME="triton-demo-notebook"
BASE_IMAGE="image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/s2i-generic-data-science-notebook:2025.1"
TARGET_IMAGE="image-registry.openshift-image-registry.svc:5000/triton-demo/${IMAGE_NAME}:latest"

# Créer le Dockerfile
cat > /tmp/Dockerfile.triton-notebook << 'EOF'
FROM image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/s2i-generic-data-science-notebook:2025.1

USER root

# Installation des packages système si nécessaire
RUN dnf update -y && dnf clean all

USER 1001

# Configuration pip pour optimiser les builds
ENV PIP_NO_CACHE_DIR=0
ENV PIP_CACHE_DIR=/tmp/pip-cache

# Installation des dépendances en couches pour optimiser le cache Docker
RUN pip install --upgrade pip setuptools wheel

# Couche 1: Dépendances de base (changent rarement)
RUN pip install \
    "urllib3>=1.26.2,<2.0" \
    "pydantic>=1.10.0,<2.0" \
    "requests>=2.31.0" \
    "typing-extensions>=4.0.0"

# Couche 2: Packages scientifiques (changent rarement)
RUN pip install \
    "numpy>=1.24.0" \
    "pandas>=2.0.0" \
    "scikit-learn>=1.3.0" \
    "matplotlib>=3.7.0" \
    "seaborn>=0.12.0"

# Couche 3: Packages ML/AI (version plus stable)
RUN pip install \
    "tensorflow>=2.13.0"

# Couche 4: Packages cloud et infrastructure
RUN pip install \
    "boto3>=1.28.0" \
    "minio>=7.1.0" \
    "pyyaml>=6.0" \
    "click>=8.1.0"

# Couche 5: Packages Kubeflow et Triton (changent plus souvent)
RUN pip install \
    "kfp>=2.0.0" \
    "kfp-kubernetes>=1.0.0" \
    "tritonclient[http]>=2.30.0" \
    "model-registry>=0.1.0"

# Configuration Elyra par défaut
RUN mkdir -p /opt/app-root/src/.jupyter && \
    echo "c.ElyraApp.enable_pipeline_editing = True" > /opt/app-root/src/.jupyter/jupyter_elyra_config.py && \
    echo "c.ElyraApp.runtime_env = 'kubeflow_pipelines'" >> /opt/app-root/src/.jupyter/jupyter_elyra_config.py

# Pré-créer les répertoires Elyra
RUN mkdir -p /opt/app-root/src/.local/share/jupyter/metadata/runtimes && \
    mkdir -p /opt/app-root/src/.local/share/jupyter/metadata/component-catalogs && \
    mkdir -p /opt/app-root/src/.local/share/jupyter/metadata/code-snippets

# Nettoyer le cache pip pour réduire la taille de l'image
RUN pip cache purge && rm -rf /tmp/pip-cache

WORKDIR /opt/app-root/src
EOF

echo "📝 Dockerfile créé: /tmp/Dockerfile.triton-notebook"

# Créer le script de build
cat > /tmp/build-triton-image.sh << EOF
#!/bin/bash
set -e

echo "🔨 Construction de l'image optimisée..."

# Se connecter au registry interne d'OpenShift
oc registry login

# Créer le namespace pour l'image si nécessaire
oc create namespace triton-demo 2>/dev/null || true

# Builder l'image
podman build -t ${TARGET_IMAGE} -f /tmp/Dockerfile.triton-notebook /tmp/

# Pousser l'image
podman push ${TARGET_IMAGE}

echo "✅ Image créée et poussée: ${TARGET_IMAGE}"
echo "📋 Pour utiliser cette image, modifiez le workbench.yaml:"
echo "   image: '${TARGET_IMAGE}'"
EOF

chmod +x /tmp/build-triton-image.sh

echo "✅ Scripts créés:"
echo "   📄 Dockerfile: /tmp/Dockerfile.triton-notebook"
echo "   🔨 Script de build: /tmp/build-triton-image.sh"
echo ""
echo "🚀 Pour construire l'image:"
echo "   bash /tmp/build-triton-image.sh"
echo ""
echo "⚡ Temps de démarrage attendu avec l'image optimisée: ~30 secondes"
echo "   (vs ~5-10 minutes avec l'installation à chaque démarrage)"