# 🆕 Installation sur Cluster OpenShift Clean

Guide complet pour installer OpenShift AI 2.22 via **pure GitOps** sur un cluster OpenShift propre.

## 🧹 IMPORTANT: Nettoyage préalable

**Si votre cluster a déjà OpenShift AI, Minio, ou d'autres composants, nettoyez d'abord :**

### Suppression OpenShift AI existant
```bash
# Supprimer les instances OpenShift AI
oc delete dsc --all
oc delete dsci --all

# Supprimer les namespaces OpenShift AI
oc delete namespace redhat-ods-applications --ignore-not-found
oc delete namespace redhat-ods-monitoring --ignore-not-found
oc delete namespace redhat-ods-operator --ignore-not-found

# Supprimer l'opérateur RHOAI
oc delete subscription rhods-operator -n openshift-operators --ignore-not-found
oc delete csv -n openshift-operators -l operators.coreos.com/rhods-operator.openshift-operators
```

### Suppression Minio et stockage S3
```bash
# Supprimer Minio si installé
oc delete deployment minio -n minio --ignore-not-found
oc delete namespace minio --ignore-not-found

# Supprimer autres stockages S3
oc delete pvc --all -n minio --ignore-not-found
```

### Suppression autres composants
```bash
# Supprimer Service Mesh si pas voulu
oc delete smcp --all -n istio-system --ignore-not-found
oc delete smmr --all -n istio-system --ignore-not-found
oc delete namespace istio-system --ignore-not-found

# Supprimer Serverless si pas voulu  
oc delete knativeserving --all -n knative-serving --ignore-not-found
oc delete namespace knative-serving --ignore-not-found

# Supprimer Pipelines si pas voulu
oc delete namespace openshift-pipelines --ignore-not-found
```

### Nettoyage complet (script automatique)
```bash
# Script de nettoyage complet - ATTENTION: supprime tout !
# Copier-coller ces commandes une par une

echo "🧹 Nettoyage complet du cluster..."

# 1. Supprimer OpenShift AI
echo "Suppression OpenShift AI..."
oc delete dsc --all --timeout=60s
oc delete dsci --all --timeout=60s
oc delete subscription rhods-operator -n openshift-operators --ignore-not-found
oc delete csv -n openshift-operators -l operators.coreos.com/rhods-operator.openshift-operators --ignore-not-found

# 2. Supprimer les namespaces OpenShift AI
echo "Suppression namespaces RHOAI..."
oc delete namespace redhat-ods-applications --timeout=120s --ignore-not-found
oc delete namespace redhat-ods-monitoring --timeout=120s --ignore-not-found  
oc delete namespace redhat-ods-operator --timeout=120s --ignore-not-found

# 3. Supprimer Minio et stockage
echo "Suppression Minio..."
oc delete namespace minio --timeout=120s --ignore-not-found
oc delete pv --selector=app=minio --ignore-not-found

# 4. Supprimer Service Mesh (optionnel)
echo "Suppression Service Mesh..."
oc delete smcp --all -n istio-system --timeout=60s --ignore-not-found
oc delete smmr --all -n istio-system --timeout=60s --ignore-not-found
oc delete namespace istio-system --timeout=120s --ignore-not-found

# 5. Supprimer Serverless (optionnel)
echo "Suppression Serverless..."
oc delete knativeserving --all -n knative-serving --timeout=60s --ignore-not-found
oc delete namespace knative-serving --timeout=120s --ignore-not-found

# 6. Supprimer Pipelines (optionnel)
echo "Suppression Pipelines..."
oc delete namespace openshift-pipelines --timeout=120s --ignore-not-found

# 7. Supprimer autres opérateurs si voulus
echo "Suppression autres opérateurs (optionnel)..."
oc delete subscription servicemeshoperator -n openshift-operators --ignore-not-found
oc delete subscription serverless-operator -n openshift-operators --ignore-not-found
oc delete subscription openshift-pipelines-operator-rh -n openshift-operators --ignore-not-found

# 8. Attendre et vérifier
echo "Attente nettoyage..."
sleep 60

echo "✅ Vérification finale:"
oc get dsc,dsci 2>/dev/null || echo "  ✅ Pas d'instances OpenShift AI"
oc get namespaces | grep -E "(ods|minio|istio|knative)" || echo "  ✅ Namespaces nettoyés"
echo "🎯 Cluster prêt pour installation GitOps !"
```

## 📋 Prérequis

- Cluster OpenShift 4.12+
- Accès administrateur cluster (`cluster-admin`)
- CLI `oc` installé et connecté
- **Cluster nettoyé** (voir section ci-dessus)

