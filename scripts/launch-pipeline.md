# 🚀 Guide de lancement de la Pipeline Triton Demo

## ✅ **Environnement prêt !**

Votre environnement OpenShift AI est maintenant déployé et fonctionnel :

- ✅ **Workbench** : `triton-workbench-0` (Running)
- ✅ **Model Registry** : `modelregistry` (Running)
- ✅ **MySQL** : `mysql` (Running)
- ✅ **MinIO** : `minio` (Running)

## 🔗 **Accès au Workbench**

**URL du workbench :**
```
https://triton-workbench-triton-demo.apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com
```

## 📊 **Comment lancer la pipeline**

### **Méthode 1 : Via le Workbench (Recommandée)**

1. **Ouvrez l'URL du workbench** dans votre navigateur
2. **Connectez-vous** avec vos credentials OpenShift
3. **Naviguez vers** : `demos/triton-example/notebooks/`
4. **Ouvrez** : `iris_classification_notebook.ipynb`
5. **Exécutez toutes les cellules** dans l'ordre

### **Méthode 2 : Via CLI**

```bash
# Vérifier le statut
./scripts/run-pipeline.sh status

# Lancer en mode CLI
./scripts/run-pipeline.sh cli
```

### **Méthode 3 : Via le script de test**

```bash
# Se connecter au workbench
oc exec -it triton-workbench-0 -n triton-demo -- bash

# Naviguer vers le projet
cd /opt/app-root/src/triton-example

# Tester le notebook
python test_notebook.py
```

## 🎯 **Étapes de la pipeline**

1. **Configuration de l'environnement**
   - Vérification des variables d'environnement
   - Création des dossiers nécessaires

2. **Chargement des données**
   - Dataset Iris (150 échantillons, 4 features)
   - Division train/test (80%/20%)

3. **Entraînement du modèle**
   - Random Forest (100 arbres)
   - Accuracy attendue : ~90%

4. **Conversion ONNX**
   - Export du modèle pour Triton
   - Validation de l'inférence

5. **Enregistrement Model Registry**
   - Upload vers S3/MinIO
   - Métadonnées complètes

6. **Test d'inférence**
   - Test avec Triton (si disponible)
   - Validation des prédictions

## 🔧 **Variables d'environnement configurées**

```yaml
# Model Registry
MODEL_REGISTRY_URL: "https://modelregistry-rest.apps.cluster-v2mx6.v2mx6.sandbox1062.opentlc.com"
MODEL_REGISTRY_DATABASE_URL: "mysql://mlmduser:TheBlurstOfTimes@mysql.db-ai.svc.cluster.local:3306/model_registry"

# S3/MinIO
AWS_ACCESS_KEY_ID: "accesskey"
AWS_SECRET_ACCESS_KEY: "secretkey"
AWS_S3_ENDPOINT: "minio.db-ai.svc.cluster.local:9000"
AWS_S3_BUCKET: "model-registry"
AWS_S3_FORCE_PATH_STYLE: "true"
```

## 📁 **Structure du projet dans le workbench**

```
/opt/app-root/src/triton-example/
├── notebooks/
│   └── iris_classification_notebook.ipynb  ← Notebook principal
├── pipelines/
│   ├── model_registry.py                   ← Script Model Registry
│   ├── model_training.py                   ← Script d'entraînement
│   └── ...
├── models/                                 ← Modèles entraînés
├── data/                                   ← Données
└── test_notebook.py                        ← Script de test
```

## 🚨 **Dépannage**

### **Workbench ne démarre pas**
```bash
# Vérifier les logs
oc logs triton-workbench-0 -n triton-demo

# Vérifier les ressources
oc describe pod triton-workbench-0 -n triton-demo
```

### **Erreur de connexion S3**
```bash
# Vérifier le secret
oc get secret triton-demo-s3-connection -n triton-demo -o yaml

# Tester la connexion MinIO
oc exec -it triton-workbench-0 -n triton-demo -- curl minio.db-ai.svc.cluster.local:9000
```

### **Erreur Model Registry**
```bash
# Vérifier le Model Registry
oc get pods -n rhoai-model-registries

# Vérifier MySQL
oc get pods -n db-ai | grep mysql
```

## 🎉 **Résultat attendu**

Après exécution complète de la pipeline, vous devriez avoir :

- ✅ **Modèle entraîné** : `models/iris_classifier.pkl`
- ✅ **Modèle ONNX** : `models/iris_classifier.onnx`
- ✅ **Métadonnées** : `models/model_metadata.json`
- ✅ **Modèle enregistré** dans le Model Registry
- ✅ **Accuracy** : ~90%

## 📞 **Support**

Si vous rencontrez des problèmes :

1. Vérifiez les logs avec `oc logs`
2. Consultez le README : `demos/triton-example/README.md`
3. Utilisez le script de test : `python test_notebook.py`

**Bonne exécution ! 🚀** 