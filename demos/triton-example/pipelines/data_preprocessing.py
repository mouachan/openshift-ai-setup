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
