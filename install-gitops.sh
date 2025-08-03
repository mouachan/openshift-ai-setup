#!/bin/bash
# Installation GitOps + OpenShift AI GARANTIE avec Distributed Workloads
# Usage: ./install-gitops.sh
#
# Composants installés:
# - OpenShift GitOps (ArgoCD)
# - OpenShift AI 2.22 avec:
#   * Dashboard, Workbenches, Pipelines
#   * KServe pour model serving
#   * Distributed workloads: CodeFlare, Kueue, Ray, Training Operator
#   * Service Mesh et Serverless pour KServe

set -e

echo "🚀 INSTALLATION GITOPS + OPENSHIFT AI"
echo "===================================="
echo ""

# 1. Vérifier et installer GitOps si nécessaire
echo "📋 Étape 1/4: Vérification OpenShift GitOps"

if oc get sub openshift-gitops-operator -n openshift-operators >/dev/null 2>&1; then
    echo "✅ GitOps déjà installé"
else
    echo "🔧 Installation OpenShift GitOps..."
    oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
    echo "⏳ Attente installation GitOps (120s)..."
    sleep 120
fi

# 2. Attendre ArgoCD
echo "📋 Étape 2/4: Attente ArgoCD"
oc wait --for=condition=available deployment/openshift-gitops-server -n openshift-gitops --timeout=300s

# 3. Créer projet default s'il manque
echo "📋 Étape 3/4: Configuration projet ArgoCD"
oc apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: openshift-gitops
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  destinations:
  - namespace: '*'
    server: '*'
  sourceRepos:
  - '*'
EOF

# 4. Créer application OpenShift AI si elle n'existe pas
echo "📋 Étape 4/4: Création application OpenShift AI"

if oc get application openshift-ai-simple -n openshift-gitops >/dev/null 2>&1; then
    echo "✅ Application OpenShift AI déjà créée"
    oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.sync.status}' && echo ""
else
    echo "🔧 Création application OpenShift AI..."
    oc apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: openshift-ai-simple
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: https://github.com/mouachan/openshift-ai-setup.git
    targetRevision: main
    path: clusters/overlays/openshift-ai-dev
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-gitops
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - Replace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF
fi

echo ""
echo "✅ GITOPS INSTALLÉ !"
echo "==================="
echo ""

# Infos de connexion
echo "🌐 Accès ArgoCD:"
ARGOCD_URL=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)

echo "URL: https://$ARGOCD_URL"
echo "User: admin"  
echo "Password: $ARGOCD_PASSWORD"
echo ""
echo "🎯 L'application 'openshift-ai-simple' sera visible dans ArgoCD"
echo "🎯 OpenShift AI sera déployé automatiquement"
