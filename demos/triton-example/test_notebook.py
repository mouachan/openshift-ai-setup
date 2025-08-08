#!/usr/bin/env python3
"""
Script de test pour le notebook Iris Classification
Permet de tester les fonctionnalités du notebook sans Jupyter
"""

import os
import sys
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

def test_notebook_functionality():
    """Test des fonctionnalités du notebook"""
    print("🔧 Test des fonctionnalités du notebook...")
    
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
    
    # Sauvegarder le modèle
    import pickle
    from datetime import datetime
    
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
        json.dump(model_metadata, f, indent=2)
    
    print(f"\n✅ Modèle sauvegardé: {model_path}")
    print(f"✅ Métadonnées sauvegardées: {metadata_path}")
    
    # Résumé
    print("\n🎉 Résumé de l'exécution:")
    print(f"   📊 Dataset: {X.shape[0]} échantillons, {X.shape[1]} features")
    print(f"   🤖 Modèle: Random Forest ({model.n_estimators} arbres)")
    print(f"   📈 Accuracy: {accuracy:.4f}")
    print(f"   💾 Modèle: {model_path}")
    print(f"   📋 Métadonnées: {metadata_path}")
    
    print("\n🎯 Prochaines étapes:")
    print("   1. Convertir le modèle au format ONNX")
    print("   2. Déployer le modèle sur Triton")
    print("   3. Tester l'inférence en temps réel")
    print("   4. Enregistrer dans le Model Registry")
    
    return True

def test_environment_variables():
    """Test des variables d'environnement"""
    print("\n🔧 Test des variables d'environnement...")
    
    # Variables d'environnement du workbench
    print(f"   JUPYTER_IMAGE: {os.getenv('JUPYTER_IMAGE', 'Non configuré')}")
    
    # Variables Model Registry et S3
    print(f"   MODEL_REGISTRY_URL: {os.getenv('MODEL_REGISTRY_URL', 'Non configuré')}")
    print(f"   AWS_ACCESS_KEY_ID: {os.getenv('AWS_ACCESS_KEY_ID', 'Non configuré')}")
    print(f"   AWS_S3_ENDPOINT: {os.getenv('AWS_S3_ENDPOINT', 'Non configuré')}")
    print(f"   AWS_S3_BUCKET: {os.getenv('AWS_S3_BUCKET', 'Non configuré')}")
    
    return True

if __name__ == "__main__":
    print("🚀 Test du notebook Iris Classification")
    print("=" * 50)
    
    try:
        # Test des variables d'environnement
        test_environment_variables()
        
        # Test des fonctionnalités
        test_notebook_functionality()
        
        print("\n✅ Tous les tests ont réussi!")
        print("📝 Le notebook est prêt à être utilisé dans le workbench OpenShift AI")
        
    except Exception as e:
        print(f"\n❌ Erreur lors du test: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1) 