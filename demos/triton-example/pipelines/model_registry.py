#!/usr/bin/env python3
"""
Étape 3: Model Registry
Push du modèle vers le Model Registry avec métadonnées
Utilise le SDK Model Registry officiel
"""

import os
import pickle
import argparse
import tarfile
import tempfile
from datetime import datetime
from model_registry import ModelRegistry
import boto3
from botocore.config import Config

def push_to_registry(model_path: str = "/tmp/model", registry_url: str = None):
    """Push du modèle vers le Model Registry"""
    
    print("🔄 Connexion au Model Registry...")
    
    # Configuration du Model Registry
    if not registry_url:
        registry_url = os.getenv("MODEL_REGISTRY_URL", "https://modelregistry-rest.apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com")
    
    # Initialiser le client Model Registry avec la nouvelle API
    try:
        registry = ModelRegistry(registry_url, author="OpenShift AI Pipeline")
        print(f"✅ Connecté au Model Registry: {registry_url}")
    except Exception as e:
        print(f"❌ Erreur de connexion au Model Registry: {e}")
        return False
    
    print("🔄 Chargement des métadonnées du modèle...")
    
    # Charger les métriques
    with open(f"{model_path}/metrics.pkl", "rb") as f:
        metrics = pickle.load(f)
    
    print(f"📊 Accuracy: {metrics['accuracy']:.4f}")
    print(f"📊 Model Type: {metrics['model_type']}")
    
    print("🔄 Création de l'archive du modèle...")
    
    # Créer une archive tar.gz du modèle
    with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as temp_file:
        archive_path = temp_file.name
        
    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(f"{model_path}/iris_classifier", arcname="iris_classifier")
    
    print(f"📦 Archive créée: {archive_path}")
    
    print("🔄 Upload vers MinIO S3...")
    
    # Configuration S3/MinIO
    s3_config = Config(
        region_name='us-east-1',
        signature_version='s3v4',
        s3={
            'addressing_style': 'path'
        }
    )
    
    s3_client = boto3.client(
        's3',
        endpoint_url=os.getenv("AWS_S3_ENDPOINT", "http://minio.db-ai.svc.cluster.local:9000"),
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID", "accesskey"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY", "secretkey"),
        config=s3_config
    )
    
    # Nom unique pour le modèle
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    s3_key = f"models/iris_classifier/{timestamp}/model.tar.gz"
    bucket_name = os.getenv("AWS_S3_BUCKET", "model-registry")
    
    try:
        # Créer le bucket s'il n'existe pas
        try:
            s3_client.head_bucket(Bucket=bucket_name)
        except:
            s3_client.create_bucket(Bucket=bucket_name)
            print(f"📦 Bucket '{bucket_name}' créé")
        
        # Upload du modèle
        s3_client.upload_file(archive_path, bucket_name, s3_key)
        s3_url = f"s3://{bucket_name}/{s3_key}"
        print(f"☁️ Modèle uploadé vers: {s3_url}")
        
    except Exception as e:
        print(f"❌ Erreur S3: {e}")
        return False
    
    print("🔄 Enregistrement dans le Model Registry...")
    
    try:
        # Utiliser la nouvelle API du SDK Model Registry
        model_name = "iris-classifier"
        version_name = f"v{timestamp}"
        
        # Enregistrer le modèle avec la nouvelle API
        model = registry.register_model(
            name=model_name,
            uri=s3_url,
            version=version_name,
            description=f"Iris classifier trained on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            model_format_name="onnx",  # Format compatible avec Triton
            model_format_version="1",
            storage_key="s3-connection",  # Clé de connexion S3
            storage_path=s3_key,
            metadata={
                "accuracy": metrics['accuracy'],
                "model_type": metrics['model_type'],
                "features": metrics['features'],
                "classes": metrics['classes'],
                "framework": "scikit-learn + onnx",
                "triton_compatible": True,
                "deployment_target": "nvidia-triton-runtime",
                "training_date": datetime.now().isoformat()
            }
        )
        
        print(f"🎯 Modèle enregistré: {model_name}")
        print(f"📋 Version: {version_name}")
        
        # Récupérer les informations du modèle
        registered_model = registry.get_registered_model(model_name)
        print(f"📋 Registered Model: {registered_model}")
        
        version = registry.get_model_version(model_name, version_name)
        print(f"📋 Model Version: {version}")
        
        # Nettoyer le fichier temporaire
        os.unlink(archive_path)
        
        print("✅ Modèle enregistré avec succès dans le Model Registry!")
        
        return {
            "model_name": model_name,
            "version": version_name,
            "s3_url": s3_url,
            "accuracy": metrics['accuracy']
        }
        
    except Exception as e:
        print(f"❌ Erreur Model Registry: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-path", default="/tmp/model", help="Chemin du modèle entraîné")
    parser.add_argument("--registry-url", help="URL du Model Registry")
    args = parser.parse_args()
    
    result = push_to_registry(args.model_path, args.registry_url)
    if result:
        print(f"🚀 Pipeline terminée! Model: {result['model_name']} v{result['version']}")
    else:
        print("❌ Échec du pipeline")
        exit(1)
