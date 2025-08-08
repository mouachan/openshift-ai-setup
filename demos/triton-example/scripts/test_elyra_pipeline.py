#!/usr/bin/env python3
"""
Script de test pour vérifier les composants de la pipeline Elyra
"""

import os
import sys
import pickle
import numpy as np
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

def test_data_preprocessing():
    """Test du composant de préparation des données"""
    print("🔧 Test: Préparation des données")
    
    # Charger les données
    iris = load_iris()
    X = iris.data
    y = iris.target
    
    # Division train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Sauvegarder les données
    os.makedirs('data', exist_ok=True)
    with open('data/X_train.pkl', 'wb') as f:
        pickle.dump(X_train, f)
    with open('data/X_test.pkl', 'wb') as f:
        pickle.dump(X_test, f)
    with open('data/y_train.pkl', 'wb') as f:
        pickle.dump(y_train, f)
    with open('data/y_test.pkl', 'wb') as f:
        pickle.dump(y_test, f)
    
    print(f"✅ Données sauvegardées: {X_train.shape[0]} train, {X_test.shape[0]} test")
    return True

def test_model_training():
    """Test du composant d'entraînement"""
    print("🤖 Test: Entraînement du modèle")
    
    # Charger les données
    with open('data/X_train.pkl', 'rb') as f:
        X_train = pickle.load(f)
    with open('data/y_train.pkl', 'rb') as f:
        y_train = pickle.load(f)
    
    # Entraîner le modèle
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Sauvegarder le modèle
    os.makedirs('models', exist_ok=True)
    with open('models/iris_model.pkl', 'wb') as f:
        pickle.dump(model, f)
    
    print("✅ Modèle entraîné et sauvegardé")
    return True

def test_model_evaluation():
    """Test du composant d'évaluation"""
    print("📊 Test: Évaluation du modèle")
    
    # Charger le modèle et les données de test
    with open('models/iris_model.pkl', 'rb') as f:
        model = pickle.load(f)
    with open('data/X_test.pkl', 'rb') as f:
        X_test = pickle.load(f)
    with open('data/y_test.pkl', 'rb') as f:
        y_test = pickle.load(f)
    
    # Prédictions
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    # Sauvegarder les métriques
    metrics = {
        'accuracy': accuracy,
        'classification_report': classification_report(y_test, y_pred, output_dict=True)
    }
    
    with open('models/metrics.pkl', 'wb') as f:
        pickle.dump(metrics, f)
    
    print(f"✅ Métriques sauvegardées - Accuracy: {accuracy:.4f}")
    return True

def main():
    """Test complet de la pipeline"""
    print("🚀 Test complet de la pipeline Elyra")
    print("=" * 50)
    
    try:
        # Test des composants
        test_data_preprocessing()
        test_model_training()
        test_model_evaluation()
        
        print("\n🎉 Tous les tests passent avec succès!")
        print("📁 Fichiers créés:")
        print("   - data/X_train.pkl, X_test.pkl, y_train.pkl, y_test.pkl")
        print("   - models/iris_model.pkl, metrics.pkl")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors du test: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 