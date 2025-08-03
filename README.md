# OpenShift AI 2.22 - GitOps Setup

Configuration GitOps pure pour déployer OpenShift AI 2.22 avec ArgoCD.

## 🚀 Installation sur cluster clean

```bash
# 1. Cloner le repository
git clone https://github.com/mouachan/openshift-ai-setup.git
cd openshift-ai-setup

# 2. Installer GitOps
oc apply -f components/operators/openshift-gitops-operator/base/subscription.yaml

# 3. Créer l'application ArgoCD
sleep 30
oc apply -f argocd/openshift-ai-application.yaml
```

## 📊 Monitoring

```bash
# Voir les applications ArgoCD
oc get applications -n openshift-gitops

# Voir les opérateurs
oc get csv -n openshift-operators

# Voir OpenShift AI
oc get dsc,dsci
```

## 🌐 Accès

```bash
# URL ArgoCD
oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}'

# URL OpenShift AI
oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}'
```

## 📁 Structure

```
clusters/overlays/openshift-ai-dev/     # Configuration principale
components/
├── operators/                          # Opérateurs (GitOps, Service Mesh, etc.)
└── instances/                          # Instances des services
argocd/                                 # Applications ArgoCD
```

## 📚 Documentation

- **[INSTALL-CLEAN-CLUSTER.md](INSTALL-CLEAN-CLUSTER.md)** - Guide installation cluster clean
- **[QUICK-START.md](QUICK-START.md)** - Démarrage rapide
- **[GITOPS-DEPLOYMENT.md](GITOPS-DEPLOYMENT.md)** - Guide complet GitOps

## ✅ Composants inclus

- OpenShift AI 2.22 (stable-2.22)
- Service Mesh (Istio)
- Serverless (Knative)
- Pipelines (Tekton)
- Kueue
- GitOps (ArgoCD)

## 🎯 Pure GitOps

- Zéro script
- Tout déclaratif
- Self-healing via ArgoCD
- Synchronisation automatique GitHub
