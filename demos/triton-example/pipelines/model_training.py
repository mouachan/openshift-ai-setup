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
