# 🚀 OpenShift AI Setup - Production Ready

[![OpenShift](https://img.shields.io/badge/OpenShift-4.15+-red.svg)](https://www.openshift.com/)
[![RHOAI](https://img.shields.io/badge/RHOAI-2.8+-blue.svg)](https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-ai)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-green.svg)](https://argoproj.github.io/argo-cd/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **OpenShift AI Setup complet et production-ready avec architecture modulaire, GitOps et déploiement automatisé**

## 🎯 **Vue d'ensemble**

Ce projet fournit une **configuration complète et production-ready** d'OpenShift AI (RHOAI) avec une architecture modulaire, des composants personnalisés et une gestion GitOps via ArgoCD. Il inclut un workbench personnalisé, des runtimes de serving, un registre de modèles et une infrastructure complète pour le machine learning en production.

## ✨ **Fonctionnalités principales**

### 🖥️ **Workbench Personnalisé**
- **Image notebook personnalisée** avec toutes les bibliothèques ML/AI pré-installées
- **Runtime Elyra** configuré pour les pipelines Kubeflow
- **Interface JupyterLab** avec extensions Elyra pour la gestion des pipelines
- **Authentification OpenShift** intégrée

### 🔧 **Pipelines et ML**
- **Kubeflow Pipelines** via le serveur par défaut d'OpenShift AI
- **Runtime Elyra** configuré avec `NO_AUTHENTICATION` pour éviter les erreurs
- **Support Tekton** pour les pipelines CI/CD
- **Intégration MinIO** pour le stockage des artefacts

### 🚀 **Serving et Déploiement**
- **Runtimes personnalisés** : Triton Inference Server + Seldon MLServer
- **Model Registry** intégré pour la gestion des modèles
- **Knative Serving** pour le déploiement serverless
- **Service Mesh** (Istio) pour la gestion du trafic

### 🗄️ **Infrastructure**
- **MinIO** pour le stockage S3 compatible
- **Base de données** pour le registre de modèles
- **Persistent Volumes** pour la persistance des données
- **RBAC** configuré pour la sécurité

### 🔄 **GitOps et Automatisation**
- **ArgoCD** pour la synchronisation GitOps
- **Kustomize** pour la gestion des configurations
- **Déploiement automatisé** via Git
- **Gestion des environnements** (dev/prod)

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenShift Cluster                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   RHOAI     │  │  Custom     │  │   GitOps    │        │
│  │  Operator   │  │ Workbench   │  │   ArgoCD    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Kubeflow   │  │   Model     │  │   MinIO     │        │
│  │  Pipelines  │  │  Registry   │  │   Storage   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Triton    │  │   Seldon    │  │  Service    │        │
│  │  Runtime    │  │  Runtime    │  │   Mesh      │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 **Démarrage rapide**

### **Prérequis**
- OpenShift 4.15+
- RHOAI 2.8+
- Accès administrateur au cluster
- `oc` CLI configuré

### **Installation en une commande**
```bash
# Cloner le repository
git clone https://github.com/votre-org/openshift-ai-setup.git
cd openshift-ai-setup

# Installation complète
./install.sh
```

### **Installation manuelle**
```bash
# 1. Installer les opérateurs
oc apply -k components/operators/

# 2. Déployer l'infrastructure
oc apply -k components/instances/minio-instance/base/
oc apply -k components/instances/rhoai-instance/components/model-registry/

# 3. Déployer le workbench personnalisé
oc apply -k components/instances/triton-demo-instance/base/data-science-project/

# 4. Configurer GitOps
oc apply -k argocd-apps/
```

## 📁 **Structure du projet**

```
openshift-ai-setup/
├── 📁 components/                    # Composants modulaires
│   ├── 📁 instances/                # Instances d'infrastructure
│   │   ├── 📁 minio-instance/       # Stockage MinIO
│   │   ├── 📁 rhoai-instance/       # Configuration RHOAI
│   │   │   ├── 📁 components/       # Composants personnalisés
│   │   │   │   ├── 📁 custom-notebook-images/    # Images personnalisées
│   │   │   │   ├── 📁 custom-serving-runtimes/   # Runtimes de serving
│   │   │   │   └── 📁 model-registry/            # Registre de modèles
│   │   │   └── 📁 base/             # Configuration de base
│   │   ├── 📁 triton-demo-instance/ # Workbench personnalisé
│   │   ├── 📁 pipelines-instance/   # Configuration Tekton
│   │   ├── 📁 serverless-instance/  # Knative Serving
│   │   └── 📁 service-mesh-instance/ # Service Mesh
│   └── 📁 operators/                # Opérateurs OpenShift
├── 📁 argocd-apps/                  # Applications GitOps
├── 📁 clusters/                      # Configurations par environnement
├── 📁 demos/                        # Exemples et démonstrations
├── 📁 docs/                         # Documentation
├── 📁 scripts/                      # Scripts utilitaires
└── 📁 install.sh                     # Script d'installation principal
```

## 🔧 **Configuration personnalisée**

### **Image Notebook Personnalisée**
```yaml
# Image avec toutes les bibliothèques ML/AI pré-installées
image: image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/triton-demo-notebook:latest

# Bibliothèques incluses :
# - PyTorch 2.6.0
# - Langchain 0.3.25
# - Ultralytics 8.3.151
# - Python 3.11
# - Elyra + extensions
```

### **Runtime Elyra Configuré**
```yaml
# Configuration automatique pour OpenShift AI
auth_type: NO_AUTHENTICATION
endpoint: https://ds-pipeline-dspa-test-pipeline.apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com
engine: Argo
namespace: test-pipeline
```

### **Runtimes de Serving**
- **Triton Inference Server** : Optimisé pour l'inférence GPU
- **Seldon MLServer** : Compatible avec les modèles scikit-learn, XGBoost, etc.

## 📊 **Monitoring et Observabilité**

### **Métriques disponibles**
- **Pods et déploiements** : État des composants
- **Pipelines** : Exécution et performance
- **Modèles** : Versioning et déploiement
- **Stockage** : Utilisation MinIO

### **Logs et débogage**
```bash
# Vérifier l'état du workbench
oc get pods -n triton-demo

# Logs du workbench
oc logs triton-workbench-0 -n triton-demo -c triton-workbench

# État des pipelines
oc get datasciencepipelinesapplications -A
```

## 🔒 **Sécurité**

### **Authentification**
- **OpenShift OAuth** intégré
- **Service Accounts** avec RBAC approprié
- **Secrets** gérés via Kubernetes

### **RBAC configuré**
- **Namespace isolation** pour les projets
- **Permissions minimales** pour les utilisateurs
- **Cluster roles** pour les pipelines

## 🚀 **Utilisation**

### **Accéder au workbench**
1. Ouvrir la route : `triton-workbench-triton-demo.apps.<cluster>.opentlc.com`
2. Se connecter avec vos credentials OpenShift
3. Utiliser Elyra pour créer des pipelines

### **Créer un pipeline**
1. Ouvrir Elyra dans JupyterLab
2. Créer un nouveau pipeline
3. Sélectionner le runtime "Data Science Pipelines (OpenShift AI)"
4. Utiliser l'image "Triton Demo - Custom ML/AI Image"

### **Déployer un modèle**
1. Utiliser le Model Registry
2. Sélectionner le runtime de serving approprié
3. Déployer via Knative Serving

## 🧪 **Tests et Validation**

### **Scripts de test disponibles**
```bash
# Vérifier l'installation
./scripts/check-prerequisites.sh

# Tester le déploiement
./scripts/test-deployment.sh

# Valider les runtimes personnalisés
./scripts/validate-custom-runtimes.sh
```

### **Validation manuelle**
```bash
# Vérifier les pods
oc get pods -A | grep -E "(triton|minio|model-registry)"

# Tester l'API des pipelines
curl -k "https://ds-pipeline-dspa-test-pipeline.apps.<cluster>/api/v1/healthz"

# Vérifier les images
oc get imagestreams -n redhat-ods-applications
```

## 🔄 **Maintenance et Mises à jour**

### **Mise à jour via GitOps**
```bash
# Les modifications sont automatiquement appliquées
git push origin main
# ArgoCD synchronise automatiquement
```

### **Mise à jour manuelle**
```bash
# Appliquer les changements
oc apply -k components/instances/triton-demo-instance/base/

# Redémarrer le workbench si nécessaire
oc delete notebook triton-workbench -n triton-demo
oc apply -f components/instances/triton-demo-instance/base/data-science-project/workbench.yaml
```

## 📚 **Documentation détaillée**

- **[CUSTOM-NOTEBOOK-IMAGE.md](docs/CUSTOM-NOTEBOOK-IMAGE.md)** : Configuration des images personnalisées
- **[MODULAR-ARCHITECTURE.md](docs/MODULAR-ARCHITECTURE.md)** : Architecture modulaire du projet
- **[QUICK-START.md](docs/QUICK-START.md)** : Guide de démarrage rapide
- **[FINAL-SUMMARY.md](docs/FINAL-SUMMARY.md)** : Résumé de l'implémentation

## 🤝 **Contribution**

### **Structure des commits**
```
feat: Nouvelle fonctionnalité
fix: Correction de bug
docs: Documentation
refactor: Refactoring
test: Tests
chore: Maintenance
```

### **Processus de développement**
1. Créer une branche feature
2. Développer et tester
3. Créer une Pull Request
4. Code review et merge

## 📄 **Licence**

Ce projet est sous licence [MIT](LICENSE).

## 🙏 **Remerciements**

- **Red Hat** pour OpenShift AI (RHOAI)
- **Open Data Hub** pour l'écosystème
- **Kubeflow** pour les pipelines ML
- **ArgoCD** pour la gestion GitOps

---

## 🆘 **Support et Dépannage**

### **Problèmes courants**

#### **Erreur d'authentification pipeline**
```bash
# Utiliser la configuration par défaut d'OpenShift AI
# Vérifier que enableOauth: false n'est pas défini
```

#### **Workbench ne démarre pas**
```bash
# Vérifier les ressources
oc get pods -n triton-demo
oc describe pod triton-workbench-0 -n triton-demo
```

#### **MinIO inaccessible**
```bash
# Vérifier le service
oc get svc -n minio
oc get routes -n minio
```

### **Obtenir de l'aide**
- **Issues GitHub** : [Créer une issue](https://github.com/votre-org/openshift-ai-setup/issues)
- **Documentation** : Consulter les fichiers dans `docs/`
- **Scripts** : Utiliser les scripts de diagnostic dans `scripts/`

---

**🎉 Votre setup OpenShift AI est maintenant production-ready avec une architecture modulaire et une gestion GitOps !**
