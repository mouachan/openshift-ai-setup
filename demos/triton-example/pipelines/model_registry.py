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
