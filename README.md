# OpenShift AI 2.22 - GitOps Deployment

Ce repository contient la configuration GitOps complète pour déployer OpenShift AI 2.22 avec Model Registry sur OpenShift.

## 🚀 Quick Start

### Prérequis
- Cluster OpenShift 4.14+
- Droits cluster-admin
- `oc` CLI configuré

### Installation complète

1. **Installer GitOps** :
   ```bash
   ./scripts/install-gitops.sh
   ```

2. **Déployer OpenShift AI** :
   ```bash
   oc apply -f argocd-apps/openshift-ai-application.yaml
   ```

3. **Vérifier le déploiement** :
   ```bash
   oc get applications.argoproj.io -n openshift-gitops
   ```

## 📁 Structure du Repository

```
├── argocd-apps/           # Applications ArgoCD
├── clusters/              # Configurations par environnement
│   └── overlays/
│       └── openshift-ai-dev/  # Configuration développement
├── components/            # Composants Kustomize
│   ├── operators/         # Opérateurs (GitOps, RHOAI, Service Mesh...)
│   └── instances/         # Instances (RHOAI, Model Registry, MySQL...)
├── docs/                  # Documentation
└── scripts/               # Scripts d'installation
```

## 🔧 Composants Inclus

- **OpenShift AI 2.22** (Red Hat OpenShift AI)
- **Model Registry** avec backends MySQL et MinIO S3
- **Service Mesh 2.6** pour la connectivité
- **OpenShift Serverless** pour KServe
- **OpenShift Pipelines** pour Tekton
- **Hooks ArgoCD** pour correction SSL automatique

## 🎯 Fonctionnalités

✅ **Déploiement 100% GitOps** - Tout via ArgoCD  
✅ **Model Registry fonctionnel** - MySQL + MinIO backends  
✅ **Correction SSL automatique** - Hooks ArgoCD intégrés  
✅ **Multi-environnements** - Structure overlay/base  
✅ **RBAC configuré** - Permissions utilisateurs  

## 📖 Documentation

- [Installation Guide](docs/installation-guide.md)
- [Configuration Model Registry](components/instances/model-registry-config/README.md)
- [ArgoCD Hooks SSL](components/instances/model-registry-config/base/README.md)

## 🐛 Troubleshooting

**Erreur SSL Model Registry** : Les hooks ArgoCD corrigent automatiquement l'erreur "packet length too long"

**Sync ArgoCD bloqué** : Vérifiez les logs avec `oc logs -n openshift-gitops deployment/openshift-gitops-application-controller`

## 📞 Support

Ce repository est maintenu pour OpenShift AI 2.22. Pour les versions plus récentes, consultez la documentation Red Hat officielle.
