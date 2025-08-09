#!/usr/bin/env python3
"""
Script pour corriger la configuration d'authentification Elyra
À exécuter dans le notebook workbench si les pipelines ne fonctionnent pas
"""

import os
import json
import sys
from pathlib import Path

def setup_elyra_auth():
    """Configure l'authentification Elyra pour Data Science Pipelines"""
    print("🔧 Configuration de l'authentification Elyra...")
    
    # Configuration
    NAMESPACE = "triton-demo"
    CLUSTER_DOMAIN = "apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"
    ELYRA_METADATA_DIR = os.path.expanduser("~/.local/share/jupyter/metadata")
    
    # Créer les répertoires nécessaires
    dirs = [
        f"{ELYRA_METADATA_DIR}/runtimes",
        f"{ELYRA_METADATA_DIR}/component-catalogs",
        f"{ELYRA_METADATA_DIR}/code-snippets",
    ]
    
    for dir_path in dirs:
        Path(dir_path).mkdir(parents=True, exist_ok=True)
        print(f"✓ Répertoire créé: {dir_path}")
    
    # Configuration du runtime avec authentification correcte
    runtime_config = {
        "display_name": "Data Science Pipelines (Fixed Auth)",
        "metadata": {
            "api_endpoint": f"https://ds-pipeline-{NAMESPACE}-pipelines-{NAMESPACE}.{CLUSTER_DOMAIN}",
            "api_username": "",
            "api_password": "",
            "cos_endpoint": "http://minio-api.minio.svc:9000",
            "cos_username": "minioadmin",
            "cos_password": "minioadmin",
            "cos_bucket": "triton-data",
            "cos_directory": "",
            "tags": ["kubeflow", "pipelines", "openshift", "fixed"],
            "engine": "Argo",
            "auth_type": "KUBERNETES_SERVICE_ACCOUNT_TOKEN",
            "runtime_type": "KUBEFLOW_PIPELINES",
            "api_version": "v1",
            "user_namespace": NAMESPACE,
            "engine_namespace": NAMESPACE,
            "cos_secure": False,
            "disable_ssl_verification": False,
            "cos_auth_type": "USER_CREDENTIALS"
        },
        "schema_name": "kfp",
        "name": "data_science_pipelines_fixed"
    }
    
    # Sauvegarder la configuration
    runtime_file = f"{ELYRA_METADATA_DIR}/runtimes/data_science_pipelines_fixed.json"
    
    try:
        with open(runtime_file, 'w') as f:
            json.dump(runtime_config, f, indent=2)
        print(f"✅ Configuration sauvegardée: {runtime_file}")
        
        # Afficher le résumé
        print("\n📋 Configuration du runtime:")
        print(f"   📛 Nom: {runtime_config['display_name']}")
        print(f"   🔗 Endpoint: {runtime_config['metadata']['api_endpoint']}")
        print(f"   🔐 Auth: {runtime_config['metadata']['auth_type']}")
        print(f"   📦 Bucket: {runtime_config['metadata']['cos_bucket']}")
        print(f"   🏷️ Namespace: {runtime_config['metadata']['user_namespace']}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la sauvegarde: {e}")
        return False

def verify_auth_setup():
    """Vérifie que l'authentification est correctement configurée"""
    print("\n🔍 Vérification de l'authentification...")
    
    # Vérifier le token
    token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
    if os.path.exists(token_path):
        print("✅ Token de service account trouvé")
        try:
            with open(token_path, 'r') as f:
                token = f.read().strip()
                print(f"✅ Token valide (longueur: {len(token)} caractères)")
        except Exception as e:
            print(f"⚠️ Erreur lecture token: {e}")
    else:
        print("❌ Token de service account manquant")
        return False
    
    # Vérifier le namespace
    namespace_path = "/var/run/secrets/kubernetes.io/serviceaccount/namespace"
    if os.path.exists(namespace_path):
        try:
            with open(namespace_path, 'r') as f:
                namespace = f.read().strip()
                print(f"✅ Namespace: {namespace}")
        except Exception as e:
            print(f"⚠️ Erreur lecture namespace: {e}")
    
    return True

def test_kfp_connection():
    """Test la connexion KFP avec la nouvelle configuration"""
    print("\n🧪 Test de connexion KFP...")
    
    try:
        import kfp
        
        # Configuration
        NAMESPACE = "triton-demo"
        CLUSTER_DOMAIN = "apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"
        api_endpoint = f"https://ds-pipeline-{NAMESPACE}-pipelines-{NAMESPACE}.{CLUSTER_DOMAIN}"
        
        # Lire le token
        token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        with open(token_path, 'r') as f:
            token = f.read().strip()
        
        # Créer le client
        client = kfp.Client(
            host=api_endpoint,
            existing_token=token,
            namespace=NAMESPACE
        )
        
        # Test
        experiments = client.list_experiments(namespace=NAMESPACE, page_size=1)
        print("✅ Connexion KFP réussie!")
        print(f"📊 Client opérationnel pour: {api_endpoint}")
        return True
        
    except Exception as e:
        print(f"❌ Erreur KFP: {e}")
        return False

def main():
    """Fonction principale"""
    print("🚀 Script de correction de l'authentification Elyra")
    print("=" * 55)
    
    # Étape 1: Configurer Elyra
    if not setup_elyra_auth():
        print("❌ Échec de la configuration Elyra")
        return 1
    
    # Étape 2: Vérifier l'authentification
    if not verify_auth_setup():
        print("❌ Problème d'authentification")
        return 1
    
    # Étape 3: Tester la connexion
    if test_kfp_connection():
        print("\n✅ Configuration réussie!")
        print("🎉 Vous pouvez maintenant utiliser les pipelines dans Elyra")
        print("📝 Utilisez le runtime 'Data Science Pipelines (Fixed Auth)'")
    else:
        print("\n⚠️ Configuration Elyra OK mais connexion KFP échouée")
        print("🔧 Vérifiez les permissions RBAC et le déploiement des pipelines")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())