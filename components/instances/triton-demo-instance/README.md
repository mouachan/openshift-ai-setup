# Triton Demo Instance - Composant GitOps

Ce composant intègre la démo Triton dans le GitOps principal d'OpenShift AI, suivant l'approche "une feature = un répertoire".

## 🏗️ Architecture

```
components/instances/triton-demo-instance/
├── base/                          # Configuration de base
│   ├── kustomization.yaml         # Configuration principale
│   ├── data-science-project/      # Projet Data Science
│   │   ├── namespace.yaml         # Namespace triton-demo
│   │   ├── pipeline-server.yaml   # DataSciencePipelinesApplication
│   │   ├── workbench.yaml         # Notebook Jupyter avec Elyra
│   │   └── storage-config.yaml    # PVC, RBAC, secrets
│   └── model-serving/             # Configuration serving
│       ├── inference-service.yaml # KServe InferenceService
│       └── model-serving-config.yaml # Secrets S3, métriques
└── overlays/                      # Configurations par environnement
    └── development/               # Overlay développement
```

## 🚀 Intégration GitOps

### Dans le GitOps principal
```yaml
# clusters/overlays/openshift-ai-dev/kustomization.yaml
resources:
  # Infrastructure de base
  - ../../../components/instances/rhoai-instance
  - ../../../components/instances/pipelines-instance
  
  # Démo intégrée
  - ../../../components/instances/triton-demo-instance/base
```

### Sync Wave
- **Wave 3** : Après l'infrastructure RHOAI et pipelines
- **Dépendances** : Model Registry, Custom Serving Runtimes, Pipelines

## 📋 Composants déployés

### 1. Data Science Project (`triton-demo`)
- **Namespace** : `triton-demo` avec labels OpenShift AI
- **RBAC** : Service accounts et permissions pour pipelines
- **Network Policy** : Isolation réseau sécurisée
- **Storage** : PVC 20Gi pour le workbench

### 2. Pipeline Server Kubeflow
- **DataSciencePipelinesApplication** : Server pipelines complet
- **MariaDB** : Base de données pour métadonnées (10Gi)
- **MinIO** : Stockage S3 pour artefacts (50Gi)
- **UI** : Interface web pour visualisation

### 3. Workbench Jupyter avec Elyra
- **Image** : `registry.redhat.io/ubi8/python-39:1-117.1684740071`
- **Packages** : Elyra, KFP, scikit-learn, TensorFlow, model-registry
- **Configuration** : Runtime Kubeflow Pipelines pré-configuré
- **Resources** : 2 CPU, 8Gi RAM, 20Gi storage

### 4. Model Serving
- **InferenceService** : Template pour Triton
- **Secrets** : Accès S3 Model Registry
- **Monitoring** : Métriques Prometheus
- **HPA** : Auto-scaling 1-5 replicas

## 🎯 Avantages de l'intégration

### ✅ Avant (GitOps séparé)
- ❌ Duplication de configuration
- ❌ Deux points de gestion
- ❌ Incohérence entre démo et infrastructure
- ❌ Maintenance complexe

### ✅ Après (GitOps intégré)
- ✅ Configuration unifiée
- ✅ Un seul point de gestion (ArgoCD)
- ✅ Cohérence garantie
- ✅ Maintenance simplifiée
- ✅ Déploiement automatique avec l'infrastructure

## 🔧 Utilisation

### Déploiement automatique
```bash
# La démo se déploie automatiquement avec OpenShift AI
oc apply -f argocd-apps/openshift-ai-application.yaml
```

### Déploiement manuel
```bash
# Déploiement du composant seul
oc apply -k components/instances/triton-demo-instance/base/
```

### Vérification
```bash
# Statut du namespace
oc get all -n triton-demo

# Statut ArgoCD
oc get applications.argoproj.io -n openshift-gitops
```

## 🌐 URLs d'accès

- **Workbench Jupyter** : `https://triton-workbench-triton-demo.apps.cluster.local`
- **Pipelines UI** : `https://ds-pipeline-ui-triton-demo-pipelines-triton-demo.apps.cluster.local`
- **OpenShift AI Dashboard** : `https://rhods-dashboard-redhat-ods-applications.apps.cluster.local/projects/triton-demo`

## 📚 Migration depuis l'ancien GitOps

L'ancien GitOps dans `demos/triton-example/gitops/` est maintenant **obsolète**. 

### Nettoyage
```bash
# Supprimer l'ancien GitOps
oc delete -k demos/triton-example/gitops/

# Le nouveau GitOps intégré prend le relais automatiquement
```

## 🔍 Debugging

### Vérification des dépendances
```bash
# Vérifier que l'infrastructure est prête
oc get datasciencecluster -n redhat-ods-applications
oc get servingruntime triton-custom-runtime -n redhat-ods-applications
```

### Logs ArgoCD
```bash
# Logs de l'application ArgoCD
oc logs -l app.kubernetes.io/name=openshift-ai-complete -n openshift-gitops
```

### Events du namespace
```bash
# Events récents
oc get events -n triton-demo --sort-by='.lastTimestamp'
``` 