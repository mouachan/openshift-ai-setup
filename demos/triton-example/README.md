# Triton Inference Server Demo

Cette démo illustre un workflow complet d'entraînement et de déploiement d'un modèle avec NVIDIA Triton Inference Server dans OpenShift AI.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌──────────────────┐
│   Data Science  │───▶│  Elyra Pipeline  │───▶│ Model Registry  │───▶│ Triton Serving  │
│    Workbench    │    │   (Kubeflow)     │    │   (MySQL+S3)    │    │   (KServe)       │
└─────────────────┘    └──────────────────┘    └─────────────────┘    └──────────────────┘
```

## Pipeline Kubeflow (3 étapes)

1. **Data Transformation** (`data_preprocessing.py`)
   - Chargement et nettoyage des données
   - Feature engineering
   - Division train/test

2. **Model Training** (`model_training.py`) 
   - Entraînement d'un modèle simple (scikit-learn)
   - Validation du modèle
   - Export au format TensorFlow SavedModel pour Triton

3. **Model Registry** (`model_registry.py`)
   - Push du modèle vers le Model Registry
   - Métadonnées et versioning
   - Intégration avec MinIO S3

## Déploiement

- **GitOps** : Déploiement automatique via ArgoCD
- **KServe** : Single Model Serving avec Triton runtime
- **Inference** : Script HTTP pour tester l'inférence

## Structure

```
demos/triton-example/
├── README.md
├── pipelines/
│   ├── iris_classification_pipeline.py    # Pipeline Elyra/Kubeflow
│   ├── data_preprocessing.py              # Étape 1: Transformation
│   ├── model_training.py                  # Étape 2: Entraînement  
│   └── model_registry.py                  # Étape 3: Registry
├── notebooks/
│   └── iris_classification_notebook.ipynb # Notebook de développement
├── models/
│   └── iris_model/                        # Modèle exporté pour Triton
└── scripts/
    └── test_inference.py                  # Test d'inférence HTTP
```

> **Note** : Le répertoire `deployment/` a été supprimé car le déploiement se fait maintenant via le GitOps intégré.
```

## � Exécution de la démo

### Option 1: Pipeline automatisé (Kubeflow)
```bash
# 1. Lancer le pipeline Kubeflow complet
python pipelines/iris_classification_pipeline.py

# 2. Surveiller l'exécution dans l'interface Kubeflow
# URL: https://your-cluster/pipelines
```

### Option 2: Notebook interactif (Workbench)
```bash
# 1. Accéder au workbench via OpenShift AI Dashboard
# URL: https://rhods-dashboard-redhat-ods-applications.apps.cluster.local/projects/triton-demo

# 2. Le workbench clone automatiquement la démo Triton depuis GitHub
# 3. Ouvrir triton-demo/notebooks/iris_classification_notebook.ipynb
# 4. Exécuter toutes les cellules
```

> **Note** : Le workbench clone automatiquement la démo Triton depuis GitHub au démarrage.

### Option 3: Exécution manuelle des étapes
```bash
# 1. Préparation des données
python pipelines/data_preprocessing.py

# 2. Entraînement du modèle
python pipelines/model_training.py

# 3. Enregistrement dans Model Registry
python pipelines/model_registry.py
```

## 🚀 Déploiement du modèle

### Déploiement automatique (GitOps intégré)
```bash
# Le GitOps est maintenant intégré dans le GitOps principal
# La démo se déploie automatiquement avec OpenShift AI

# Vérifier le statut du GitOps intégré
make check-gitops

# Vérification du statut
./scripts/deploy.sh status

# Test d'inférence
./scripts/deploy.sh test
```

### Déploiement manuel (déploiement du modèle uniquement)
```bash
# 1. Appliquer les configurations Kustomize
oc apply -k ../../components/instances/triton-demo-instance/base/model-serving/ -n triton-demo

# 2. Attendre que le service soit prêt
oc wait --for=condition=Ready inferenceservice/iris-classifier-triton -n triton-demo --timeout=300s

# 3. Récupérer l'URL du service
oc get inferenceservice iris-classifier-triton -n triton-demo -o jsonpath='{.status.url}'
```

## 🧪 Tests d'inférence

### Test automatique
```bash
# Test complet avec script Python
python scripts/test_inference.py --url <service-url>

# Test avec données personnalisées
python scripts/test_inference.py --url <service-url> --custom-data "[[5.1,3.5,1.4,0.2]]"
```

## 🔄 Migration vers GitOps intégré

### ⚠️ Changements importants
La démo Triton a été migrée vers le **GitOps intégré** dans le GitOps principal d'OpenShift AI.

### ✅ Avantages de la migration
- **Configuration unifiée** : Un seul GitOps pour tout
- **Déploiement automatique** : La démo se déploie avec l'infrastructure
- **Maintenance simplifiée** : Une seule configuration à gérer
- **Cohérence garantie** : Utilise l'infrastructure déployée

### 📚 Documentation de migration
- **Documentation complète** : `../../docs/TRITON-DEMO-GITOPS-MIGRATION.md`
- **Script de migration** : `../../scripts/migrate-triton-demo-to-gitops.sh`
- **Composant intégré** : `../../components/instances/triton-demo-instance/`

### 🚀 Utilisation du nouveau GitOps
```bash
# Déploiement automatique avec OpenShift AI
oc apply -f ../../argocd-apps/openshift-ai-application.yaml

# Vérification du statut
make check-gitops

# Accès aux services
oc get all -n triton-demo
```

### Test manuel avec curl
```bash
# Test de santé
curl -X GET <service-url>/v2/health/ready

# Test d'inférence
curl -X POST <service-url>/v2/models/iris_classifier/versions/1/infer 
  -H "Content-Type: application/json" 
  -d '{
    "inputs": [
      {
        "name": "input_features",
        "shape": [1, 4],
        "datatype": "FP32",
        "data": [5.1, 3.5, 1.4, 0.2]
      }
    ],
    "outputs": [
      {"name": "predictions"},
      {"name": "probabilities"}
    ]
  }'
```
