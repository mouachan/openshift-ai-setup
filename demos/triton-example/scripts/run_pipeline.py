#!/usr/bin/env python3
"""
Script pour lancer la pipeline Iris Classification avec KFP
"""

import os
import sys
import kfp
from kfp import dsl
import yaml

def main():
    print("🚀 Lancement de la pipeline Iris Classification")
    print("=" * 50)
    
    # Configuration KFP
    pipeline_server_url = "https://ds-pipeline-triton-demo-pipelines-triton-demo.apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"
    
    print(f"🔗 Connexion au pipeline server: {pipeline_server_url}")
    
    try:
        # Connexion au pipeline server
        client = kfp.Client(host=pipeline_server_url)
        print("✅ Connexion au pipeline server réussie")
        
        # Charger la pipeline compilée
        pipeline_file = "pipelines/iris_classification_triton_pipeline.yaml"
        if not os.path.exists(pipeline_file):
            print(f"❌ Fichier pipeline non trouvé: {pipeline_file}")
            print("🔧 Compilation de la pipeline...")
            os.system("python3 pipelines/iris_classification_pipeline.py")
        
        if os.path.exists(pipeline_file):
            print(f"📄 Pipeline trouvée: {pipeline_file}")
            
            # Créer une expérience
            experiment_name = "iris-classification"
            try:
                experiment = client.create_experiment(name=experiment_name)
                print(f"✅ Expérience créée: {experiment_name}")
            except:
                experiment = client.get_experiment(experiment_name=experiment_name)
                print(f"✅ Expérience existante récupérée: {experiment_name}")
            
            # Lancer la pipeline
            run_name = f"iris-classification-{os.getenv('USER', 'demo')}"
            run = client.run_pipeline(
                experiment_id=experiment.id,
                job_name=run_name,
                pipeline_package_path=pipeline_file
            )
            
            print(f"🚀 Pipeline lancée avec succès!")
            print(f"   Run ID: {run.id}")
            print(f"   Nom: {run_name}")
            print(f"   Statut: {run.run.status}")
            print(f"   URL: {pipeline_server_url}/#/runs/details/{run.id}")
            
            return run.id
            
        else:
            print("❌ Impossible de compiler la pipeline")
            return None
            
    except Exception as e:
        print(f"❌ Erreur lors du lancement de la pipeline: {e}")
        return None

if __name__ == "__main__":
    main() 