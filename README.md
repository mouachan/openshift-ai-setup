# OpenShift AI Setup via GitOps

Setup complet OpenShift AI 2.22 avec GitOps (ArgoCD) - **Repository Public pour installation ultra-simple!**

## 🚀 Installation Ultra-Rapide (2 commandes)

```bash
# 1. Installer OpenShift GitOps
oc apply -f https://raw.githubusercontent.com/mouachan/openshift-ai-setup/main/components/operators/openshift-gitops-operator/base/subscription.yaml

# 2. Déployer OpenShift AI complet  
oc apply -f https://raw.githubusercontent.com/mouachan/openshift-ai-setup/main/argocd/openshift-ai-application-public.yaml
```

**C'est tout ! ArgoCD installe automatiquement :**
- OpenShift AI 2.22 (stable-2.22)
- Minio S3 Storage
- Model Registry + MySQL  
- Utilisateurs et RBAC
- Service Mesh, Serverless, Pipelines

## � Documentation

- **[Installation Repository Public](INSTALL-PUBLIC-REPO.md)** - Installation ultra-simple
- **[Installation Cluster Propre](INSTALL-CLEAN-CLUSTER.md)** - Guide complet  
- **[Quick Start](QUICK-START.md)** - Démarrage rapide
