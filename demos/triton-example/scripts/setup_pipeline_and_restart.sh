#!/bin/bash

echo "🚀 Configuration de la pipeline et redémarrage du workbench"
echo "=========================================================="

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "pipelines/iris.pipeline" ]; then
    echo "❌ Erreur: Veuillez exécuter ce script depuis le répertoire triton-example"
    exit 1
fi

echo "📋 Pipeline complétée avec:"
echo "   - Data connections configurées"
echo "   - Outputs vers triton-data/iris-data/ et iris-models/"
echo "   - Variables d'environnement définies"

# Copier les scripts de pipeline depuis le ConfigMap
echo "📁 Copie des scripts de pipeline..."
mkdir -p pipelines/

# Créer les scripts de pipeline
cat > pipelines/data_preprocessing.py << 'EOF'
import os
import pickle
import numpy as np
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split

print("🔧 Préparation des données Iris")
print("=" * 40)

# Configuration des chemins S3
PROJECT_NAME = os.getenv('PROJECT_NAME', 'iris')
S3_DATA_PATH = f"{PROJECT_NAME}-data"

# Charger et préparer les données
iris = load_iris()
X, y = iris.data, iris.target
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=float(os.getenv('TEST_SIZE', 0.2)),
    random_state=int(os.getenv('RANDOM_STATE', 42))
)

# Sauvegarder les données (sera uploadé vers S3/triton-data/iris-data/)
with open('X_train.pkl', 'wb') as f:
    pickle.dump(X_train, f)
with open('X_test.pkl', 'wb') as f:
    pickle.dump(X_test, f)
with open('y_train.pkl', 'wb') as f:
    pickle.dump(y_train, f)
with open('y_test.pkl', 'wb') as f:
    pickle.dump(y_test, f)

print(f"✅ Données préparées: {X_train.shape[0]} train, {X_test.shape[0]} test")
print(f"📊 Features: {X_train.shape[1]}")
print(f"🎯 Classes: {len(np.unique(y))}")
print(f"📁 S3 Path: triton-data/{S3_DATA_PATH}/")
EOF

cat > pipelines/model_training.py << 'EOF'
import os
import pickle
from sklearn.ensemble import RandomForestClassifier

print("🤖 Entraînement du modèle Random Forest")
print("=" * 40)

# Configuration des chemins S3
PROJECT_NAME = os.getenv('PROJECT_NAME', 'iris')
S3_MODELS_PATH = f"{PROJECT_NAME}-models"

# Charger les données
with open('X_train.pkl', 'rb') as f:
    X_train = pickle.load(f)
with open('y_train.pkl', 'rb') as f:
    y_train = pickle.load(f)

# Entraîner le modèle
model = RandomForestClassifier(
    n_estimators=int(os.getenv('N_ESTIMATORS', 100)),
    random_state=int(os.getenv('RANDOM_STATE', 42))
)
model.fit(X_train, y_train)

# Sauvegarder le modèle (sera uploadé vers Model Registry via "Triton Demo - S3 Connection")
with open('iris_model.pkl', 'wb') as f:
    pickle.dump(model, f)

print("✅ Modèle entraîné et sauvegardé")
print(f"🌳 Nombre d'arbres: {model.n_estimators}")
print(f"📁 S3 Path: [Model Registry]/{S3_MODELS_PATH}/")
EOF

cat > pipelines/model_registry.py << 'EOF'
import os
import pickle
import json
from sklearn.metrics import accuracy_score, classification_report

print("📊 Évaluation du modèle")
print("=" * 30)

# Configuration des chemins S3
PROJECT_NAME = os.getenv('PROJECT_NAME', 'iris')
S3_MODELS_PATH = f"{PROJECT_NAME}-models"

# Charger le modèle et les données
with open('iris_model.pkl', 'rb') as f:
    model = pickle.load(f)
with open('X_test.pkl', 'rb') as f:
    X_test = pickle.load(f)
with open('y_test.pkl', 'rb') as f:
    y_test = pickle.load(f)

# Évaluation
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

# Sauvegarder les métriques (sera uploadé vers Model Registry via "Triton Demo - S3 Connection")
metrics = {
    'accuracy': accuracy,
    'classification_report': classification_report(y_test, y_pred, output_dict=True)
}

with open('metrics.pkl', 'wb') as f:
    pickle.dump(metrics, f)

with open('accuracy.txt', 'w') as f:
    f.write(f"Accuracy: {accuracy:.4f}")

print(f"✅ Métriques sauvegardées - Accuracy: {accuracy:.4f}")
print("📋 Rapport de classification:")
print(classification_report(y_test, y_pred))
print(f"📁 S3 Path: [Model Registry]/{S3_MODELS_PATH}/")
EOF

echo "✅ Scripts de pipeline créés"

# Redémarrer le workbench
echo "🔄 Redémarrage du workbench..."
oc delete pod -n triton-demo -l app.kubernetes.io/name=triton-workbench --force --grace-period=0

echo "⏳ Attente du redémarrage du workbench..."
sleep 10

# Vérifier le statut
echo "🔍 Vérification du statut du workbench..."
oc get pods -n triton-demo -l app.kubernetes.io/name=triton-workbench

echo ""
echo "🎉 Configuration terminée !"
echo ""
echo "📋 Prochaines étapes dans Elyra:"
echo "1. Ouvrez le workbench JupyterLab"
echo "2. Allez dans Elyra → Pipelines"
echo "3. Ouvrez la pipeline 'iris.pipeline'"
echo "4. Configurez les data connections:"
echo "   - Nœud data_preprocessing: triton-data-connection"
echo "   - Nœud model_training: triton-data-connection"
echo "   - Nœud model_registry: Triton Demo - S3 Connection"
echo "5. Lancez la pipeline !"
echo ""
echo "📁 Fichiers créés:"
echo "   - pipelines/iris.pipeline (pipeline complétée)"
echo "   - pipelines/data_preprocessing.py"
echo "   - pipelines/model_training.py"
echo "   - pipelines/model_registry.py" 