#!/usr/bin/env python3
"""
Script de configuration Elyra pour l'intégration avec Kubeflow Pipelines
Crée les métadonnées runtime et les catalogues de composants
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, Any

# Configuration
ELYRA_METADATA_DIR = os.path.expanduser("~/.local/share/jupyter/metadata")
CLUSTER_DOMAIN = os.getenv("CLUSTER_DOMAIN", "apps.cluster.local")
NAMESPACE = "triton-demo"

def ensure_elyra_dirs():
    """Crée les répertoires Elyra nécessaires"""
    dirs = [
        f"{ELYRA_METADATA_DIR}/runtimes",
        f"{ELYRA_METADATA_DIR}/component-catalogs",
        f"{ELYRA_METADATA_DIR}/code-snippets",
    ]
    
    for dir_path in dirs:
        Path(dir_path).mkdir(parents=True, exist_ok=True)
        print(f"✓ Répertoire créé: {dir_path}")

def create_kubeflow_runtime() -> Dict[str, Any]:
    """Crée la configuration runtime Kubeflow Pipelines"""
    return {
        "display_name": "Triton Demo - Kubeflow Pipelines",
        "metadata": {
            "api_endpoint": f"https://ds-pipeline-{NAMESPACE}-pipelines-{NAMESPACE}.{CLUSTER_DOMAIN}",
            "api_username": "",
            "api_password": "",
            "cos_endpoint": f"http://minio-{NAMESPACE}-pipelines-{NAMESPACE}.{CLUSTER_DOMAIN}",
            "cos_username": "minio",
            "cos_password": "minio123",
            "cos_bucket": "mlpipeline",
            "cos_directory": "pipelines",
            "tags": ["triton", "demo", "inference"],
            "engine": "Kubeflow Pipelines",
            "auth_type": "NO_AUTHENTICATION",
            "runtime_type": "KUBEFLOW_PIPELINES",
            "api_version": "v1",
            "user_namespace": NAMESPACE,
            "engine_namespace": NAMESPACE,
            "cos_secure": False,
            "disable_ssl_verification": True
        },
        "schema_name": "kfp",
        "name": "triton_demo_kfp"
    }

def create_component_catalog() -> Dict[str, Any]:
    """Crée le catalogue de composants personnalisés"""
    return {
        "display_name": "Triton Demo - Component Catalog",
        "metadata": {
            "description": "Catalogue de composants pour la démo Triton",
            "runtime_type": "KUBEFLOW_PIPELINES",
            "categories": ["Machine Learning", "Data Processing", "Model Serving"],
            "tags": ["triton", "tensorflow", "scikit-learn", "model-registry"],
            "base_image": "registry.redhat.io/ubi8/python-39:1-117.1684740071"
        },
        "schema_name": "local-file-catalog",
        "name": "triton_demo_catalog"
    }

def create_airflow_runtime() -> Dict[str, Any]:
    """Crée une configuration runtime Airflow (optionnel)"""
    return {
        "display_name": "Triton Demo - Apache Airflow",
        "metadata": {
            "apache_airflow_host": f"http://airflow-webserver-{NAMESPACE}.{CLUSTER_DOMAIN}:8080",
            "apache_airflow_username": "admin",
            "apache_airflow_password": "admin",
            "cos_endpoint": f"http://minio-{NAMESPACE}-pipelines-{NAMESPACE}.{CLUSTER_DOMAIN}",
            "cos_username": "minio",
            "cos_password": "minio123",
            "cos_bucket": "mlpipeline",
            "cos_directory": "airflow",
            "tags": ["airflow", "demo"],
            "runtime_type": "APACHE_AIRFLOW",
            "user_namespace": NAMESPACE,
            "cos_secure": False
        },
        "schema_name": "airflow",
        "name": "triton_demo_airflow"
    }

def create_code_snippets() -> Dict[str, Any]:
    """Crée des snippets de code utiles pour la démo"""
    return {
        "display_name": "Triton Demo - Code Snippets",
        "metadata": {
            "description": "Snippets de code pour la démo Triton",
            "tags": ["triton", "kubeflow", "model-registry"],
            "language": "python"
        },
        "schema_name": "code-snippet",
        "name": "triton_demo_snippets",
        "snippets": {
            "model_registry_connection": {
                "name": "Model Registry Connection",
                "description": "Connexion au Model Registry",
                "code": '''
from model_registry import ModelRegistry

# Connexion au Model Registry
registry = ModelRegistry(
    server_address="http://model-registry-service.model-registry.svc.cluster.local:8080",
    author="demo-user"
)

# Lister les modèles
models = registry.get_registered_models()
print(f"Modèles disponibles: {[m.name for m in models]}")
''',
                "tags": ["model-registry", "connection"]
            },
            "kubeflow_pipeline_component": {
                "name": "Kubeflow Pipeline Component",
                "description": "Template pour composant de pipeline",
                "code": '''
from kfp import dsl
from kfp.dsl import component, Input, Output, Dataset, Model

@component(
    base_image="registry.redhat.io/ubi8/python-39:1-117.1684740071",
    packages_to_install=["scikit-learn", "pandas", "model-registry"]
)
def process_data(
    input_data: Input[Dataset],
    output_data: Output[Dataset],
    model_name: str = "iris_classifier"
):
    """Composant de traitement des données"""
    import pandas as pd
    
    # Votre code ici
    data = pd.read_csv(input_data.path)
    
    # Traitement...
    processed_data = data.copy()
    
    # Sauvegarde
    processed_data.to_csv(output_data.path, index=False)
''',
                "tags": ["kubeflow", "component", "pipeline"]
            },
            "triton_inference_test": {
                "name": "Triton Inference Test",
                "description": "Test d'inférence avec Triton",
                "code": '''
import requests
import json
import numpy as np

# Configuration
triton_url = "http://iris-classifier-triton-triton-demo.apps.cluster.local"
model_name = "iris_classifier"
model_version = "1"

# Données de test
test_data = [[5.1, 3.5, 1.4, 0.2]]  # Setosa

# Préparer la requête Triton
payload = {
    "inputs": [
        {
            "name": "input_features",
            "shape": [len(test_data), 4],
            "datatype": "FP32",
            "data": [item for sublist in test_data for item in sublist]
        }
    ],
    "outputs": [
        {"name": "predictions"},
        {"name": "probabilities"}
    ]
}

# Envoyer la requête
response = requests.post(
    f"{triton_url}/v2/models/{model_name}/versions/{model_version}/infer",
    headers={"Content-Type": "application/json"},
    data=json.dumps(payload)
)

# Afficher les résultats
if response.status_code == 200:
    result = response.json()
    prediction = result["outputs"][0]["data"][0]
    probabilities = result["outputs"][1]["data"]
    print(f"Prédiction: {prediction}")
    print(f"Probabilités: {probabilities}")
else:
    print(f"Erreur: {response.status_code} - {response.text}")
''',
                "tags": ["triton", "inference", "test"]
            }
        }
    }

def save_metadata(metadata: Dict[str, Any], file_path: str):
    """Sauvegarde les métadonnées dans un fichier JSON"""
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)
        print(f"✓ Métadonnées sauvegardées: {file_path}")
    except Exception as e:
        print(f"✗ Erreur lors de la sauvegarde {file_path}: {e}")

def configure_elyra():
    """Configuration principale d'Elyra"""
    print("🔧 Configuration d'Elyra pour la démo Triton")
    print("=" * 50)
    
    # Créer les répertoires
    ensure_elyra_dirs()
    
    # Créer le runtime Kubeflow
    kfp_runtime = create_kubeflow_runtime()
    save_metadata(
        kfp_runtime,
        f"{ELYRA_METADATA_DIR}/runtimes/triton_demo_kfp.json"
    )
    
    # Créer le catalogue de composants
    component_catalog = create_component_catalog()
    save_metadata(
        component_catalog,
        f"{ELYRA_METADATA_DIR}/component-catalogs/triton_demo_catalog.json"
    )
    
    # Créer les snippets de code
    code_snippets = create_code_snippets()
    save_metadata(
        code_snippets,
        f"{ELYRA_METADATA_DIR}/code-snippets/triton_demo_snippets.json"
    )
    
    print("\n" + "=" * 50)
    print("✅ Configuration Elyra terminée!")
    print("\nProchaines étapes:")
    print("1. Redémarrez Jupyter Lab/Notebook")
    print("2. Allez dans l'onglet 'Runtime Images' pour voir les configs")
    print("3. Créez un nouveau pipeline avec l'éditeur visuel")
    print("4. Utilisez les snippets de code disponibles")

