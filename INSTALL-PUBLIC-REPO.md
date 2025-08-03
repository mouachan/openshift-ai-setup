# Installation OpenShift AI via GitOps - Repository Public

## 🚀 Installation Ultra-Simple (2 commandes)

### Prérequis
- Cluster OpenShift 4.12+
- Accès cluster-admin
- Repository GitHub **PUBLIC** (pas de configuration SSH!)

### Installation complète

```bash
# 1. Installer OpenShift GitOps
oc apply -f https://raw.githubusercontent.com/mouachan/openshift-ai-setup/main/components/operators/openshift-gitops-operator/base/subscription.yaml

# 2. Déployer OpenShift AI complet
oc apply -f https://raw.githubusercontent.com/mouachan/openshift-ai-setup/main/argocd/openshift-ai-application-public.yaml
```

**C'est tout ! ArgoCD va tout installer automatiquement.**

## 🎯 Ce qui sera installé

- **OpenShift AI 2.22** (stable-2.22)
- **Minio S3** pour le stockage
- **Model Registry** avec MySQL
- **Utilisateurs et RBAC** de test
- **Service Mesh** (Istio)
- **Serverless** (Knative)
- **Pipelines** (Tekton)

## 📊 Monitoring du déploiement

### Via ArgoCD UI
```bash
# Obtenir l'URL ArgoCD
oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}'

# Mot de passe admin
oc get secret argocd-initial-admin-secret -n openshift-gitops -o jsonpath='{.data.password}' | base64 -d
```

### Via CLI
```bash
# Vérifier les applications ArgoCD
oc get applications -n openshift-gitops

# Vérifier OpenShift AI
oc get dsci,dsc

# Vérifier tous les composants
oc get pods -n redhat-ods-applications
oc get pods -n minio
```

## 🧹 Nettoyage (si nécessaire)

Si vous avez déjà OpenShift AI installé :

```bash
# Télécharger et exécuter le nettoyage
curl -O https://raw.githubusercontent.com/mouachan/openshift-ai-setup/main/cleanup-cluster.sh
chmod +x cleanup-cluster.sh
./cleanup-cluster.sh
```

## ✅ Avantages Repository Public

- ✅ **Pas de configuration SSH** 
- ✅ **Installation directe HTTPS**
- ✅ **Partage communautaire facile**
- ✅ **URLs raw GitHub utilisables**
- ✅ **Déploiement ultra-rapide**

## 🔧 Troubleshooting

### ArgoCD ne démarre pas
```bash
# Vérifier l'opérateur GitOps
oc get csv -n openshift-gitops

# Redémarrer ArgoCD
oc rollout restart deployment argocd-server -n openshift-gitops
```

### Application en erreur
```bash
# Voir les détails de l'application
oc describe application openshift-ai-setup -n openshift-gitops

# Forcer la synchronisation
oc patch application openshift-ai-setup -n openshift-gitops --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

---

**Profitez de votre OpenShift AI setup GitOps ! 🎉**
