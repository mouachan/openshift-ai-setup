# OpenShift AI 2.22 - Configuration GitOps COMPLETE 🚀

Configuration GitOps complète pour **OpenShift AI 2.22** avec **toutes les fonctionnalités officielles** documentées.

## 🎯 Fonctionnalités Incluses

### 🔧 Composants Core OpenShift AI
- ✅ **Data Science Dashboard** - Interface principale
- ✅ **Jupyter Workbenches** - Environnements de développement
- ✅ **Model Serving** - KServe + ModelMesh
- ✅ **Data Science Pipelines** - Kubeflow Pipelines
- ✅ **Distributed Workloads** - CodeFlare + Ray
- ✅ **Model Registry** - Gestion des modèles ML

### 🎯 Fonctionnalités Avancées 2.22
- ✅ **TrustyAI** - Explainable AI et monitoring
- ✅ **Training Operator** - PyTorch, TensorFlow, XGBoost, MPI
- ✅ **Kueue** - Job queueing et resource management
- ✅ **Service Mesh** - Istio pour sécurité et observabilité
- ✅ **Serverless** - Knative pour scaling automatique

### 👥 Gestion des Utilisateurs
- Configuration HTPasswd intelligente
- Préservation automatique de l'utilisateur actuel
- Utilisateurs pré-configurés pour tests
- Roles RBAC optimisés
- **Workbenches** : Jupyter notebooks avec GPU support
- **Model Serving** : KServe et ModelMesh
- **Data Science Pipelines** : MLOps avec Tekton
- **TrustyAI** : Explainability et bias detection

### 🧪 Technology Preview (2.22)
- **Model Registry v2.x** : Registry centralisé avec UI améliorée
- **Feature Store** : Stockage centralisé des features
- **LAB-tuning** : Fine-tuning de large language models
- **Distributed Workloads** : Orchestration avancée avec Kueue

### ☁️ Infrastructure Complète
- **S3 Storage** : MinIO pour artifacts et datasets
- **Database** : MySQL pour Model Registry
- **Service Mesh** : Istio pour sécurité mTLS
- **Monitoring** : Prometheus + Grafana + alertes

### 👥 Gestion Utilisateurs
- **OAuth HTPasswd** : Authentification intégrée
- **RBAC** : Permissions granulaires par rôle
- **Groupes** : data-scientists, data-engineers, mlops-engineers
- **Projects** : Isolation par utilisateur avec quotas

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     OpenShift AI 2.22                      │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Prerequisites                                      │
│ ├─ Service Mesh Operator                                    │
│ ├─ Serverless Operator                                      │
│ ├─ Pipelines Operator                                       │
│ ├─ OpenShift AI Operator                                    │
│ └─ OpenShift GitOps Operator (ArgoCD)                      │
├─────────────────────────────────────────────────────────────┤
│ Phase 2: Core AI Platform                                  │
│ ├─ DataScienceClusterInitialization (DSCI)                 │
│ ├─ DataScienceCluster (DSC)                                │
│ ├─ Dashboard + Workbenches                                  │
│ ├─ KServe + ModelMesh Serving                              │
│ ├─ Data Science Pipelines                                  │
│ ├─ TrustyAI + CodeFlare + Ray                              │
│ └─ Model Registry (Tech Preview)                           │
├─────────────────────────────────────────────────────────────┤
│ Phase 3: Advanced Components                               │
│ ├─ Service Mesh Control Plane                              │
│ ├─ Knative Serving + Eventing                              │
│ ├─ Model Registry v2 Configuration                         │
│ └─ Monitoring + Alerting                                   │
├─────────────────────────────────────────────────────────────┤
│ Phase 4: Storage & Infrastructure                          │
│ ├─ MinIO S3 (model artifacts, datasets)                    │
│ ├─ MySQL (Model Registry database)                         │
│ ├─ PVCs + StorageClasses                                   │
│ └─ Backup + Restore Jobs                                   │
├─────────────────────────────────────────────────────────────┤
│ Phase 5: Users & RBAC                                      │
│ ├─ OAuth HTPasswd Provider                                 │
│ ├─ Users + Groups                                          │
│ ├─ RBAC Bindings                                           │
│ └─ NetworkPolicies                                         │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Installation GitOps (Recommandée)

### Quick Start
```bash
# Cloner le repository
git clone <repo-url>
cd openshift-ai-setup

# Déploiement complet automatique
make gitops-deploy

# Ou déploiement phase par phase
make gitops-deploy-phase PHASE=1
make gitops-deploy-phase PHASE=2
make gitops-deploy-phase PHASE=3
make gitops-deploy-phase PHASE=4
make gitops-deploy-phase PHASE=5
```

