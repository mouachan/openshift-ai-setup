#!/bin/bash
# Script pour configurer Elyra avec NO_AUTHENTICATION (OAuth désactivé)

echo "🔧 Configuration Elyra pour NO_AUTHENTICATION"
echo "=============================================="

NAMESPACE="triton-demo"
POD_NAME="triton-workbench-0"
CONTAINER="triton-workbench"

echo "📋 Mise à jour de la configuration Elyra runtime..."

# Script pour corriger la configuration Elyra
cat << 'EOF' > /tmp/fix_elyra_no_auth.py
#!/usr/bin/env python3
import json
import os

# Configuration du runtime Elyra pour NO_AUTHENTICATION
NAMESPACE = os.environ.get('KUBERNETES_NAMESPACE', 'triton-demo')
CLUSTER_DOMAIN = "apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"

def fix_elyra_runtime():
    """Configure Elyra pour NO_AUTHENTICATION (OAuth désactivé)"""
    print("🔓 Configuration NO_AUTHENTICATION pour Elyra...")
    
    # Chemin vers les métadonnées Elyra
    metadata_dir = "/opt/app-root/src/.local/share/jupyter/metadata/runtimes"
    os.makedirs(metadata_dir, exist_ok=True)
    
    # Configuration pour NO_AUTHENTICATION
    runtime_config = {
        "display_name": "Data Science Pipelines (No Auth)",
        "metadata": {
            "api_endpoint": f"https://ds-pipeline-{NAMESPACE}-pipelines-{NAMESPACE}.{CLUSTER_DOMAIN}",
            "api_username": "",
            "api_password": "",
            "cos_endpoint": "http://minio-api.minio.svc:9000",
            "cos_username": "minioadmin", 
            "cos_password": "minioadmin",
            "cos_bucket": "triton-data",
            "cos_directory": "",
            "tags": ["kubeflow", "pipelines", "triton", "no-auth"],
            "engine": "Argo",
            "auth_type": "NO_AUTHENTICATION",
            "runtime_type": "KUBEFLOW_PIPELINES", 
            "api_version": "v1",
            "user_namespace": NAMESPACE,
            "engine_namespace": NAMESPACE,
            "cos_secure": False,
            "disable_ssl_verification": False,
            "cos_auth_type": "USER_CREDENTIALS"
        },
        "schema_name": "kfp",
        "name": "data_science_pipelines"
    }
    
    # Écrire la configuration
    config_file = os.path.join(metadata_dir, "data_science_pipelines.json")
    with open(config_file, 'w') as f:
        json.dump(runtime_config, f, indent=2)
    
    print(f"✅ Configuration NO_AUTH écrite dans {config_file}")
    print("✅ Configuration Elyra NO_AUTHENTICATION terminée")

if __name__ == "__main__":
    fix_elyra_runtime()
EOF

# Copier et exécuter le script dans le pod
echo "📤 Envoi du script de correction dans le pod..."
oc cp /tmp/fix_elyra_no_auth.py ${NAMESPACE}/${POD_NAME}:/tmp/fix_elyra_no_auth.py -c ${CONTAINER}

echo "⚡ Exécution de la correction..."
oc exec ${POD_NAME} -c ${CONTAINER} -n ${NAMESPACE} -- python3 /tmp/fix_elyra_no_auth.py

echo "🧪 Test de la nouvelle connexion..."
oc exec ${POD_NAME} -c ${CONTAINER} -n ${NAMESPACE} -- python3 /tmp/test-pipeline-auth.py

# Nettoyer
rm -f /tmp/fix_elyra_no_auth.py

echo ""
echo "✅ Configuration NO_AUTHENTICATION terminée!"
echo "📋 Actions suivantes:"
echo "   1. 🔄 Redémarrer le noyau Jupyter dans l'interface"
echo "   2. 🧪 Tester la création d'un pipeline Elyra"
echo "   3. 🔍 Vérifier que les experiments sont listés"
echo ""
echo "🔓 Auth Type: NO_AUTHENTICATION (OAuth désactivé)"