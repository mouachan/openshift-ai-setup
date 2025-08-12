#!/usr/bin/env python3
"""
Pipeline Elyra/Kubeflow: Iris Classification avec Triton Deployment
Pipeline complet d'entraînement et déploiement d'un modèle Iris avec NVIDIA Triton
"""

from kfp import dsl, compiler
from kfp.dsl import component, pipeline, Input, Output, Artifact, Model
import os

# Images de base pour les composants
BASE_IMAGE = "quay.io/modh/runtime-images:runtime-cuda-tensorflow-ubi9-python-3.9-2023b-20240301"

@component(
    base_image=BASE_IMAGE,
    packages_to_install=[
        "pandas==2.0.3",
        "numpy==1.24.3", 
        "scikit-learn==1.3.0"
    ]
)
def data_preprocessing(output_data: Output[Artifact]) -> str:
    """Étape 1: Preprocessing des données Iris"""
    
    import pandas as pd
    import numpy as np
    from sklearn.datasets import load_iris
    from sklearn.model_selection import train_test_split
    from sklearn.preprocessing import StandardScaler
    import pickle
    import os
    
    print("🔄 [Preprocessing] Chargement des données Iris...")
    
    # Charger le dataset Iris
    iris = load_iris()
    X, y = iris.data, iris.target
    feature_names = iris.feature_names
    target_names = iris.target_names
    
    print(f"📊 Dataset: {X.shape[0]} échantillons, {X.shape[1]} features")
    
    # Division train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Normalisation
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Sauvegarder dans le répertoire de sortie
    output_path = output_data.path
    os.makedirs(output_path, exist_ok=True)
    
    np.save(f"{output_path}/X_train.npy", X_train_scaled)
    np.save(f"{output_path}/X_test.npy", X_test_scaled)
    np.save(f"{output_path}/y_train.npy", y_train)
    np.save(f"{output_path}/y_test.npy", y_test)
    
    with open(f"{output_path}/scaler.pkl", "wb") as f:
        pickle.dump(scaler, f)
    
    metadata = {
        "feature_names": feature_names,  # feature_names est déjà une liste
        "target_names": target_names,    # target_names est déjà une liste
        "n_features": X.shape[1],
        "n_classes": len(target_names),
        "train_size": len(X_train),
        "test_size": len(X_test)
    }
    
    with open(f"{output_path}/metadata.pkl", "wb") as f:
        pickle.dump(metadata, f)
    
    print("✅ [Preprocessing] Terminé avec succès!")
    return output_path

@component(
    base_image=BASE_IMAGE,
    packages_to_install=[
        "tensorflow==2.13.0",
        "scikit-learn==1.3.0",
        "numpy==1.24.3"
    ]
)
def model_training(input_data: Input[Artifact], output_model: Output[Model]) -> str:
    """Étape 2: Entraînement du modèle et export Triton"""
    
    import numpy as np
    import pickle
    import os
    import tensorflow as tf
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import accuracy_score, classification_report
    
    print("🔄 [Training] Chargement des données...")
    
    # Charger les données
    data_path = input_data.path
    X_train = np.load(f"{data_path}/X_train.npy")
    X_test = np.load(f"{data_path}/X_test.npy")
    y_train = np.load(f"{data_path}/y_train.npy")
    y_test = np.load(f"{data_path}/y_test.npy")
    
    with open(f"{data_path}/metadata.pkl", "rb") as f:
        metadata = pickle.load(f)
    
    print(f"📊 Train: {X_train.shape}, Test: {X_test.shape}")
    
    # Entraîner le modèle
    print("🔄 [Training] Entraînement Random Forest...")
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Évaluation
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"🎯 Accuracy: {accuracy:.4f}")
    
    # Export pour Triton
    print("🔄 [Training] Export pour Triton...")
    model_path = output_model.path
    triton_model_path = f"{model_path}/iris_classifier/1"
    os.makedirs(triton_model_path, exist_ok=True)
    
    # Wrapper TensorFlow
    class IrisClassifierWrapper(tf.Module):
        def __init__(self, sklearn_model, scaler):
            super().__init__()
            self.sklearn_model = sklearn_model
            self.scaler = scaler
            
        @tf.function(input_signature=[tf.TensorSpec(shape=[None, 4], dtype=tf.float32)])
        def __call__(self, x):
            x_scaled = tf.py_function(
                lambda x: self.scaler.transform(x.numpy()).astype(np.float32),
                [x], tf.float32
            )
            x_scaled.set_shape([None, 4])
            
            predictions = tf.py_function(
                lambda x: self.sklearn_model.predict_proba(x.numpy()).astype(np.float32),
                [x_scaled], tf.float32
            )
            predictions.set_shape([None, 3])
            
            return {"probabilities": predictions}
    
    # Charger le scaler
    with open(f"{data_path}/scaler.pkl", "rb") as f:
        scaler = pickle.load(f)
    
    wrapper = IrisClassifierWrapper(model, scaler)
    tf.saved_model.save(wrapper, triton_model_path)
    
    # Configuration Triton
    config_content = '''name: "iris_classifier"
platform: "tensorflow_savedmodel"
max_batch_size: 8
input [
  {
    name: "x"
    data_type: TYPE_FP32
    dims: [ 4 ]
  }
]
output [
  {
    name: "probabilities"
    data_type: TYPE_FP32
    dims: [ 3 ]
  }
]
version_policy { all: {} }
'''
    
    with open(f"{model_path}/iris_classifier/config.pbtxt", "w") as f:
        f.write(config_content)
    
    # Métriques
    metrics = {
        "accuracy": float(accuracy),
        "model_type": "RandomForestClassifier",
        "features": metadata['feature_names'],
        "classes": metadata['target_names']
    }
    
    with open(f"{model_path}/metrics.pkl", "wb") as f:
        pickle.dump(metrics, f)
    
    print("✅ [Training] Modèle entraîné et exporté!")
    return model_path

