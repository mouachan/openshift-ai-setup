# 🚀 Quick Start - OpenShift AI GitOps

## Installation en 2 étapes

### 1. Vérifiez votre cluster
```bash
# Connectez-vous à OpenShift
oc whoami
oc auth can-i create clusterroles
```

### 2. Déployez OpenShift AI
```bash
# Installer GitOps
oc apply -f components/operators/openshift-gitops-operator/base/subscription.yaml

# Attendre puis créer l'application
sleep 30
oc apply -f argocd/openshift-ai-application.yaml
```

## ✅ Vérification

```bash
# Applications ArgoCD
oc get applications -n openshift-gitops

# Opérateurs
oc get csv -n openshift-operators | grep -E "(gitops|rhods)"

# OpenShift AI
oc get dsc
```

## 🌐 URLs

```bash
# ArgoCD
echo "https://$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}')"

# OpenShift AI
echo "https://$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}')"
```

## ⏱️ Temps d'installation

- GitOps: 2-3 minutes
- Application ArgoCD: 30 secondes  
- Déploiement complet: 10-15 minutes

## 🔧 Dépannage

```bash
# Forcer la synchronisation
oc patch application openshift-ai-main -n openshift-gitops -p '{"operation":{"sync":{}}}' --type merge

# Voir les détails
oc describe application openshift-ai-main -n openshift-gitops
```

**C'est tout ! ArgoCD gère automatiquement le reste.** 🎉
