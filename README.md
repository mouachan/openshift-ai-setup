# OpenShift AI 2.22 - GitOps Deployment

Ce repository contient la configuration GitOps complète pour déployer OpenShift AI 2.22 avec Model Registry sur OpenShift.

**✨ Restructuré avec l'approche RH AI Services BU** : "une feature = un répertoire" pour une meilleure maintenabilité.

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
│   └── instances/         # Instances consolidées
│       └── rhoai-instance/
│           ├── base/      # Instance RHOAI de base
│           └── components/
│               └── model-registry/  # ✨ Model Registry consolidé
└── docs/                  # Documentation
```

## 🔧 Composants Inclus

- **OpenShift AI 2.22** (Red Hat OpenShift AI)
- **Model Registry consolidé** avec backends MySQL et MinIO S3
- **Service Mesh 2.6** pour la connectivité  
- **OpenShift Serverless** pour KServe
- **OpenShift Pipelines** pour Tekton
- **Hooks ArgoCD** pour correction SSL automatique

## 🎯 Fonctionnalités

✅ **Déploiement 100% GitOps** - Tout via ArgoCD  
✅ **Model Registry consolidé** - Structure "une feature = un répertoire"  
✅ **Correction SSL automatique** - Hooks ArgoCD intégrés  
✅ **Multi-environnements** - Structure overlay/base  
✅ **RBAC configuré** - Permissions utilisateurs  
✅ **Best Practices RH AI Services BU** - Organisation optimisée

## 📖 Documentation

- [Installation Guide](docs/installation-guide.md)
- [Model Registry Consolidé](components/instances/rhoai-instance/components/model-registry/README.md)
- [Migration Consolidation](MODEL-REGISTRY-CONSOLIDATION.md)

## 🐛 Troubleshooting

**Erreur SSL Model Registry** : Les hooks ArgoCD corrigent automatiquement l'erreur "packet length too long"

**Sync ArgoCD bloqué** : Vérifiez les logs avec `oc logs -n openshift-gitops deployment/openshift-gitops-application-controller`

## 📞 Support

Ce repository est maintenu pour OpenShift AI 2.22. Pour les versions plus récentes, consultez la documentation Red Hat officielle.
