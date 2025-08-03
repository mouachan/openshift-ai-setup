# OpenShift AI 2.22 - Déploiement GitOps avec Kustomize

Ce projet suit la structure et les bonnes pratiques du repository [rh-aiservices-bu/rhoaibu-cluster](https://github.com/rh-aiservices-bu/rhoaibu-cluster) avec une approche 100% GitOps utilisant Kustomize.

## 🏗️ Structure du Projet

```
clusters/
  overlays/
    openshift-ai-dev/          # Point d'entrée principal pour environnement dev
      kustomization.yaml       # Configuration principale Kustomize
      dev-patches.yaml         # Patches spécifiques dev

components/
  operators/                   # Opérateurs avec structure base/overlays
    openshift-gitops-operator/
      base/
        kustomization.yaml
        subscription.yaml
      kustomization.yaml
    openshift-service-mesh/
    kiali-operator/
    openshift-serverless-operator/
    openshift-pipelines-operator/
    rhoai-operator/             # OpenShift AI 2.22 (stable-2.22)
    
  instances/                   # Instances avec structure base/overlays
    service-mesh-instance/
      base/
        kustomization.yaml
        control-plane.yaml      # ServiceMeshControlPlane v2.5
      kustomization.yaml
    serverless-instance/
      base/
        kustomization.yaml
        knative.yaml           # KnativeServing + KnativeEventing
      kustomization.yaml
    pipelines-instance/
      base/
        kustomization.yaml
        pipelines-instance.yaml # TektonConfig avec intégration DS
      kustomization.yaml
    rhoai-instance/
      base/
        kustomization.yaml
        rhoai.yaml             # DSCInitialization + DataScienceCluster
      kustomization.yaml
```

## 🚀 Déploiement

### Option 1: Déploiement Complet (Recommandé)

```bash
# Déployer toute la stack OpenShift AI 2.22
kubectl apply -k clusters/overlays/openshift-ai-dev
```

### Option 2: Déploiement par Étapes

```bash
# 1. Déployer les opérateurs (dans l'ordre)
kubectl apply -k components/operators/openshift-gitops-operator
kubectl apply -k components/operators/openshift-service-mesh  
kubectl apply -k components/operators/kiali-operator
kubectl apply -k components/operators/openshift-serverless-operator
kubectl apply -k components/operators/openshift-pipelines-operator
kubectl apply -k components/operators/rhoai-operator

# 2. Attendre que les opérateurs soient prêts
kubectl wait --for=condition=Ready pod -l name=servicemeshoperator -n openshift-operators --timeout=300s

# 3. Déployer les instances
kubectl apply -k components/instances/service-mesh-instance
kubectl apply -k components/instances/serverless-instance  
kubectl apply -k components/instances/pipelines-instance
kubectl apply -k components/instances/rhoai-instance
```

## 🔍 Vérification du Déploiement

```bash
# Vérifier les opérateurs
kubectl get subscription -A | grep -E "(servicemesh|serverless|pipelines|rhods)"

# Vérifier Service Mesh
kubectl get servicemeshcontrolplane -n istio-system

# Vérifier Serverless  
kubectl get knativeserving -n knative-serving
kubectl get knativeeventing -n knative-eventing

# Vérifier Pipelines
kubectl get tektonconfig -n openshift-pipelines

# Vérifier OpenShift AI 2.22
kubectl get datasciencecluster,dscinitialization -A
```

## 🎯 Composants Déployés

### OpenShift AI 2.22
- **Canal**: `stable-2.22` (version fixe)
- **Composants**: Dashboard, Workbenches, Data Science Pipelines, KServe, CodeFlare, Kueue, ModelMesh, Ray, TrustyAI, Model Registry

### Service Mesh v2.5
- **Addons**: Jaeger, Kiali, Grafana
- **Sécurité**: mTLS automatique activé
- **Monitoring**: Intégré pour RHOAI

### Serverless
- **Ingress**: Istio Gateway intégré
- **Certificats**: Workload certificates activés
- **KServe**: Support complet pour model serving

### Pipelines
- **Version**: Latest stable
- **Intégrations**: Hub Tekton, Pipelines as Code
- **ML Support**: Optimisé pour data science workflows

## 🛠️ Personnalisation

### Modifier la Configuration

1. **Environnement de développement**: Éditer `clusters/overlays/openshift-ai-dev/dev-patches.yaml`
2. **Base operators**: Modifier les fichiers dans `components/operators/*/base/`  
3. **Base instances**: Modifier les fichiers dans `components/instances/*/base/`

### Créer un Nouvel Environnement

```bash
mkdir -p clusters/overlays/openshift-ai-prod
cp clusters/overlays/openshift-ai-dev/kustomization.yaml clusters/overlays/openshift-ai-prod/
# Modifier le kustomization.yaml pour production
```

## 🏷️ Conformité rh-aiservices-bu

Ce projet suit exactement la même structure que le repository de référence:
- ✅ Structure `base/` et `overlays/` avec Kustomize
- ✅ Séparation `operators/` et `instances/`  
- ✅ Point d'entrée `clusters/overlays/<ENVIRONMENT>`
- ✅ Patches environnement-spécifiques
- ✅ GitOps pur sans scripts shell
- ✅ OpenShift AI 2.22 avec canal stable-2.22

## 📝 Notes

- Les erreurs de lint VS Code sont normales (CRDs OpenShift non reconnus)
- L'ordre de déploiement est important (operators → instances)  
- Service Mesh doit être prêt avant KServe
- Compatible ArgoCD Applications pour automatisation complète
