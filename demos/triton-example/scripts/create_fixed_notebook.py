#!/usr/bin/env python3
"""
Script pour créer un notebook Jupyter corrigé pour la classification Iris
"""

import json
import os

def create_fixed_notebook():
    """Créer le notebook corrigé"""
    
    notebook = {
        "cells": [
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": [
                    "# 🌸 Classification Iris avec Triton Inference Server\n",
                    "\n",
                    "Ce notebook démontre l'utilisation de NVIDIA Triton Inference Server pour déployer et servir un modèle de classification Iris.\n",
                    "\n",
                    "## Configuration de l'environnement\n",
                    "- **Image**: `s2i-generic-data-science-notebook:2025.1`\n",
                    "- **Namespace**: `triton-demo`\n",
                    "- **User**: `mouachan`\n",
                    "- **Base URL**: `/notebook/triton-demo/test-triton`"
                ]
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": [
                    "# Cellule 1: Imports et configuration\n",
                    "import os\n",
                    "import numpy as np\n",
                    "import pandas as pd\n",
                    "import matplotlib.pyplot as plt\n",
                    "import seaborn as sns\n",
                    "from sklearn.datasets import load_iris\n",
                    "from sklearn.model_selection import train_test_split\n",
                    "from sklearn.ensemble import RandomForestClassifier\n",
                    "from sklearn.metrics import accuracy_score, classification_report\n",
                    "\n",
                    "print(\"🔧 Configuration de l'environnement...\")\n",
                    "print(f\"📁 Répertoire de travail: {os.getcwd()}\")\n",
                    "print(f\"👤 Utilisateur: {os.getenv('USER', 'unknown')}\")\n",
                    "print(f\"🏷️ Namespace: {os.getenv('NAMESPACE', 'unknown')}\")\n",
                    "\n",
                    "# Variables d'environnement du workbench\n",
                    "print(f\"\\n🔗 Configuration du workbench:\")\n",
                    "print(f\"   JUPYTER_IMAGE: {os.getenv('JUPYTER_IMAGE', 'Non configuré')}\")\n",
                    "\n",
                    "# Variables Model Registry et S3\n",
                    "print(f\"\\n📊 Configuration Model Registry:\")\n",
                    "print(f\"   MODEL_REGISTRY_URL: {os.getenv('MODEL_REGISTRY_URL', 'Non configuré')}\")\n",
                    "\n",
                    "print(f\"\\n☁️ Configuration S3/MinIO:\")\n",
                    "print(f\"   AWS_ACCESS_KEY_ID: {os.getenv('AWS_ACCESS_KEY_ID', 'Non configuré')}\")\n",
                    "print(f\"   AWS_S3_ENDPOINT: {os.getenv('AWS_S3_ENDPOINT', 'Non configuré')}\")\n",
                    "print(f\"   AWS_S3_BUCKET: {os.getenv('AWS_S3_BUCKET', 'Non configuré')}\")\n",
                    "\n",
                    "# Créer les dossiers nécessaires\n",
                    "os.makedirs('models', exist_ok=True)\n",
                    "os.makedirs('data', exist_ok=True)\n",
                    "print(\"\\n✅ Dossiers créés\")"
                ]
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": [
                    "# Cellule 2: Chargement et préparation des données\n",
                    "print(\"📊 Chargement du dataset Iris...\")\n",
                    "iris = load_iris()\n",
                    "X = iris.data\n",
                    "y = iris.target\n",
                    "\n",
                    "print(f\"📈 Forme des données: {X.shape}\")\n",
                    "print(f\"🎯 Nombre de classes: {len(np.unique(y))}\")\n",
                    "print(f\"🏷️ Classes: {iris.target_names}\")\n",
                    "print(f\"📋 Features: {iris.feature_names}\")\n",
                    "\n",
                    "# Diviser en train/test\n",
                    "X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)\n",
                    "\n",
                    "print(f\"\\n📊 Division train/test:\")\n",
                    "print(f\"   Train: {X_train.shape[0]} échantillons\")\n",
                    "print(f\"   Test: {X_test.shape[0]} échantillons\")"
                ]
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": [
                    "# Cellule 3: Visualisation des données\n",
                    "plt.figure(figsize=(15, 5))\n",
                    "\n",
                    "# Distribution des classes\n",
                    "plt.subplot(1, 3, 1)\n",
                    "sns.countplot(y=y_train)\n",
                    "plt.title('Distribution des classes (Train)')\n",
                    "plt.xlabel('Classe')\n",
                    "plt.ylabel('Nombre d\\'échantillons')\n",
                    "\n",
                    "# Corrélation entre features\n",
                    "plt.subplot(1, 3, 2)\n",
                    "df_train = pd.DataFrame(X_train, columns=iris.feature_names)\n",
                    "df_train['target'] = y_train\n",
                    "sns.heatmap(df_train.corr(), annot=True, cmap='coolwarm', center=0)\n",
                    "plt.title('Matrice de corrélation')\n",
                    "\n",
                    "# Distribution des features par classe\n",
                    "plt.subplot(1, 3, 3)\n",
                    "for i, feature in enumerate(iris.feature_names):\n",
                    "    plt.hist(X_train[y_train == 0, i], alpha=0.5, label=f'{iris.target_names[0]}', bins=10)\n",
                    "    plt.hist(X_train[y_train == 1, i], alpha=0.5, label=f'{iris.target_names[1]}', bins=10)\n",
                    "    plt.hist(X_train[y_train == 2, i], alpha=0.5, label=f'{iris.target_names[2]}', bins=10)\n",
                    "    plt.xlabel(feature)\n",
                    "    plt.ylabel('Fréquence')\n",
                    "    plt.title(f'Distribution de {feature}')\n",
                    "    plt.legend()\n",
                    "    break  # Afficher seulement la première feature\n",
                    "\n",
                    "plt.tight_layout()\n",
                    "plt.show()"
                ]
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": [
                    "# Cellule 4: Entraînement du modèle\n",
                    "print(\"🤖 Entraînement du modèle Random Forest...\")\n",
                    "model = RandomForestClassifier(n_estimators=100, random_state=42)\n",
                    "model.fit(X_train, y_train)\n",
                    "\n",
                    "# Prédictions et évaluation\n",
                    "y_pred = model.predict(X_test)\n",
                    "accuracy = accuracy_score(y_test, y_pred)\n",
                    "\n",
                    "print(f\"\\n📊 Performance du modèle:\")\n",
                    "print(f\"   Accuracy: {accuracy:.4f}\")\n",
                    "print(f\"   Classes: {iris.target_names}\")\n",
                    "\n",
                    "# Rapport de classification\n",
                    "print(\"\\n📋 Rapport de classification:\")\n",
                    "print(classification_report(y_test, y_pred, target_names=iris.target_names))"
                ]
            },
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": [
                    "# Cellule 5: Sauvegarde du modèle\n",
                    "import pickle\n",
                    "from datetime import datetime\n",
                    "\n",
                    "# Sauvegarder le modèle\n",
                    "model_path = f\"models/iris_classifier_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pkl\"\n",
                    "with open(model_path, 'wb') as f:\n",
                    "    pickle.dump(model, f)\n",
                    "\n",
                    "print(f\"💾 Modèle sauvegardé: {model_path}\")\n",
                    "print(f\"📊 Métadonnées du modèle:\")\n",
                    "print(f\"   Features: {iris.feature_names}\")\n",
                    "print(f\"   Classes: {iris.target_names}\")\n",
                    "print(f\"   Accuracy: {accuracy:.4f}\")"
                ]
            }
        ],
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3"
            },
            "language_info": {
                "codemirror_mode": {
                    "name": "ipython",
                    "version": 3
                },
                "file_extension": ".py",
                "mimetype": "text/x-python",
                "name": "python",
                "nbconvert_exporter": "python",
                "pygments_lexer": "ipython3",
                "version": "3.8.0"
            }
        },
        "nbformat": 4,
        "nbformat_minor": 4
    }
    
    # Sauvegarder le notebook
    output_path = "../notebooks/iris_classification_fixed.ipynb"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(notebook, f, indent=1, ensure_ascii=False)
    
    print(f"✅ Notebook corrigé créé: {output_path}")
    print("📝 Instructions pour l'ouvrir:")
    print("1. Dans votre workbench JupyterLab, naviguez vers le dossier 'triton-demo/notebooks'")
    print("2. Cliquez sur 'iris_classification_fixed.ipynb'")
    print("3. Exécutez les cellules dans l'ordre (de haut en bas)")

if __name__ == "__main__":
    create_fixed_notebook() 