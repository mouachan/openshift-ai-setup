#!/usr/bin/env python3
"""
Script d'initialisation du workbench
Charge automatiquement le projet Git et configure l'environnement
"""

import os
import subprocess
import sys
from pathlib import Path

def run_command(cmd, cwd=None):
    """Exécute une commande et retourne le résultat"""
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True, cwd=cwd)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"❌ Erreur lors de l'exécution de '{cmd}': {e}")
        print(f"Stderr: {e.stderr}")
        return None

def init_workbench():
    """Initialise le workbench avec le projet Git"""
    
    print("🚀 Initialisation du workbench...")
    
    # Vérifier si Git est disponible
    if not run_command("git --version"):
        print("❌ Git n'est pas disponible")
        return False
    
    # Vérifier si le projet est déjà cloné
    project_path = Path("/opt/app-root/src/triton-example")
    if project_path.exists():
        print(f"📁 Projet déjà présent dans {project_path}")
        
        # Mettre à jour le projet
        print("🔄 Mise à jour du projet...")
        if not run_command("git pull origin main", cwd=project_path):
            print("⚠️ Impossible de mettre à jour le projet")
    else:
        # Cloner le projet
        repo_url = os.getenv("GIT_REPO", "https://github.com/mouachan/openshift-ai-setup.git")
        branch = os.getenv("GIT_BRANCH", "main")
        git_path = os.getenv("GIT_PATH", "demos/triton-example")
        
        print(f"📥 Clonage du projet depuis {repo_url}...")
        if not run_command(f"git clone -b {branch} {repo_url} /tmp/openshift-ai-setup"):
            print("❌ Impossible de cloner le projet")
            return False
        
        # Copier le dossier du projet
        source_path = Path(f"/tmp/openshift-ai-setup/{git_path}")
        if not source_path.exists():
            print(f"❌ Le chemin {source_path} n'existe pas")
            return False
        
        print(f"📋 Copie du projet vers {project_path}...")
        if not run_command(f"cp -r {source_path} {project_path}"):
            print("❌ Impossible de copier le projet")
            return False
        
        # Nettoyer
        run_command("rm -rf /tmp/openshift-ai-setup")
    
    # Installer les dépendances Python
    print("📦 Installation des dépendances Python...")
    requirements_file = project_path / "requirements.txt"
    if requirements_file.exists():
        if not run_command(f"pip install -r {requirements_file}"):
            print("⚠️ Erreur lors de l'installation des dépendances")
    
    # Créer le dossier data pour S3
    data_path = Path("/opt/app-root/src/data")
    data_path.mkdir(exist_ok=True)
    print(f"📁 Dossier data créé: {data_path}")
    
    # Créer un fichier de test pour vérifier S3
    test_file = data_path / "test_s3.txt"
    test_file.write_text("Test S3 connection - " + os.getenv("AWS_S3_ENDPOINT", "unknown"))
    print(f"📝 Fichier de test créé: {test_file}")
    
    # Afficher les informations de configuration
    print("\n📋 Configuration du workbench:")
    print(f"   📁 Projet: {project_path}")
    print(f"   📁 Data: {data_path}")
    print(f"   🔗 Model Registry: {os.getenv('MODEL_REGISTRY_URL', 'Non configuré')}")
    print(f"   ☁️ S3 Endpoint: {os.getenv('AWS_S3_ENDPOINT', 'Non configuré')}")
    print(f"   🪣 S3 Bucket: {os.getenv('AWS_S3_BUCKET', 'Non configuré')}")
    
    print("\n✅ Workbench initialisé avec succès!")
    print("🎯 Vous pouvez maintenant ouvrir les notebooks dans le dossier triton-example/notebooks/")
    
    return True

if __name__ == "__main__":
    success = init_workbench()
    sys.exit(0 if success else 1) 