## 🚀 Installation Pure GitOps

### Étape 1: Cloner le repository

```bash
git clone https://github.com/mouachan/openshift-ai-setup.git
cd openshift-ai-setup
```

### Étape 2: Vérifications de base

```bash
# Vérifier la connexion
oc whoami --show-server

# Vérifier les permissions admin
oc auth can-i create clusterroles

# IMPORTANT: Vérifier que le cluster est clean
echo "🔍 Vérification cluster clean..."
oc get dsc,dsci 2>/dev/null && echo "❌ OpenShift AI encore présent!" || echo "✅ Pas d'OpenShift AI"
oc get namespaces | grep -E "(ods|minio)" && echo "❌ Namespaces à nettoyer!" || echo "✅ Namespaces clean"
```

### Étape 3: Déploiement en 2 commandes

```bash
# 1. Installer GitOps
oc apply -f components/operators/openshift-gitops-operator/base/subscription.yaml

# 2. Attendre 30s puis créer l'application ArgoCD  
sleep 30
oc apply -f argocd/openshift-ai-application.yaml
```

**C'est tout !** ArgoCD gère automatiquement tout le reste via GitHub.

## 📊 Monitoring GitOps

```bash
# Voir le statut des applications
oc get applications -n openshift-gitops

# Voir les opérateurs
oc get csv -n openshift-operators

# Voir OpenShift AI
oc get dsc,dsci

# Suivre en temps réel
watch oc get applications -n openshift-gitops
```

## ⏱️ Temps d'installation

| Étape | Temps estimé |
|-------|-------------|
| GitOps | 2-3 minutes |
| Application ArgoCD | 30 secondes |
| **ArgoCD fait le reste** | **10-12 minutes** |
| **Total** | **12-15 minutes** |

## 🌐 Accès aux interfaces

### ArgoCD
```bash
# URL ArgoCD
oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}'

# Mot de passe admin
oc get secret argocd-initial-admin-secret -n openshift-gitops -o jsonpath='{.data.password}' | base64 -d
```

### OpenShift AI
```bash
# URL Dashboard OpenShift AI
oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}'
```

## � Philosophie GitOps

**ArgoCD surveille automatiquement GitHub** et déploie :
- ✅ Tous les opérateurs dans l'ordre correct
- ✅ Toutes les instances de services  
- ✅ Gestion des dépendances
- ✅ Self-healing automatique
- ✅ Synchronisation continue

**Aucun script nécessaire !** Tout est déclaratif via Kustomize.

## 🆘 Dépannage GitOps

### GitOps ne s'installe pas
```bash
# Vérifier les permissions
oc auth can-i create clusterroles

# Réessayer l'installation
oc apply -f components/operators/openshift-gitops-operator/base/subscription.yaml
```

### Application ArgoCD en erreur
```bash
# Voir les détails dans ArgoCD UI
oc get route argocd-server -n openshift-gitops

# Forcer la synchronisation
oc patch application openshift-ai-main -n openshift-gitops -p '{"operation":{"sync":{}}}' --type merge
```

### Monitoring en temps réel
```bash
# Suivre tout via ArgoCD
watch oc get applications -n openshift-gitops

# Voir les erreurs éventuelles
oc describe application openshift-ai-main -n openshift-gitops
```

## 🧹 Nettoyage

```bash
# Supprimer l'application ArgoCD (garde GitOps et opérateurs)
oc delete application openshift-ai-main -n openshift-gitops

# Redéployer si nécessaire
oc apply -f argocd/openshift-ai-application.yaml
```

## ✅ Checklist post-installation

- [ ] GitOps installé: `oc get csv -n openshift-operators | grep gitops`
- [ ] Application ArgoCD créée: `oc get applications -n openshift-gitops`  
- [ ] Opérateurs en Succeeded: `oc get csv -n openshift-operators`
- [ ] OpenShift AI Ready: `oc get dsc`
- [ ] Dashboard accessible: `oc get route rhods-dashboard -n redhat-ods-applications`

## 🎯 Avantages GitOps pur

✅ **Zéro script** - Tout déclaratif  
✅ **Self-healing** - ArgoCD corrige automatiquement  
✅ **Audit trail** - Tout versionné dans Git  
✅ **Rollback facile** - Retour à un commit précédent  
✅ **Monitoring intégré** - Interface ArgoCD  

**2 commandes suffisent !**

1. `oc apply -f components/operators/openshift-gitops-operator/base/subscription.yaml`
2. `oc apply -f argocd/openshift-ai-application.yaml`