### Installation détaillée

1. **Vérifier les prérequis**
```bash
# Vérifier la connexion au cluster
oc whoami
oc version

# Vérifier les permissions (cluster-admin requis)
oc auth can-i create clusterroles
```

2. **Simulation (recommandée)**
```bash
# Tester sans déployer
make gitops-dry-run
```

3. **Déploiement complet**
```bash
# Déploiement automatique avec monitoring
./deploy-openshift-ai.sh

# Ou via Makefile
make gitops-deploy
```

4. **Vérification du déploiement**
```bash
# Status global
make gitops-status

# Status détaillé des composants
oc get dsc,dsci -o wide
oc get pods -A | grep -E "(rhods|minio|mysql)"
```

## 📊 Accès aux Services

Une fois le déploiement terminé :

### 🌐 OpenShift AI Dashboard
```bash
# Obtenir l'URL
oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}'

# Accès: https://<dashboard-url>
# Utilisateurs par défaut:
# - admin / openshift123 (cluster admin)
# - rhods-admin / openshift123 (OpenShift AI admin)
# - datascientist1 / openshift123 (data scientist)
# - datascientist2 / openshift123 (data scientist)
# - dataengineer1 / openshift123 (data engineer)
# - mlops1 / openshift123 (MLOps engineer)
```

### 🗄️ MinIO S3 Console
```bash
# Obtenir l'URL
oc get route minio-console -n minio -o jsonpath='{.spec.host}'

# Accès: https://<minio-url>
# Username: admin
# Password: password123
```

### 📈 Monitoring
```bash
# Prometheus
oc get route prometheus -n redhat-ods-monitoring

# Grafana
oc get route grafana-route -n redhat-ods-monitoring
```

## 🧪 Technology Preview Features

### Model Registry v2.x
```bash
# Accéder via Dashboard > Settings > Model registry settings
# Ou directement:
oc get route model-registry -n model-registry
```

### LAB-tuning (Large Model Tuning)
```bash
# Vérifier si disponible
oc get pods -n redhat-ods-applications | grep lab-tuning

# Accès via Dashboard > Distributed workloads
```

### Distributed Workloads
```bash
# Vérifier Kueue operator
oc get pods -n kueue-system

# Créer des Ray clusters via Dashboard
```

## 📁 Structure du projet

```
├── gitops/                        # 🚀 GitOps déploiement OpenShift AI 2.22
│   ├── README.md                  # Documentation GitOps complète
│   ├── phase-01-prerequisites/    # Operators (Service Mesh, Serverless, etc.)
│   │   ├── README.md
│   │   ├── kustomization.yaml
│   │   ├── namespaces.yaml
│   │   ├── operator-groups.yaml
│   │   └── subscriptions.yaml
│   ├── phase-02-openshift-ai-core/ # DSCI, DSC, composants principaux
│   │   ├── README.md
│   │   ├── kustomization.yaml
│   │   ├── dsci.yaml
│   │   └── dsc.yaml
│   ├── phase-03-advanced-components/ # Service Mesh CP, Knative, Model Registry
│   │   ├── README.md
│   │   ├── kustomization.yaml
│   │   ├── service-mesh-control-plane.yaml
│   │   ├── knative-serving.yaml
│   │   ├── knative-eventing.yaml
│   │   └── monitoring-config.yaml
│   ├── phase-04-storage-and-infrastructure/ # MinIO, MySQL, PVCs, backups
│   │   ├── README.md
│   │   ├── kustomization.yaml
│   │   ├── namespaces.yaml
│   │   ├── minio-deployment.yaml
│   │   ├── mysql-deployment.yaml
│   │   ├── storage-configs.yaml
│   │   └── backup-configs.yaml
│   └── phase-05-users-and-rbac/   # OAuth, utilisateurs, permissions
│       ├── README.md
│       ├── kustomization.yaml
│       ├── oauth-provider.yaml
│       ├── users-groups.yaml
│       └── rbac-bindings.yaml
├── deploy-openshift-ai.sh         # 🚀 Script de déploiement automatique
├── Makefile                       # Commands GitOps intégrées
├── package.json                   # Métadonnées du projet
└── README.md                      # Documentation principale
```

## 👥 Utilisateurs créés par défaut

| Utilisateur | Rôle | Permissions | Mot de passe |
|-------------|------|-------------|--------------|
| `admin` | Super Admin | `cluster-admin` complet | `openshift123` |
| `mouachan` | Cluster Admin | `cluster-admin` complet | `openshift123` |
| `rhods-admin` | Admin OpenShift AI | Admin OpenShift AI | `openshift123` |
| `datascientist1` | Data Scientist | Workbenches + Model Serving | `openshift123` |
| `datascientist2` | Data Scientist | Workbenches + Pipelines | `openshift123` |
| `dataengineer1` | Data Engineer | Infrastructure + Storage | `openshift123` |
| `mlops1` | MLOps Engineer | Monitoring + Deployment | `openshift123` |

