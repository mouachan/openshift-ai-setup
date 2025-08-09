#!/usr/bin/env python3
"""
Script simple pour tester la classification Iris
Sans ONNX, juste pickle pour commencer
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import pickle
from datetime import datetime

def main():
    print("🚀 Test simple de classification Iris")
    print("=" * 50)
    
    # Configuration de l'environnement
    print("🔧 Configuration de l'environnement...")
    print(f"📁 Répertoire de travail: {os.getcwd()}")
    print(f"👤 Utilisateur: {os.getenv('USER', 'unknown')}")
    print(f"🏷️ Namespace: {os.getenv('NAMESPACE', 'unknown')}")
    
    # Créer les dossiers nécessaires
    os.makedirs('models', exist_ok=True)
    os.makedirs('data', exist_ok=True)
    print("✅ Dossiers créés")
    
    # Charger le dataset Iris
    print("\n📊 Chargement du dataset Iris...")
    iris = load_iris()
    X = iris.data
    y = iris.target
    
    print(f"📈 Forme des données: {X.shape}")
    print(f"🎯 Nombre de classes: {len(np.unique(y))}")
    print(f"🏷️ Classes: {iris.target_names}")
    print(f"📋 Features: {iris.feature_names}")
    
    # Diviser en train/test
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    
    print(f"\n📊 Division train/test:")
    print(f"   Train: {X_train.shape[0]} échantillons")
    print(f"   Test: {X_test.shape[0]} échantillons")
    
    # Entraîner le modèle
    print("\n🤖 Entraînement du modèle Random Forest...")
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Prédictions et évaluation
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"\n📊 Performance du modèle:")
    print(f"   Accuracy: {accuracy:.4f}")
    print(f"   Classes: {iris.target_names}")
    
    # Rapport de classification
    print("\n📋 Rapport de classification:")
    print(classification_report(y_test, y_pred, target_names=iris.target_names))
    
    # Sauvegarder le modèle (format pickle simple)
    print("\n💾 Sauvegarde du modèle...")
    
    # Sauvegarder le modèle scikit-learn
    model_path = 'models/iris_classifier.pkl'
    with open(model_path, 'wb') as f:
        pickle.dump(model, f)
    
    # Sauvegarder les métadonnées
    model_metadata = {
        'accuracy': float(accuracy),
        'model_type': 'RandomForestClassifier',
        'features': iris.feature_names,
        'classes': iris.target_names.tolist(),
        'n_estimators': model.n_estimators,
        'training_date': datetime.now().isoformat(),
        'dataset_size': {
            'train': len(X_train),
            'test': len(X_test),
            'total': len(X)
        }
    }
    
    metadata_path = 'models/model_metadata.json'
    with open(metadata_path, 'w') as f:
        import json
        json.dump(model_metadata, f, indent=2)
    
    print(f"✅ Modèle sauvegardé: {model_path}")
    print(f"✅ Métadonnées sauvegardées: {metadata_path}")
    
    # Test du modèle sauvegardé
    print("\n🧪 Test du modèle sauvegardé...")
    
    # Recharger le modèle
    with open(model_path, 'rb') as f:
        loaded_model = pickle.load(f)
    
    # Test avec quelques échantillons
    test_samples = X_test[:5]
    predictions = loaded_model.predict(test_samples)
    probabilities = loaded_model.predict_proba(test_samples)
    
    print(f"\n🎯 Prédictions:")
    for i, (pred, prob) in enumerate(zip(predictions, probabilities)):
        class_name = iris.target_names[pred]
        confidence = prob.max() * 100
        print(f"   Échantillon {i+1}: {class_name} (confiance: {confidence:.1f}%)")
    
    # Résumé final
    print("\n🎉 Résumé de l'exécution:")
    print(f"   📊 Dataset: {X.shape[0]} échantillons, {X.shape[1]} features")
    print(f"   🤖 Modèle: Random Forest ({model.n_estimators} arbres)")
    print(f"   📈 Accuracy: {accuracy:.4f}")
    print(f"   💾 Modèle: {model_path}")
    print(f"   📋 Métadonnées: {metadata_path}")
    
    print("\n🎯 Prochaines étapes:")
    print("   1. Tester le modèle avec de nouvelles données")
    print("   2. Améliorer les performances")
    print("   3. Déployer le modèle en production")
    
    print("\n🔧 Configuration du workbench:")
    print(f"   📁 Working Directory: {os.getcwd()}")
    print(f"   🏷️ Namespace: {os.getenv('NAMESPACE', 'unknown')}")
    print(f"   👤 User: {os.getenv('USER', 'unknown')}")
    print(f"   🔗 Base URL: /notebook/triton-demo/triton-workbench")
    
    print("\n✅ Test terminé avec succès!")
    return True

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n❌ Erreur: {e}")
        import traceback
        traceback.print_exc()
        exit(1) 