# 🆕 Installation sur Cluster OpenShift Clean

Guide complet pour installer OpenShift AI 2.22 via **pure GitOps** sur un cluster OpenShift propre.

## 📋 Prérequis

- Cluster OpenShift 4.12+
- Accès administrateur cluster (`cluster-admin`)
- CLI `oc` installé et connecté

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