⚠️ **Production** : Changez tous les mots de passe par défaut !

## 🔧 Services déployés automatiquement

### 🌐 OpenShift AI Core
- **Dashboard** : Interface web principale
- **Workbenches** : Jupyter notebooks avec GPU support
- **Model Serving** : KServe + ModelMesh auto-scaling
- **Data Science Pipelines** : MLOps avec Tekton
- **TrustyAI** : Explainability et bias detection
- **CodeFlare + Ray** : Distributed computing

### 🧪 Technology Preview (2.22)
- **Model Registry v2.x** : Registry centralisé avec UI améliorée
- **Distributed Workloads** : Orchestration avec Kueue
- **LAB-tuning** : Fine-tuning de Large Language Models
- **Feature Store** : Stockage centralisé des features

### 🗄️ Infrastructure
- **MinIO S3** : Stockage compatible S3 (buckets: model-artifacts, datasets, pipelines, notebooks)
- **MySQL** : Base de données Model Registry avec backup automatique
- **Service Mesh** : Istio Control Plane avec mTLS
- **Monitoring** : Prometheus + Grafana + alertes personnalisées

## 📚 Documentation

- [📋 GitOps Guide Complet](gitops/README.md) - Documentation principale GitOps
- [🔧 Phase 1: Prerequisites](gitops/phase-01-prerequisites/README.md) - Service Mesh, Serverless, Pipelines
- [🤖 Phase 2: Core AI Platform](gitops/phase-02-openshift-ai-core/README.md) - DSCI, DSC, composants
- [🚀 Phase 3: Advanced Components](gitops/phase-03-advanced-components/README.md) - Service Mesh CP, Model Registry
- [🗄️ Phase 4: Storage & Infrastructure](gitops/phase-04-storage-and-infrastructure/README.md) - MinIO, MySQL, backups
- [👥 Phase 5: Users & RBAC](gitops/phase-05-users-and-rbac/README.md) - OAuth, utilisateurs, permissions

## 🛠️ Commandes GitOps

```bash
# 🚀 Déploiement complet automatique
make gitops-deploy

# 🔍 Simulation avant déploiement
make gitops-dry-run

# 📊 Status de tous les composants
make gitops-status

# 🏗️ Déploiement phase par phase
make gitops-deploy-phase PHASE=1  # Prerequisites
make gitops-deploy-phase PHASE=2  # OpenShift AI Core
make gitops-deploy-phase PHASE=3  # Advanced Components
make gitops-deploy-phase PHASE=4  # Storage & Infrastructure
make gitops-deploy-phase PHASE=5  # Users & RBAC

# 📚 Documentation GitOps
make gitops-docs

# 🧹 Nettoyage complet (avec confirmation)
make gitops-clean
```

### Commandes legacy (maintenues pour compatibilité)
```bash
# Vérifier le statut général
make status

# Tests utilisateurs (si configurés manuellement)
make test-users

# Nettoyer anciennes ressources
make clean

# Obtenir l'URL du dashboard
make dashboard-url
```

## ✅ Prérequis

- **Cluster OpenShift 4.12+** accessible
- **Permissions `cluster-admin`** requises
- **CLI `oc`** installé et configuré
- **Connexion internet** pour télécharger les images
- **Ressources cluster** : 16+ vCPU, 32+ GB RAM, 500+ GB storage
- **StorageClass** par défaut configurée (ex: gp3-csi, fast-ssd)

## 🔒 Sécurité intégrée

- ✅ **TLS/HTTPS** sur toutes les routes externes
- ✅ **Service Mesh mTLS** entre composants internes
- ✅ **NetworkPolicies** pour isolation réseau
- ✅ **RBAC granulaire** par rôles et namespaces
- ✅ **Secrets** chiffrés pour credentials
- ✅ **OAuth HTPasswd** provider sécurisé
- ✅ **Backup automatique** des données critiques

## 🤝 Contribution

1. Fork du projet
2. Créer une branche pour votre fonctionnalité
3. Commit de vos changements
4. Push vers la branche
5. Ouvrir une Pull Request

## 📝 Licence

MIT License - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🆘 Support

- Consultez la [documentation complète](docs/installation-guide.md)
- Ouvrez une issue sur GitHub pour les bugs
- Consultez les logs avec `oc logs` en cas de problème
