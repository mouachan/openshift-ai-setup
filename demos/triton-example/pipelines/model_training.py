#!/usr/bin/env python3
"""
Étape 2: Model Training
Entraînement d'un modèle de classification Iris et export pour Triton
"""

import numpy as np
import pickle
import os
import argparse
import tensorflow as tf
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

def train_model(data_path: str = "/tmp/data", model_path: str = "/tmp/model"):
    """Entraînement du modèle et export au format TensorFlow SavedModel pour Triton"""
    
    print("🔄 Chargement des données preprocessées...")
    
    # Charger les données
    X_train = np.load(f"{data_path}/X_train.npy")
    X_test = np.load(f"{data_path}/X_test.npy")
    y_train = np.load(f"{data_path}/y_train.npy")
    y_test = np.load(f"{data_path}/y_test.npy")
    
    with open(f"{data_path}/metadata.pkl", "rb") as f:
        metadata = pickle.load(f)
    
    print(f"📊 Train set: {X_train.shape}")
    print(f"📊 Test set: {X_test.shape}")
    print(f"📊 Features: {metadata['feature_names']}")
    print(f"📊 Classes: {metadata['target_names']}")
    
    print("🔄 Entraînement du modèle Random Forest...")
    
    # Entraîner un modèle Random Forest
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    print("🔄 Évaluation du modèle...")
    
    # Prédictions et évaluation
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"🎯 Accuracy: {accuracy:.4f}")
    print("📊 Classification Report:")
    print(classification_report(y_test, y_pred, target_names=metadata['target_names']))
    
    print("🔄 Export du modèle au format TensorFlow SavedModel pour Triton...")
    
    # Créer le répertoire de sortie pour Triton
    triton_model_path = f"{model_path}/iris_classifier/1"
    os.makedirs(triton_model_path, exist_ok=True)
    
    # Créer un wrapper TensorFlow pour le modèle scikit-learn
    class IrisClassifierWrapper(tf.Module):
        def __init__(self, sklearn_model, scaler):
            super().__init__()
            self.sklearn_model = sklearn_model
            self.scaler = scaler
            
        @tf.function(input_signature=[tf.TensorSpec(shape=[None, 4], dtype=tf.float32)])
        def __call__(self, x):
            # Normaliser les inputs
            x_scaled = tf.py_function(
                lambda x: self.scaler.transform(x.numpy()).astype(np.float32),
                [x], tf.float32
            )
            x_scaled.set_shape([None, 4])
            
            # Prédiction
            predictions = tf.py_function(
                lambda x: self.sklearn_model.predict_proba(x.numpy()).astype(np.float32),
                [x_scaled], tf.float32
            )
            predictions.set_shape([None, 3])
            
            return {"probabilities": predictions}
    
    # Charger le scaler
    with open(f"{data_path}/scaler.pkl", "rb") as f:
        scaler = pickle.load(f)
    
    # Créer le wrapper
    wrapper = IrisClassifierWrapper(model, scaler)
    
    # Sauvegarder au format TensorFlow SavedModel
    tf.saved_model.save(wrapper, triton_model_path)
    
    print(f"💾 Modèle sauvegardé dans {triton_model_path}")
    
    # Créer le fichier de configuration Triton
    config_content = f'''name: "iris_classifier"
platform: "tensorflow_savedmodel"
max_batch_size: 8
input [
  {{
    name: "x"
    data_type: TYPE_FP32
    dims: [ 4 ]
  }}
]
output [
  {{
    name: "probabilities"
    data_type: TYPE_FP32
    dims: [ 3 ]
  }}
]
version_policy: {{ all: {{}} }}
'''
    
    with open(f"{model_path}/iris_classifier/config.pbtxt", "w") as f:
        f.write(config_content)
    
    print("📝 Configuration Triton créée")
    
    # Sauvegarder les métriques du modèle
    metrics = {
        "accuracy": float(accuracy),
        "model_type": "RandomForestClassifier",
        "n_estimators": 100,
        "features": metadata['feature_names'],
        "classes": metadata['target_names'],
        "triton_model_path": triton_model_path
    }
    
    with open(f"{model_path}/metrics.pkl", "wb") as f:
        pickle.dump(metrics, f)
    
    print("✅ Entraînement et export terminés avec succès!")
    
    return model_path

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-path", default="/tmp/data", help="Chemin des données preprocessées")
    parser.add_argument("--model-path", default="/tmp/model", help="Chemin de sortie du modèle")
    args = parser.parse_args()
    
    train_model(args.data_path, args.model_path)
