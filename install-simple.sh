#!/bin/bash
# Installation OpenShift AI GARANTIE - Version ultra-simple
# Usage: ./install-simple.sh

set -e

echo "🚀 INSTALLATION OPENSHIFT AI - VERSION SIMPLE"
echo "=============================================="
echo ""

# 1. Installer SEULEMENT l'opérateur RHOAI
echo "📋 Étape 1/3: Installation opérateur OpenShift AI"
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhods-operator
  namespace: openshift-operators
spec:
  channel: stable-2.22
  installPlanApproval: Automatic
  name: rhods-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

echo "⏳ Attente installation opérateur (60s)..."
sleep 60

# 2. Créer le namespace
echo "📋 Étape 2/3: Création namespace"
oc create namespace redhat-ods-operator --dry-run=client -o yaml | oc apply -f -

# 3. Installer OpenShift AI
echo "📋 Étape 3/3: Installation OpenShift AI"
oc apply -f - <<EOF
apiVersion: dscinitialization.opendatahub.io/v1
kind: DSCInitialization
metadata:
  name: default-dsci
  namespace: redhat-ods-operator
spec:
  applicationNamespace: redhat-ods-applications
  monitoring:
    managementState: Managed
    namespace: redhat-ods-monitoring
  serviceMesh:
    controlPlane:
      name: basic
      namespace: istio-system
    managementState: Managed
  trustedCABundle:
    managementState: Managed
---
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
  namespace: redhat-ods-operator
spec:
  components:
    dashboard:
      managementState: Managed
    workbenches:
      managementState: Managed
    modelmeshserving:
      managementState: Managed
    datasciencepipelines:
      managementState: Managed
    kserve:
      managementState: Managed
EOF

echo ""
echo "✅ INSTALLATION TERMINÉE !"
echo "========================"
echo ""
echo "🔍 Vérification:"
sleep 30
oc get dsci,dsc -n redhat-ods-operator

echo ""
echo "🌐 Accès OpenShift AI:"
echo "Attendez 5-10 minutes puis:"
RHOAI_URL=$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours d'installation...")
echo "URL: https://$RHOAI_URL"
echo ""
echo "🎯 FINI ! OpenShift AI sera accessible dans quelques minutes."
