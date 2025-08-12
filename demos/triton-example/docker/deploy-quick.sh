#!/bin/bash

# Script de déploiement rapide pour tester la nouvelle image
# Redémarre le workbench et vérifie le statut

set -e

echo "🚀 Déploiement rapide de la nouvelle image"

# Vérifier que l'image existe
IMAGE_NAME="quay.io/mouachan/triton-demo-notebook:latest"
echo "🔍 Vérification de l'image: ${IMAGE_NAME}"

# Redémarrage du workbench
echo "🔄 Redémarrage du workbench..."
oc rollout restart deployment/triton-workbench -n triton-demo

# Attendre que le rollout soit terminé
echo "⏳ Attente du déploiement..."
oc rollout status deployment/triton-workbench -n triton-demo --timeout=300s

# Vérifier le statut
echo "✅ Vérification du statut..."
oc get pods -n triton-demo -l app=triton-workbench

# Test rapide de connexion
echo "🧪 Test de connexion au workbench..."
WORKBENCH_POD=$(oc get pod -n triton-demo -l app=triton-workbench -o jsonpath='{.items[0].metadata.name}')
echo "📱 Pod: ${WORKBENCH_POD}"

# Vérifier les packages installés
echo "📦 Vérification des packages..."
oc exec -n triton-demo "${WORKBENCH_POD}" -c triton-workbench -- python -c "
import jupyter, jupyterlab, elyra, numpy, pandas, sklearn, matplotlib, kfp
print('✅ Packages principaux:')
print(f'  JupyterLab: {jupyterlab.__version__}')
print(f'  Elyra: {elyra.__version__}')
print(f'  KFP: {kfp.__version__}')
print(f'  NumPy: {numpy.__version__}')
print(f'  Pandas: {pandas.__version__}')
print(f'  Scikit-learn: {sklearn.__version__}')
"

echo "🎉 Déploiement terminé avec succès!"
echo "🌐 Workbench accessible via la route OpenShift"
