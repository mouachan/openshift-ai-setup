#!/usr/bin/env python3
"""
Script pour tester l'authentification aux pipelines Kubeflow depuis le workbench
"""

import os
import requests
import subprocess
import json
from urllib3.exceptions import InsecureRequestWarning

# Supprimer les warnings SSL
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

def get_token():
    """Récupérer le token du service account"""
    token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
    try:
        with open(token_path, 'r') as f:
            return f.read().strip()
    except Exception as e:
        print(f"❌ Erreur lecture token: {e}")
        return None

def test_pipeline_auth():
    """Tester l'authentification aux pipelines"""
    print("🧪 Test d'authentification aux pipelines Kubeflow")
    print("=" * 50)
    
    # Configuration
    namespace = os.environ.get('KUBERNETES_NAMESPACE', 'triton-demo')
    cluster_domain = "apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"
    api_endpoint = f"https://ds-pipeline-{namespace}-pipelines-{namespace}.{cluster_domain}"
    
    print(f"🔗 Endpoint: {api_endpoint}")
    print(f"📁 Namespace: {namespace}")
    
    # Récupérer le token
    token = get_token()
    if not token:
        print("❌ Impossible de récupérer le token")
        return False
    
    print(f"🔑 Token: {token[:20]}...{token[-10:]} (longueur: {len(token)})")
    
    # Headers pour l'authentification
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    # Test 1: Vérifier la connectivité de base
    print("\n🔍 Test 1: Connectivité de base")
    try:
        response = requests.get(f"{api_endpoint}/apis/v2beta1/healthz", 
                              headers=headers, 
                              verify=False, 
                              timeout=10)
        print(f"📊 Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Connexion OK")
        else:
            print(f"⚠️ Status inattendu: {response.text[:200]}")
    except Exception as e:
        print(f"❌ Erreur connexion: {e}")
    
    # Test 2: Lister les experiments
    print("\n🔍 Test 2: Liste des experiments")
    try:
        url = f"{api_endpoint}/apis/v2beta1/experiments"
        params = {
            'page_token': '',
            'page_size': 10,
            'sort_by': '',
            'namespace': namespace
        }
        
        response = requests.get(url, 
                              headers=headers, 
                              params=params,
                              verify=False, 
                              timeout=10)
        
        print(f"📊 Status: {response.status_code}")
        print(f"📋 Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"✅ Experiments trouvés: {len(data.get('experiments', []))}")
                return True
            except json.JSONDecodeError:
                print(f"⚠️ Réponse non-JSON: {response.text[:200]}")
        elif response.status_code == 401:
            print("❌ Non autorisé - problème d'authentification")
        elif response.status_code == 403:
            print("❌ Interdit - problème de permissions")
        else:
            print(f"⚠️ Erreur: {response.text[:200]}")
            
    except Exception as e:
        print(f"❌ Erreur requête: {e}")
    
    return False

def check_elyra_config():
    """Vérifier la configuration Elyra"""
    print("\n🔍 Vérification configuration Elyra")
    print("-" * 40)
    
    config_path = "/opt/app-root/src/.local/share/jupyter/metadata/runtimes/data_science_pipelines.json"
    
    if os.path.exists(config_path):
        print(f"✅ Fichier config trouvé: {config_path}")
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
                print(f"📋 Display name: {config.get('display_name', 'N/A')}")
                print(f"🔐 Auth type: {config.get('metadata', {}).get('auth_type', 'N/A')}")
                print(f"🔗 API endpoint: {config.get('metadata', {}).get('api_endpoint', 'N/A')}")
                return True
        except Exception as e:
            print(f"❌ Erreur lecture config: {e}")
    else:
        print(f"❌ Fichier config non trouvé: {config_path}")
    
    return False

if __name__ == "__main__":
    print("🚀 Test d'authentification Pipeline OpenShift AI")
    print("=" * 60)
    
    # Vérifier la config Elyra
    check_elyra_config()
    
    # Tester l'auth
    success = test_pipeline_auth()
    
    print("\n" + "=" * 60)
    if success:
        print("🎉 SUCCÈS: Authentification aux pipelines OK!")
    else:
        print("❌ ÉCHEC: Problème d'authentification")
        print("\n💡 Solutions possibles:")
        print("   1. Vérifier les permissions RBAC du service account")
        print("   2. Redémarrer le workbench")
        print("   3. Vérifier la configuration OAuth du pipeline server")