#!/bin/bash
set -e

echo "🔧 Cleaning up old ArgoCD applications..."

# Remove any existing problematic applications
oc delete application.argoproj.io openshift-ai-simple -n openshift-gitops --ignore-not-found=true
oc delete application.argoproj.io model-registry-infrastructure -n openshift-gitops --ignore-not-found=true 
oc delete application.argoproj.io openshift-ai-platform -n openshift-gitops --ignore-not-found=true

echo "✅ Old applications cleaned up"

echo "🚀 Deploying single optimized ArgoCD application..."

# Deploy the single, optimized application
oc apply -f argocd-apps/openshift-ai-application.yaml

echo "✅ ArgoCD application deployed"

echo "📊 Checking application status..."
sleep 5
oc get applications.argoproj.io -n openshift-gitops

echo "🎯 GitOps setup complete!"
echo "Monitor with: oc get applications.argoproj.io -n openshift-gitops -w"
