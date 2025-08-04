#!/bin/bash
# Installation GitOps + OpenShift AI GARANTIE avec résolution automatique
# Usage: ./install-gitops.sh

set -e

echo "🚀 INSTALLATION GITOPS + OPENSHIFT AI"
echo "===================================="
echo ""

# 0. RÉSOLUTION DES PROBLÈMES
echo "📋 Étape 0/5: RÉSOLUTION PROBLÈMES"
echo "🔧 Création namespace redhat-ods-operator..."
oc create namespace redhat-ods-operator --dry-run=client -o yaml | oc apply -f -

echo "🔧 Nettoyage Service Mesh conflictuels..."
oc delete servicemeshcontrolplane --all --all-namespaces --ignore-not-found

echo "✅ Problèmes résolus"

# 1. GitOps
echo "📋 Étape 1/5: Vérification OpenShift GitOps"
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
echo "📋 Étape 2/5: Attente ArgoCD"
oc wait --for=condition=available deployment/openshift-gitops-server -n openshift-gitops --timeout=300s

# 3. PERMISSIONS CLUSTER-ADMIN POUR ARGOCD
echo "📋 Étape 3/5: PERMISSIONS CLUSTER-ADMIN"
echo "🔧 Attribution cluster-admin à ArgoCD..."
oc create clusterrolebinding openshift-gitops-argocd-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller \
  --dry-run=client -o yaml | oc apply -f -
echo "✅ Permissions accordées"

# 4. Projet
echo "📋 Étape 4/5: Configuration projet ArgoCD"
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

# 5. APPLICATION + FORCE SYNC
echo "📋 Étape 5/5: Application OpenShift AI"
if oc get applications.argoproj.io openshift-ai-simple -n openshift-gitops >/dev/null 2>&1; then
    echo "✅ Application existe - FORCE SYNCHRONISATION..."
    oc patch applications.argoproj.io openshift-ai-simple -n openshift-gitops --type merge -p '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'
else
    echo "🔧 Création application..."
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
    - SkipDryRunOnMissingResource=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF
fi

echo ""
echo "✅ TEKTON SUPPRIMÉ + SYNC FORCÉ !"
echo "================================="
echo ""

ARGOCD_URL=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)

echo "🌐 ArgoCD: https://$ARGOCD_URL"
echo "👤 User: admin"  
echo "🔑 Password: $ARGOCD_PASSWORD"
echo ""
echo "📊 SURVEILLANCE:"
echo "watch oc get applications.argoproj.io openshift-ai-simple -n openshift-gitops"