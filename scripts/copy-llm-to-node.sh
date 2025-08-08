#!/bin/bash

# Script pour copier un LLM vers un nœud OpenShift
# Usage: ./copy-llm-to-node.sh <source-path> <node-name> <destination-path>

set -e

SOURCE_PATH="${1:-/path/to/llm/model}"
NODE_NAME="${2:-worker-0}"
DEST_PATH="${3:-/opt/llm/models}"
MODEL_NAME="${4:-llama2-7b}"

echo "🚀 Copie du LLM vers le nœud OpenShift"
echo "Source: $SOURCE_PATH"
echo "Nœud: $NODE_NAME"
echo "Destination: $DEST_PATH"
echo "Modèle: $MODEL_NAME"

# Étape 1: Créer un Pod temporaire avec accès au nœud
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: llm-copy-pod
  namespace: default
spec:
  nodeName: $NODE_NAME
  containers:
  - name: llm-copy
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/bash"]
    args: ["-c", "sleep 3600"]
    volumeMounts:
    - name: llm-storage
      mountPath: /opt/llm
    - name: host-storage
      mountPath: /host
      readOnly: true
  volumes:
  - name: llm-storage
    emptyDir: {}
  - name: host-storage
    hostPath:
      path: /
      type: Directory
  restartPolicy: Never
EOF

echo "⏳ Attendre que le Pod soit prêt..."
oc wait --for=condition=Ready pod/llm-copy-pod --timeout=300s

# Étape 2: Copier le modèle depuis la source
echo "📁 Copie du modèle depuis $SOURCE_PATH..."
if [[ "$SOURCE_PATH" == http* ]]; then
    # Téléchargement depuis une URL
    oc exec llm-copy-pod -- bash -c "
        mkdir -p $DEST_PATH
        cd $DEST_PATH
        wget -O $MODEL_NAME.tar.gz '$SOURCE_PATH'
        tar -xzf $MODEL_NAME.tar.gz
        rm $MODEL_NAME.tar.gz
        echo '✅ Modèle téléchargé et extrait'
    "
elif [[ -d "$SOURCE_PATH" ]]; then
    # Copie depuis un répertoire local
    echo "📦 Création d'un tar du modèle..."
    tar -czf /tmp/$MODEL_NAME.tar.gz -C "$SOURCE_PATH" .
    
    echo "📤 Upload vers le Pod..."
    oc cp /tmp/$MODEL_NAME.tar.gz llm-copy-pod:$DEST_PATH/
    
    echo "📁 Extraction du modèle..."
    oc exec llm-copy-pod -- bash -c "
        mkdir -p $DEST_PATH
        cd $DEST_PATH
        tar -xzf $MODEL_NAME.tar.gz
        rm $MODEL_NAME.tar.gz
        echo '✅ Modèle extrait'
    "
    
    rm /tmp/$MODEL_NAME.tar.gz
else
    echo "❌ Source invalide: $SOURCE_PATH"
    exit 1
fi

# Étape 3: Copier vers le système de fichiers du nœud
echo "🔄 Copie vers le système de fichiers du nœud..."
oc exec llm-copy-pod -- bash -c "
    mkdir -p /host$DEST_PATH
    cp -r $DEST_PATH/* /host$DEST_PATH/
    chmod -R 755 /host$DEST_PATH
    echo '✅ Modèle copié vers le nœud: /host$DEST_PATH'
"

# Étape 4: Nettoyage
echo "🧹 Nettoyage du Pod temporaire..."
oc delete pod llm-copy-pod

echo "🎉 LLM copié avec succès vers le nœud $NODE_NAME"
echo "📍 Emplacement: $DEST_PATH" 