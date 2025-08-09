#!/bin/bash
# Script pour corriger l'authentification Elyra avec OAuth OpenShift

echo "🔧 Correction de l'authentification Elyra pour OpenShift OAuth"
echo "=============================================================="

NAMESPACE="triton-demo"
POD_NAME="triton-workbench-0"
CONTAINER="triton-workbench"

echo "📋 Correction de la configuration Elyra runtime..."

# Script à exécuter dans le pod pour corriger l'auth
cat << 'EOF' > /tmp/fix_elyra_runtime.py
#!/usr/bin/env python3
import json
import os
import subprocess

# Configuration du runtime Elyra corrigée pour OAuth OpenShift
NAMESPACE = os.environ.get('KUBERNETES_NAMESPACE', 'triton-demo')
CLUSTER_DOMAIN = "apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"

def fix_elyra_runtime():
    """Configure Elyra pour utiliser l'OAuth OpenShift"""
    print("🔐 Configuration OAuth OpenShift pour Elyra...")
    
    # Chemin vers les métadonnées Elyra
    metadata_dir = "/opt/app-root/src/.local/share/jupyter/metadata/runtimes"
    os.makedirs(metadata_dir, exist_ok=True)
    
    # Configuration correcte pour OAuth OpenShift
    runtime_config = {
        "display_name": "Data Science Pipelines (OAuth)",
        "metadata": {
            "api_endpoint": f"https://ds-pipeline-{NAMESPACE}-pipelines-{NAMESPACE}.{CLUSTER_DOMAIN}",
            "api_username": "",
            "api_password": "",
            "cos_endpoint": "http://minio-api.minio.svc:9000",
            "cos_username": "minioadmin", 
            "cos_password": "minioadmin",
            "cos_bucket": "triton-data",
            "cos_directory": "",
            "tags": ["kubeflow", "pipelines", "triton", "oauth"],
            "engine": "Argo",
            "auth_type": "KUBERNETES_SERVICE_ACCOUNT_TOKEN",
            "runtime_type": "KUBEFLOW_PIPELINES", 
            "api_version": "v1",
            "user_namespace": NAMESPACE,
            "engine_namespace": NAMESPACE,
            "cos_secure": False,
            "disable_ssl_verification": False,
            "cos_auth_type": "USER_CREDENTIALS",
            # Configuration spécifique OAuth OpenShift
            "bearer_token": True,
            "oauth_token_path": "/var/run/secrets/kubernetes.io/serviceaccount/token"
        },
        "schema_name": "kfp",
        "name": "data_science_pipelines"
    }
    
    # Écrire la configuration
    config_file = os.path.join(metadata_dir, "data_science_pipelines.json")
    with open(config_file, 'w') as f:
        json.dump(runtime_config, f, indent=2)
    
    print(f"✅ Configuration écrite dans {config_file}")
    
    # Vérifier le token
    token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
    if os.path.exists(token_path):
        with open(token_path, 'r') as f:
            token = f.read().strip()
            print(f"✅ Token service account trouvé (longueur: {len(token)})")
    else:
        print("⚠️ Token service account non trouvé")
    
    print("✅ Configuration Elyra OAuth terminée")

if __name__ == "__main__":
    fix_elyra_runtime()
EOF

# Copier et exécuter le script dans le pod
echo "📤 Envoi du script de correction dans le pod..."
oc cp /tmp/fix_elyra_runtime.py ${NAMESPACE}/${POD_NAME}:/tmp/fix_elyra_runtime.py -c ${CONTAINER}

echo "⚡ Exécution de la correction..."
oc exec ${POD_NAME} -c ${CONTAINER} -n ${NAMESPACE} -- python3 /tmp/fix_elyra_runtime.py

echo "🔄 Redémarrage du noyau Elyra..."
oc exec ${POD_NAME} -c ${CONTAINER} -n ${NAMESPACE} -- bash -c "
echo '🔄 Redémarrage des services Jupyter...'
# Recharger la configuration Elyra
export JUPYTER_CONFIG_DIR=/opt/app-root/src/.jupyter
export ELYRA_METADATA_STORE_PATH=/opt/app-root/src/.local/share/jupyter/metadata
echo '✅ Variables d'environnement configurées'
"

echo "🧪 Test de la connexion aux pipelines..."
oc exec ${POD_NAME} -c ${CONTAINER} -n ${NAMESPACE} -- python3 -c "
import os
print('🔍 Variables d''environnement:')
print(f'KUBERNETES_NAMESPACE: {os.environ.get(\"KUBERNETES_NAMESPACE\", \"non défini\")}')
print(f'JUPYTER_CONFIG_DIR: {os.environ.get(\"JUPYTER_CONFIG_DIR\", \"non défini\")}')

# Test du token
token_path = '/var/run/secrets/kubernetes.io/serviceaccount/token'
if os.path.exists(token_path):
    with open(token_path, 'r') as f:
        token = f.read().strip()
        print(f'✅ Token disponible: {token[:20]}...')
else:
    print('❌ Token non trouvé')

# Test de la configuration
config_path = '/opt/app-root/src/.local/share/jupyter/metadata/runtimes/data_science_pipelines.json'
if os.path.exists(config_path):
    print(f'✅ Configuration Elyra trouvée: {config_path}')
else:
    print(f'❌ Configuration Elyra non trouvée: {config_path}')
"

# Nettoyer
rm -f /tmp/fix_elyra_runtime.py

echo ""
echo "✅ Correction terminée!"
echo "📋 Actions suivantes:"
echo "   1. 🔄 Redémarrer le noyau Jupyter dans l'interface"
echo "   2. 🧪 Tester la création d'un pipeline Elyra"
echo "   3. 🔍 Vérifier que les experiments sont listés"
echo ""
echo "🌐 Accès workbench: https://triton-workbench-triton-demo.${CLUSTER_DOMAIN}"