def verify_configuration():
    """Vérifie que la configuration est correcte"""
    print("🔍 Vérification de la configuration Elyra...")
    
    files_to_check = [
        f"{ELYRA_METADATA_DIR}/runtimes/triton_demo_kfp.json",
        f"{ELYRA_METADATA_DIR}/component-catalogs/triton_demo_catalog.json",
        f"{ELYRA_METADATA_DIR}/code-snippets/triton_demo_snippets.json"
    ]
    
    all_good = True
    for file_path in files_to_check:
        if os.path.exists(file_path):
            print(f"✓ {file_path}")
        else:
            print(f"✗ {file_path}")
            all_good = False
    
    if all_good:
        print("\n✅ Toutes les configurations sont présentes!")
    else:
        print("\n❌ Certaines configurations manquent!")
        return False
    
    return True

def cleanup_elyra():
    """Nettoie la configuration Elyra"""
    print("🧹 Nettoyage de la configuration Elyra...")
    
    files_to_remove = [
        f"{ELYRA_METADATA_DIR}/runtimes/triton_demo_kfp.json",
        f"{ELYRA_METADATA_DIR}/component-catalogs/triton_demo_catalog.json",
        f"{ELYRA_METADATA_DIR}/code-snippets/triton_demo_snippets.json"
    ]
    
    for file_path in files_to_remove:
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                print(f"✓ Supprimé: {file_path}")
        except Exception as e:
            print(f"✗ Erreur lors de la suppression {file_path}: {e}")
    
    print("✅ Nettoyage terminé!")

def main():
    """Fonction principale"""
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "configure":
            configure_elyra()
        elif command == "verify":
            verify_configuration()
        elif command == "cleanup":
            cleanup_elyra()
        else:
            print(f"Commande inconnue: {command}")
            print("Usage: python configure_elyra.py {configure|verify|cleanup}")
            sys.exit(1)
    else:
        # Configuration par défaut
        configure_elyra()

if __name__ == "__main__":
    main()
