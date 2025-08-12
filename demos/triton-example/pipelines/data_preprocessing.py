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

# S'assurer que feature_names et target_names sont des listes Python
feature_names = list(iris.feature_names) if hasattr(iris, 'feature_names') else []
target_names = list(iris.target_names) if hasattr(iris, 'target_names') else []

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

# Sauvegarder les métadonnées
metadata = {
    "feature_names": feature_names,
    "target_names": target_names,
    "n_features": X.shape[1],
    "n_classes": len(np.unique(y)),
    "train_size": len(X_train),
    "test_size": len(X_test)
}

with open('metadata.pkl', 'wb') as f:
    pickle.dump(metadata, f)

print(f"✅ Données préparées: {X_train.shape[0]} train, {X_test.shape[0]} test")
print(f"📊 Features: {X_train.shape[1]}")
print(f"🎯 Classes: {len(np.unique(y))}")
print(f"📁 S3 Path: triton-data/{S3_DATA_PATH}/")
print(f"📋 Métadonnées sauvegardées: {len(feature_names)} features, {len(target_names)} classes")
