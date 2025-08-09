#!/bin/bash
# Script pour configurer Elyra avec l'URL interne du service (approche recommandée)

echo "🔧 Configuration Elyra avec URL interne du service"
echo "================================================"

NAMESPACE="triton-demo"
POD_NAME="triton-workbench-0"
CONTAINER="triton-workbench"

echo "📋 Configuration Elyra avec service interne..."

# Script pour configurer Elyra avec l'URL interne
cat << 'EOF' > /tmp/fix_elyra_internal.py
#!/usr/bin/env python3
import json
import os

# Configuration du runtime Elyra avec URL interne du service
NAMESPACE = os.environ.get('KUBERNETES_NAMESPACE', 'triton-demo')

def fix_elyra_runtime():
    """Configure Elyra pour utiliser l'URL interne du service"""
    print("🔗 Configuration URL interne pour Elyra...")
    
    # Chemin vers les métadonnées Elyra
    metadata_dir = "/opt/app-root/src/.local/share/jupyter/metadata/runtimes"
    os.makedirs(metadata_dir, exist_ok=True)
    
    # Configuration avec URL interne du service (recommandée par Red Hat)
    runtime_config = {
        "display_name": "Data Science Pipelines (Internal)",
        "metadata": {
            # URL interne du service (pas de route externe nécessaire)
            "api_endpoint": f"http://ds-pipeline-{NAMESPACE}-pipelines.{NAMESPACE}.svc.cluster.local:8888",
            "api_username": "",
            "api_password": "",
            "cos_endpoint": "http://minio-api.minio.svc:9000",
            "cos_username": "minioadmin", 
            "cos_password": "minioadmin",
            "cos_bucket": "triton-data",
            "cos_directory": "",
            "tags": ["kubeflow", "pipelines", "triton", "internal"],
            "engine": "Argo",
            "auth_type": "NO_AUTHENTICATION",
            "runtime_type": "KUBEFLOW_PIPELINES", 
            "api_version": "v1",
            "user_namespace": NAMESPACE,
            "engine_namespace": NAMESPACE,
            "cos_secure": False,
            "disable_ssl_verification": True,  # Nécessaire pour URL interne
            "cos_auth_type": "USER_CREDENTIALS"
        },
        "schema_name": "kfp",
        "name": "data_science_pipelines"
    }
    
    # Écrire la configuration
    config_file = os.path.join(metadata_dir, "data_science_pipelines.json")
    with open(config_file, 'w') as f:
        json.dump(runtime_config, f, indent=2)
    
    print(f"✅ Configuration interne écrite dans {config_file}")
    print("✅ Configuration Elyra URL interne terminée")

if __name__ == "__main__":
    fix_elyra_runtime()
EOF

# Copier et exécuter le script dans le pod
echo "📤 Envoi du script de correction dans le pod..."
oc cp /tmp/fix_elyra_internal.py ${NAMESPACE}/${POD_NAME}:/tmp/fix_elyra_internal.py -c ${CONTAINER}

echo "⚡ Exécution de la correction..."
oc exec ${POD_NAME} -c ${CONTAINER} -n ${NAMESPACE} -- python3 /tmp/fix_elyra_internal.py

echo "🧪 Test de connectivité interne..."
oc exec ${POD_NAME} -c ${CONTAINER} -n ${NAMESPACE} -- curl -s -o /dev/null -w "%{http_code}" http://ds-pipeline-triton-demo-pipelines.triton-demo.svc.cluster.local:8888/apis/v2beta1/healthz

echo ""
echo "🧪 Test complet..."
oc exec ${POD_NAME} -c ${CONTAINER} -n ${NAMESPACE} -- python3 -c "
import requests
try:
    response = requests.get('http://ds-pipeline-triton-demo-pipelines.triton-demo.svc.cluster.local:8888/apis/v2beta1/experiments?namespace=triton-demo', timeout=5)
    print(f'✅ API response status: {response.status_code}')
    if response.status_code == 200:
        data = response.json()
        print(f'✅ Experiments found: {len(data.get(\"experiments\", []))}')
    else:
        print(f'Response: {response.text[:200]}')
except Exception as e:
    print(f'❌ Error: {e}')
"

# Nettoyer
rm -f /tmp/fix_elyra_internal.py

echo ""
echo "✅ Configuration URL interne terminée!"
echo "📋 Cette approche utilise l'URL interne du service"
echo "    ce qui est la méthode recommandée par Red Hat"
echo ""
echo "🔗 URL interne: http://ds-pipeline-triton-demo-pipelines.triton-demo.svc.cluster.local:8888"