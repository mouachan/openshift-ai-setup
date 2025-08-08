#!/usr/bin/env python3
"""
Script simple pour lancer la pipeline Iris Classification depuis le workbench
"""

import os
import subprocess
import json
import time
from datetime import datetime

def main():
    print("🚀 Lancement de la pipeline Iris Classification")
    print("=" * 50)
    
    # Vérifier que nous sommes dans le bon répertoire
    if not os.path.exists("pipelines/iris_classification_pipeline.py"):
        print("❌ Veuillez exécuter ce script depuis le répertoire triton-example")
        return
    
    # Compiler la pipeline si nécessaire
    pipeline_file = "pipelines/iris_classification_triton_pipeline.yaml"
    if not os.path.exists(pipeline_file):
        print("🔧 Compilation de la pipeline...")
        result = subprocess.run(["python3", "pipelines/iris_classification_pipeline.py"], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ Erreur lors de la compilation: {result.stderr}")
            return
        print("✅ Pipeline compilée avec succès")
    
    # Lancer la pipeline avec kubectl
    print("🚀 Déploiement de la pipeline...")
    
    # Créer un nom unique pour la pipeline
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    pipeline_name = f"iris-classification-{timestamp}"
    
    # Appliquer la pipeline
    apply_cmd = [
        "kubectl", "apply", "-f", pipeline_file,
        "-n", "triton-demo"
    ]
    
    print(f"📋 Commande: {' '.join(apply_cmd)}")
    result = subprocess.run(apply_cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"❌ Erreur lors du déploiement: {result.stderr}")
        return
    
    print("✅ Pipeline déployée avec succès")
    print(f"📄 Pipeline: {pipeline_name}")
    
    # Afficher les pods créés
    print("\n🔍 Vérification des pods...")
    time.sleep(5)
    
    pods_cmd = ["kubectl", "get", "pods", "-n", "triton-demo", "-l", "workflows.argoproj.io/workflow"]
    result = subprocess.run(pods_cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(result.stdout)
    else:
        print("⚠️ Impossible de récupérer les pods")
    
    # Afficher les workflows
    print("\n📊 Workflows Argo...")
    workflows_cmd = ["kubectl", "get", "workflows", "-n", "triton-demo"]
    result = subprocess.run(workflows_cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(result.stdout)
    else:
        print("⚠️ Impossible de récupérer les workflows")
    
    print(f"\n🎉 Pipeline lancée avec succès!")
    print(f"📁 Fichier: {pipeline_file}")
    print(f"🔗 Surveillez les logs avec: kubectl logs -n triton-demo -l workflows.argoproj.io/workflow -f")

if __name__ == "__main__":
    main() 