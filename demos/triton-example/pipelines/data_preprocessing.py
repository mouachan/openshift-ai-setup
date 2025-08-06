#!/usr/bin/env python3
"""
Étape 1: Data Preprocessing
Transformation et préparation des données Iris pour l'entraînement
"""

import pandas as pd
import numpy as np
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import os
import pickle
import argparse

def preprocess_data(output_path: str = "/tmp/data"):
    """Préparation des données Iris"""
    
    print("🔄 Chargement des données Iris...")
    
    # Charger le dataset Iris
    iris = load_iris()
    X, y = iris.data, iris.target
    feature_names = iris.feature_names
    target_names = iris.target_names
    
    print(f"📊 Dataset: {X.shape[0]} échantillons, {X.shape[1]} features")
    print(f"📊 Classes: {list(target_names)}")
    
    # Création du DataFrame
    df = pd.DataFrame(X, columns=feature_names)
    df['target'] = y
    df['species'] = [target_names[i] for i in y]
    
    print("🔄 Division train/test (80/20)...")
    
    # Division train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    print("🔄 Normalisation des features...")
    
    # Normalisation
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Créer le répertoire de sortie
    os.makedirs(output_path, exist_ok=True)
    
    print(f"💾 Sauvegarde des données dans {output_path}...")
    
    # Sauvegarder les données preprocessées
    np.save(f"{output_path}/X_train.npy", X_train_scaled)
    np.save(f"{output_path}/X_test.npy", X_test_scaled)
    np.save(f"{output_path}/y_train.npy", y_train)
    np.save(f"{output_path}/y_test.npy", y_test)
    
    # Sauvegarder le scaler pour l'inférence
    with open(f"{output_path}/scaler.pkl", "wb") as f:
        pickle.dump(scaler, f)
    
    # Sauvegarder les métadonnées
    metadata = {
        "feature_names": feature_names.tolist(),
        "target_names": target_names.tolist(),
        "n_features": X.shape[1],
        "n_classes": len(target_names),
        "train_size": len(X_train),
        "test_size": len(X_test)
    }
    
    with open(f"{output_path}/metadata.pkl", "wb") as f:
        pickle.dump(metadata, f)
    
    print("✅ Preprocessing terminé avec succès!")
    print(f"📈 Train set: {X_train_scaled.shape}")
    print(f"📈 Test set: {X_test_scaled.shape}")
    
    return output_path

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-path", default="/tmp/data", help="Chemin de sortie des données")
    args = parser.parse_args()
    
    preprocess_data(args.output_path)