@component(
    base_image=BASE_IMAGE,
    packages_to_install=[
        "model-registry==0.2.7a1",
        "boto3==1.28.25"
    ]
)
def model_registry_push(input_model: Input[Model]) -> str:
    """Étape 3: Push vers Model Registry"""
    
    import os
    import pickle
    import tarfile
    import tempfile
    from datetime import datetime
    
    print("🔄 [Registry] Préparation du modèle...")
    
    model_path = input_model.path
    
    # Charger les métriques
    with open(f"{model_path}/metrics.pkl", "rb") as f:
        metrics = pickle.load(f)
    
    print(f"📊 Accuracy: {metrics['accuracy']:.4f}")
    
    # Créer l'archive
    with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as temp_file:
        archive_path = temp_file.name
        
    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(f"{model_path}/iris_classifier", arcname="iris_classifier")
    
    print(f"📦 Archive créée: {archive_path}")
    
    # Simuler l'upload S3 (en attendant la vraie intégration)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    s3_url = f"s3://models/iris_classifier/{timestamp}/model.tar.gz"
    
    print(f"☁️ [Simulation] Upload vers: {s3_url}")
    print("📝 [Simulation] Enregistrement dans Model Registry...")
    
    # Nettoyer
    os.unlink(archive_path)
    
    result = {
        "model_name": "iris-classifier",
        "version": f"v{timestamp}",
        "s3_url": s3_url,
        "accuracy": metrics['accuracy']
    }
    
    print("✅ [Registry] Modèle enregistré avec succès!")
    return str(result)

@pipeline(
    name="iris-classification-triton-pipeline",
    description="Pipeline complète d'entraînement Iris et déploiement Triton"
)
def iris_triton_pipeline():
    """Pipeline principale Iris Classification avec Triton"""
    
    # Étape 1: Preprocessing
    preprocess_task = data_preprocessing()
    preprocess_task.set_display_name("Data Preprocessing")
    
    # Étape 2: Training
    train_task = model_training(input_data=preprocess_task.outputs["output_data"])
    train_task.set_display_name("Model Training & Triton Export")
    train_task.after(preprocess_task)
    
    # Étape 3: Registry
    registry_task = model_registry_push(input_model=train_task.outputs["output_model"])
    registry_task.set_display_name("Model Registry Push")
    registry_task.after(train_task)

if __name__ == "__main__":
    # Compiler le pipeline
    pipeline_file = "iris_classification_triton_pipeline.yaml"
    compiler.Compiler().compile(iris_triton_pipeline, pipeline_file)
    print(f"✅ Pipeline compilé: {pipeline_file}")
