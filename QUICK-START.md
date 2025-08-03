# 🚀 Quick Start - OpenShift AI GitOps

## Déploiement en 3 étapes

### 1. Vérifiez votre cluster
```bash
# Vous devez être connecté à OpenShift
oc whoami
oc cluster-info
```

### 2. Installez GitOps (si pas déjà fait)
```bash
oc apply -f components/operators/gitops/base/subscription.yaml
# Attendez 2-3 minutes
oc get csv -n openshift-operators | grep gitops
```

### 3. Déployez OpenShift AI
```bash
oc apply -f argocd/openshift-ai-application.yaml
```

## ✅ Vérification rapide

```bash
# Voir les applications ArgoCD
oc get applications -n openshift-gitops

# URL ArgoCD
oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}'

# URL OpenShift AI (après ~10 minutes)
oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours d'installation..."
```

## 🔧 En cas de problème

```bash
# Voir l'état détaillé
oc describe application openshift-ai-main -n openshift-gitops

# Forcer la synchronisation
oc patch application openshift-ai-main -n openshift-gitops -p '{"operation":{"sync":{}}}' --type merge
```

## ⏱️ Temps d'installation

- GitOps : ~3 minutes
- Tous les opérateurs : ~8 minutes  
- Instances complètes : ~15 minutes total

**C'est tout ! 🎉**
