#!/bin/bash

# Script GitOps pour déployer Triton Demo
# Commite et pousse les changements pour qu'ArgoCD les applique

set -e

echo "🚀 Déploiement GitOps de Triton Demo"

# Vérifier que nous sommes dans un repo git
if [ ! -d ".git" ]; then
    echo "❌ Erreur: Pas de repository git trouvé"
    exit 1
fi

# Vérifier le statut git
echo "📊 Statut Git actuel..."
git status

# Ajouter tous les fichiers modifiés
echo "📦 Ajout des fichiers modifiés..."
git add .

# Vérifier ce qui va être commité
echo "🔍 Fichiers à commiter:"
git diff --cached --name-only

# Demander confirmation
read -p "🤔 Continuer avec le commit ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Annulé par l'utilisateur"
    exit 1
fi

# Commit avec message descriptif
echo "💾 Commit des changements..."
git commit -m "🚀 Mise à jour Triton Demo Pipeline

- Alignement DSPA sur la configuration qui fonctionne
- Workbench optimisé avec Elyra et KFP
- Nouveaux ConfigMaps pour Elyra et certificats CA
- Scripts de test et déploiement GitOps

Configuration basée sur le namespace 'test' qui fonctionne"

# Push vers le remote
echo "📤 Push vers le remote..."
git push

echo "✅ Changements poussés avec succès!"
echo "🔄 ArgoCD va automatiquement appliquer les changements"
echo "⏳ Attendez quelques minutes que la synchronisation soit terminée"
echo ""
echo "💡 Pour vérifier le statut:"
echo "   - ArgoCD UI: Vérifiez la synchronisation"
echo "   - Cluster: oc get pods -n triton-demo"
echo "   - Test: ./scripts/test-triton-demo-pipeline.sh"
