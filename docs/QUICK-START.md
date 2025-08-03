# Guide d'Installation Rapide - OpenShift AI 2.22

## 🚀 Installation Express (5 minutes)

### Prérequis
- Cluster OpenShift 4.14+
- Accès cluster-admin
- Outil `oc` configuré

### Étapes

1. **Clone du repository**
```bash
git clone <this-repo>
cd openshift-ai-setup
```

2. **Déploiement GitOps COMPLET**
```bash
make gitops-deploy
```

3. **Vérification**
```bash
# Status
make status

# Vérification complète
make verify

# URL Dashboard
oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='https://{.spec.host}'
```

## 🧪 Test avec Utilisateurs

| Utilisateur | Mot de passe | Rôle |
|-------------|--------------|------|
| `mouachan` | `R3dH42025!` | cluster-admin |
| `admin` | `openshift123` | cluster-admin |
| `datascientist1` | `openshift123` | user |

## ✅ Fonctionnalités Déployées

- 🎯 **OpenShift AI Dashboard**
- 🚀 **Jupyter Workbenches**
- 📊 **Model Serving** (KServe + ModelMesh)
- 🔄 **Data Science Pipelines**
- ⚡ **Distributed Workloads** (CodeFlare + Ray)
- 📝 **Model Registry**
- 🛡️ **TrustyAI** (Explainable AI)
- 🎯 **Training Operator** (PyTorch/TensorFlow/XGBoost)
- 📋 **Kueue** (Job Queueing)
- 🕸️ **Service Mesh** (Istio)
- ⚡ **Serverless** (Knative)

## 🧹 Nettoyage

```bash
# Nettoyage sécurisé (préserve utilisateur actuel)
make cleanup-safe

# Nettoyage complet (⚠️ DANGER)
make cleanup-all
```

---

**C'est tout!** 🎉 Votre environnement OpenShift AI 2.22 complet est prêt.
