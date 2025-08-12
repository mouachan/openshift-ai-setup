#!/usr/bin/env python3
"""
Script de test pour vérifier la connectivité vers le pipeline server
avec les services internes (pas de routes externes)
"""

import requests
import json
import os

def test_pipeline_server():
    """Teste la connectivité vers le pipeline server"""
    print("🔍 Test de connectivité vers le pipeline server...")
    
    # Utiliser le service interne avec HTTPS
    pipeline_url = "https://ds-pipeline-dspa.triton-demo.svc:8888/apis/v1beta1/healthz"
    
    try:
        response = requests.get(pipeline_url, timeout=10, verify=False)
        if response.status_code == 200:
            print("✅ Pipeline server accessible via service interne")
            print(f"   Réponse: {response.text}")
            return True
        else:
            print(f"❌ Pipeline server accessible mais erreur HTTP: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erreur de connexion au pipeline server: {e}")
        return False

def test_minio_connection():
    """Teste la connectivité vers MinIO"""
    print("\n🔍 Test de connectivité vers MinIO...")
    
    # Utiliser le service interne
    minio_url = "http://minio-api.minio.svc:9000/minio/health/live"
    
    try:
        response = requests.get(minio_url, timeout=10)
        if response.status_code == 200:
            print("✅ MinIO accessible via service interne")
            return True
        else:
            print(f"❌ MinIO accessible mais erreur HTTP: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erreur de connexion à MinIO: {e}")
        return False

def test_kfp_api():
    """Teste l'API KFP directement"""
    print("\n🔍 Test de l'API KFP directement...")
    
    try:
        import requests
        
        # Tester l'API des expériences directement
        api_url = "https://ds-pipeline-dspa.triton-demo.svc:8888/apis/v1beta1/experiments"
        
        response = requests.get(api_url, verify=False, timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API des expériences accessible: {len(data.get('experiments', []))} expériences")
            return True
        else:
            print(f"⚠️ API des expériences accessible mais erreur HTTP: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Erreur lors de l'accès à l'API KFP: {e}")
        return False

def main():
    """Test principal"""
    print("🚀 Test de connectivité pour le pipeline server")
    print("=" * 50)
    
    # Test 1: Pipeline server
    pipeline_ok = test_pipeline_server()
    
    # Test 2: MinIO
    minio_ok = test_minio_connection()
    
    # Test 3: Client KFP
    kfp_ok = test_kfp_api()
    
    # Résumé
    print("\n" + "=" * 50)
    print("📊 RÉSUMÉ DES TESTS:")
    print(f"   Pipeline Server: {'✅ OK' if pipeline_ok else '❌ KO'}")
    print(f"   MinIO: {'✅ OK' if minio_ok else '❌ KO'}")
    print(f"   Client KFP: {'✅ OK' if kfp_ok else '❌ KO'}")
    
    if all([pipeline_ok, minio_ok, kfp_ok]):
        print("\n🎉 TOUS LES TESTS SONT PASSÉS!")
        print("   Le workbench peut maintenant se connecter au pipeline server")
    else:
        print("\n⚠️ CERTAINS TESTS ONT ÉCHOUÉ")
        print("   Vérifiez la configuration des services")

if __name__ == "__main__":
    main()
