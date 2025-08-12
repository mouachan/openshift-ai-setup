# 🚀 Guide de Démarrage Rapide - OpenShift AI Setup

> **Démarrage en 5 minutes pour OpenShift AI avec workbench personnalisé et pipelines**

## ⚡ **Installation Express (5 minutes)**

### **1. Prérequis**
```bash
# Vérifier OpenShift CLI
oc version

# Vérifier l'accès au cluster
oc whoami

# Vérifier les droits administrateur
oc auth can-i create datascienceclusters --all-namespaces
```

### **2. Installation en une commande**
```bash
# Cloner et installer
git clone https://github.com/votre-org/openshift-ai-setup.git
cd openshift-ai-setup
./install.sh
```

### **3. Vérification rapide**
```bash
# Vérifier que tout fonctionne
oc get pods -A | grep -E "(triton|minio|model-registry)"
```

## 🔧 **Installation Manuelle (10 minutes)**

### **Étape 1 : Opérateurs**
```bash
# Installer tous les opérateurs nécessaires
oc apply -k components/operators/

# Attendre que les opérateurs soient prêts
oc get csv -A | grep -E "(rhods|servicemesh|serverless)"
```

### **Étape 2 : Infrastructure de base**
```bash
# MinIO pour le stockage
oc apply -k components/instances/minio-instance/base/

# Model Registry
oc apply -k components/instances/rhoai-instance/components/model-registry/

# Serving Runtimes personnalisés
oc apply -k components/instances/rhoai-instance/components/custom-serving-runtimes/
```

### **Étape 3 : Workbench personnalisé**
```bash
# Déployer le workbench avec image personnalisée
oc apply -k components/instances/triton-demo-instance/base/data-science-project/

# Attendre que le workbench démarre
oc get pods -n triton-demo -w
```

### **Étape 4 : Configuration Elyra**
```bash
# Appliquer la configuration Elyra
oc apply -f components/instances/triton-demo-instance/base/data-science-project/elyra-runtime-config.yaml

# Configurer le runtime dans le workbench
oc exec triton-workbench-0 -n triton-demo -c triton-workbench -- python3 /opt/app-root/elyra-config/init-runtime.py
```

### **Étape 5 : GitOps (optionnel)**
```bash
# Configurer ArgoCD pour la synchronisation automatique
oc apply -k argocd-apps/
```

## 🎯 **Premiers Pas**

### **Accéder au workbench**
1. **Ouvrir la route** : `triton-workbench-triton-demo.apps.<cluster>.opentlc.com`
2. **Se connecter** avec vos credentials OpenShift
3. **Vérifier Elyra** : L'extension devrait être visible dans JupyterLab

### **Créer votre premier pipeline**
1. **Ouvrir Elyra** dans JupyterLab
2. **Créer un pipeline** : `File > New > Pipeline`
3. **Sélectionner le runtime** : "Data Science Pipelines (OpenShift AI)"
4. **Ajouter des composants** et connecter
5. **Exécuter le pipeline**

### **Utiliser l'image personnalisée**
1. **Ouvrir un notebook** : `File > New > Notebook`
2. **Sélectionner l'image** : "Triton Demo - Custom ML/AI Image"
3. **Vérifier les bibliothèques** :
   ```python
   import torch
   import langchain
   import ultralytics
   print("✅ Toutes les bibliothèques sont disponibles!")
   ```

## 🔍 **Vérification de l'Installation**

### **Checklist de validation**
```bash
# ✅ Workbench fonctionnel
oc get pods -n triton-demo | grep Running

# ✅ MinIO accessible
oc get routes -n minio

# ✅ Model Registry configuré
oc get pods -n rhoai-model-registries

# ✅ Pipelines disponibles
oc get datasciencepipelinesapplications -A

# ✅ Images personnalisées
oc get imagestreams -n redhat-ods-applications | grep triton
```

### **Test de connectivité**
```bash
# Tester l'API des pipelines
curl -k "https://ds-pipeline-dspa-test-pipeline.apps.<cluster>/api/v1/healthz"

# Tester MinIO
curl -k "https://minio-api-minio.apps.<cluster>/health/live"
```

## 🚨 **Dépannage Rapide**

### **Workbench ne démarre pas**
```bash
# Vérifier les ressources
oc describe pod triton-workbench-0 -n triton-demo

# Vérifier les logs
oc logs triton-workbench-0 -n triton-demo -c triton-workbench

# Redémarrer si nécessaire
oc delete notebook triton-workbench -n triton-demo
oc apply -f components/instances/triton-demo-instance/base/data-science-project/workbench.yaml
```

### **Erreur d'authentification pipeline**
```bash
# Vérifier la configuration Elyra
oc exec triton-workbench-0 -n triton-demo -c triton-workbench -- cat /opt/app-root/src/.local/share/jupyter/metadata/runtimes/data_science_pipelines.json

# Reconfigurer si nécessaire
oc exec triton-workbench-0 -n triton-demo -c triton-workbench -- python3 /opt/app-root/elyra-config/init-runtime.py
```

### **MinIO inaccessible**
```bash
# Vérifier le service
oc get svc -n minio

# Vérifier les routes
oc get routes -n minIO

# Vérifier les pods
oc get pods -n minio
```

## 📚 **Prochaines Étapes**

### **Développement de pipelines**
- [Guide des pipelines Elyra](https://elyra.readthedocs.io/)
- [Exemples de pipelines](demos/triton-example/pipelines/)
- [Documentation Kubeflow](https://www.kubeflow.org/)

### **Déploiement de modèles**
- [Guide du Model Registry](docs/CUSTOM-NOTEBOOK-IMAGE.md)
- [Serving avec Triton](components/instances/rhoai-instance/components/custom-serving-runtimes/README.md)
- [Documentation Seldon](https://docs.seldon.io/)

### **Personnalisation avancée**
- [Architecture modulaire](docs/MODULAR-ARCHITECTURE.md)
- [Configuration des images](docs/CUSTOM-NOTEBOOK-IMAGE.md)
- [Gestion GitOps](argocd-apps/)

## 🎉 **Félicitations !**

Votre setup OpenShift AI est maintenant **100% fonctionnel** avec :
- ✅ **Workbench personnalisé** avec bibliothèques ML/AI
- ✅ **Pipelines Elyra** fonctionnels
- ✅ **Infrastructure complète** (MinIO, Model Registry, Serving)
- ✅ **GitOps** configuré pour la maintenance

**Vous êtes prêt à développer et déployer des solutions ML/AI en production !** 🚀

---

## 📞 **Besoin d'aide ?**

- **Documentation complète** : [README.md](../README.md)
- **Issues GitHub** : [Créer une issue](https://github.com/votre-org/openshift-ai-setup/issues)
- **Scripts de diagnostic** : [scripts/](../scripts/)
