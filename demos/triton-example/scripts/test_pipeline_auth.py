#!/usr/bin/env python3
"""
Test script pour vérifier l'authentification et la connexion aux pipelines
Utilise le même mécanisme d'authentification qu'Elyra
"""

import os
import sys
import json
import requests
from urllib3.exceptions import InsecureRequestWarning

# Supprimer les avertissements SSL pour les tests
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

def get_kubernetes_token():
    """Récupère le token de service account Kubernetes"""
    token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
    try:
        if os.path.exists(token_path):
            with open(token_path, 'r') as f:
                token = f.read().strip()
                print(f"✅ Token Kubernetes trouvé (longueur: {len(token)} caractères)")
                return token
        else:
            print("❌ Token Kubernetes non trouvé")
            return None
    except Exception as e:
        print(f"❌ Erreur lors de la lecture du token: {e}")
        return None

def get_namespace():
    """Récupère le namespace courant"""
    namespace_path = "/var/run/secrets/kubernetes.io/serviceaccount/namespace"
    try:
        if os.path.exists(namespace_path):
            with open(namespace_path, 'r') as f:
                namespace = f.read().strip()
                print(f"✅ Namespace trouvé: {namespace}")
                return namespace
        else:
            print("⚠️ Namespace par défaut: triton-demo")
            return "triton-demo"
    except Exception as e:
        print(f"❌ Erreur lors de la lecture du namespace: {e}")
        return "triton-demo"

def test_pipeline_api_access():
    """Test l'accès à l'API des pipelines"""
    print("\n🔍 Test de l'accès à l'API des pipelines...")
    
    # Configuration
    cluster_domain = "apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"
    namespace = get_namespace()
    api_endpoint = f"https://ds-pipeline-{namespace}-pipelines-{namespace}.{cluster_domain}"
    
    print(f"📡 Endpoint API: {api_endpoint}")
    
    # Test de base - health check
    try:
        health_url = f"{api_endpoint}/api/v1/healthz"
        print(f"🏥 Test health check: {health_url}")
        
        response = requests.get(health_url, verify=False, timeout=10)
        print(f"📊 Status Code: {response.status_code}")
        print(f"📋 Réponse: {response.text[:200]}...")
        
        if response.status_code == 200:
            print("✅ Health check réussi")
        else:
            print(f"⚠️ Health check échoué: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erreur lors du health check: {e}")
    
    # Test d'authentification avec token
    token = get_kubernetes_token()
    if token:
        try:
            experiments_url = f"{api_endpoint}/api/v2beta1/experiments"
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            print(f"\n🔐 Test d'authentification: {experiments_url}")
            response = requests.get(experiments_url, headers=headers, verify=False, timeout=10)
            
            print(f"📊 Status Code: {response.status_code}")
            print(f"📋 Headers: {dict(response.headers)}")
            
            if response.status_code == 200:
                print("✅ Authentification réussie")
                try:
                    data = response.json()
                    print(f"📦 Nombre d'expériences: {len(data.get('experiments', []))}")
                except:
                    print("📋 Réponse valide mais pas de JSON")
            elif response.status_code == 401:
                print("❌ Authentification échouée - Token invalide")
            elif response.status_code == 403:
                print("❌ Authentification échouée - Permissions insuffisantes")
            else:
                print(f"⚠️ Réponse inattendue: {response.status_code}")
                print(f"📋 Contenu: {response.text[:500]}...")
                
        except Exception as e:
            print(f"❌ Erreur lors du test d'authentification: {e}")

def test_kfp_client():
    """Test avec le client KFP Python"""
    print("\n🐍 Test avec le client KFP Python...")
    
    try:
        import kfp
        print("✅ Module KFP importé")
        
        namespace = get_namespace()
        cluster_domain = "apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"
        api_endpoint = f"https://ds-pipeline-{namespace}-pipelines-{namespace}.{cluster_domain}"
        
        # Configuration du client avec authentification par token
        token = get_kubernetes_token()
        if token:
            client = kfp.Client(
                host=api_endpoint,
                existing_token=token,
                namespace=namespace
            )
            
            print(f"🔗 Client KFP configuré pour: {api_endpoint}")
            
            # Test de connexion
            try:
                experiments = client.list_experiments(namespace=namespace, page_size=1)
                print("✅ Connexion KFP réussie")
                print(f"📦 API client opérationnel")
            except Exception as e:
                print(f"❌ Erreur KFP client: {e}")
                return False
                
        else:
            print("❌ Pas de token disponible pour KFP")
            return False
            
    except ImportError:
        print("❌ Module KFP non disponible")
        return False
    except Exception as e:
        print(f"❌ Erreur lors du test KFP: {e}")
        return False
    
    return True

def test_elyra_runtime_config():
    """Test la configuration Elyra"""
    print("\n⚙️ Test de la configuration Elyra...")
    
    metadata_dir = os.path.expanduser("~/.local/share/jupyter/metadata")
    runtime_file = os.path.join(metadata_dir, "runtimes", "data_science_pipelines.json")
    
    if os.path.exists(runtime_file):
        print(f"✅ Fichier de configuration trouvé: {runtime_file}")
        try:
            with open(runtime_file, 'r') as f:
                config = json.load(f)
                print(f"📋 Display name: {config.get('display_name')}")
                print(f"🔗 API endpoint: {config['metadata'].get('api_endpoint')}")
                print(f"🔐 Auth type: {config['metadata'].get('auth_type')}")
                print(f"🏷️ Namespace: {config['metadata'].get('user_namespace')}")
                
                if config['metadata'].get('auth_type') == 'KUBERNETES_SERVICE_ACCOUNT_TOKEN':
                    print("✅ Configuration d'authentification correcte")
                else:
                    print("⚠️ Type d'authentification inattendu")
                    
        except Exception as e:
            print(f"❌ Erreur lors de la lecture de la configuration: {e}")
    else:
        print(f"❌ Configuration Elyra non trouvée: {runtime_file}")

def main():
    """Fonction principale de test"""
    print("🧪 Test d'authentification et de connexion aux pipelines")
    print("=" * 60)
    
    # Informations d'environnement
    print(f"🌍 Variables d'environnement:")
    print(f"   KUBERNETES_SERVICE_HOST: {os.environ.get('KUBERNETES_SERVICE_HOST', 'Non défini')}")
    print(f"   KUBERNETES_SERVICE_PORT: {os.environ.get('KUBERNETES_SERVICE_PORT', 'Non défini')}")
    print(f"   USER: {os.environ.get('USER', 'Non défini')}")
    
    # Tests
    test_elyra_runtime_config()
    test_pipeline_api_access()
    success = test_kfp_client()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ Tests terminés avec succès!")
        print("🚀 La connexion aux pipelines devrait fonctionner dans Elyra")
    else:
        print("❌ Certains tests ont échoué")
        print("🔧 Vérifiez la configuration et les permissions RBAC")
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())