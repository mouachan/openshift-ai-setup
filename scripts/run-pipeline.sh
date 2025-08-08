#!/bin/bash

# Script pour lancer la pipeline Triton Demo
# Usage: ./run-pipeline.sh [mode]

set -e

MODE="${1:-workbench}"
NAMESPACE="triton-demo"
WORKBENCH_NAME="triton-workbench"

echo "🚀 Lancement de la pipeline Triton Demo"
echo "Mode: $MODE"
echo "Namespace: $NAMESPACE"

case $MODE in
    "workbench")
        echo "📊 Mode Workbench - Lancement du notebook..."
        
        # Vérifier que le workbench est prêt
        echo "⏳ Vérification du workbench..."
        oc wait --for=condition=Ready statefulset/$WORKBENCH_NAME -n $NAMESPACE --timeout=300s
        
        # Récupérer l'URL du workbench
        WORKBENCH_URL=$(oc get route -n $NAMESPACE | grep $WORKBENCH_NAME | awk '{print $2}')
        echo "🔗 URL du workbench: https://$WORKBENCH_URL"
        
        echo "✅ Workbench prêt !"
        echo "📝 Instructions:"
        echo "1. Ouvrez https://$WORKBENCH_URL"
        echo "2. Naviguez vers: demos/triton-example/notebooks/"
        echo "3. Ouvrez: iris_classification_notebook.ipynb"
        echo "4. Exécutez toutes les cellules"
        ;;
        
    "cli")
        echo "💻 Mode CLI - Exécution directe..."
        
        # Se connecter au workbench et exécuter les scripts
        echo "🔌 Connexion au workbench..."
        oc exec -it statefulset/$WORKBENCH_NAME -n $NAMESPACE -- bash -c "
            echo '📁 Navigation vers le projet...'
            cd /opt/app-root/src/triton-example
            
            echo '🔧 Test de l\'environnement...'
            python test_notebook.py
            
            echo '🤖 Lancement de l\'entraînement...'
            python pipelines/model_training.py
            
            echo '📊 Enregistrement dans le Model Registry...'
            python pipelines/model_registry.py
            
            echo '✅ Pipeline terminée avec succès !'
        "
        ;;
        
    "kubeflow")
        echo "🔄 Mode Kubeflow Pipelines..."
        
        # Vérifier que Kubeflow est disponible
        PIPELINE_UI=$(oc get route -n $NAMESPACE | grep pipeline-ui | awk '{print $2}')
        if [ -n "$PIPELINE_UI" ]; then
            echo "🔗 Pipeline UI: https://$PIPELINE_UI"
            echo "📝 Instructions:"
            echo "1. Ouvrez https://$PIPELINE_UI"
            echo "2. Créez une nouvelle pipeline"
            echo "3. Importez les scripts depuis le workbench"
        else
            echo "❌ Kubeflow Pipelines non disponible"
        fi
        ;;
        
    "status")
        echo "📊 Statut de l'environnement..."
        
        echo "🔍 Workbench:"
        oc get pods -n $NAMESPACE | grep $WORKBENCH_NAME
        
        echo "🔍 Model Registry:"
        oc get pods -n rhoai-model-registries | grep modelregistry
        
        echo "🔍 MySQL:"
        oc get pods -n db-ai | grep mysql
        
        echo "🔍 MinIO:"
        oc get pods -n db-ai | grep minio
        ;;
        
    *)
        echo "❌ Mode non reconnu: $MODE"
        echo "📋 Modes disponibles:"
        echo "  workbench  - Lance le workbench (défaut)"
        echo "  cli        - Exécution directe via CLI"
        echo "  kubeflow   - Via Kubeflow Pipelines"
        echo "  status     - Vérifier le statut"
        exit 1
        ;;
esac

echo "🎉 Pipeline lancée avec succès !" 