# Déploiement GitOps OpenShift AI avec ArgoCD

## Vue d'ensemble

Ce dépôt contient une configuration GitOps complète pour déployer OpenShift AI 2.22 avec tous ses composants en utilisant Kustomize et ArgoCD.

## Structure du projet

```
clusters/overlays/openshift-ai-dev/     # Configuration principale
components/
├── operators/                          # Opérateurs requis
│   ├── gitops/                         # OpenShift GitOps
│   ├── service-mesh/                   # Red Hat Service Mesh
│   ├── kiali/                          # Kiali
│   ├── serverless/                     # OpenShift Serverless
│   ├── pipelines/                      # OpenShift Pipelines
│   ├── kueue/                          # Kueue (gestion des files d'attente)
│   └── rhoai/                          # Red Hat OpenShift AI
└── instances/                          # Instances des services
    ├── service-mesh-control-plane/     # Instance Service Mesh
    ├── kiali/                          # Instance Kiali
    └── knative-serving/                # Instance Knative Serving
argocd/                                 # Applications ArgoCD
```

## Prérequis

1. Cluster OpenShift 4.12+
2. OpenShift GitOps (ArgoCD) installé
3. Accès administrateur au cluster

## Installation d'OpenShift GitOps

Si GitOps n'est pas encore installé :

```bash
oc apply -f components/operators/gitops/base/subscription.yaml
```

Attendez que l'opérateur soit installé puis vérifiez :

```bash
oc get csv -n openshift-operators | grep gitops
```

## Déploiement avec ArgoCD

### Option 1 : Application unique (recommandée)

Déployez tout en une fois avec l'application principale :

```bash
oc apply -f argocd/openshift-ai-application.yaml
```

### Option 2 : App-of-Apps (déploiement par phases)

Pour un déploiement plus granulaire :

```bash
oc apply -f argocd/app-of-apps.yaml
```

## Vérification du déploiement

1. **Vérifiez les applications ArgoCD :**
   ```bash
   oc get applications -n openshift-gitops
   ```

2. **Accédez à l'interface ArgoCD :**
   ```bash
   oc get route argocd-server -n openshift-gitops
   ```

3. **Vérifiez les opérateurs installés :**
   ```bash
   oc get csv -n openshift-operators
   ```

4. **Vérifiez les instances de services :**
   ```bash
   oc get smcp -n istio-system
   oc get kiali -n istio-system  
   oc get knativeserving -n knative-serving
   ```

5. **Vérifiez OpenShift AI :**
   ```bash
   oc get datasciencecluster
   oc get route -n redhat-ods-applications
   ```

## Ordre d'installation

L'installation suit cet ordre pour éviter les dépendances :

1. **Opérateurs** (phase 1) :
   - OpenShift GitOps
   - Red Hat Service Mesh
   - Kiali
   - OpenShift Serverless
   - OpenShift Pipelines
   - Kueue
   - Red Hat OpenShift AI

2. **Instances** (phase 2) :
   - Service Mesh Control Plane
   - Kiali
   - Knative Serving

## Synchronisation et health checks

- **Sync Policy** : Manuel (peut être automatisé)
- **Health Checks** : Activés pour tous les composants
- **Self Heal** : Activé en mode automatique
- **Prune** : Activé pour nettoyer les ressources supprimées

## Dépannage

### Application en erreur
```bash
# Voir les détails de l'application
oc describe application openshift-ai-main -n openshift-gitops

# Forcer la synchronisation
oc patch application openshift-ai-main -n openshift-gitops -p '{"operation":{"sync":{}}}' --type merge
```

### Opérateur bloqué
```bash
# Vérifier l'état des subscriptions
oc get subscriptions -n openshift-operators

# Vérifier les install plans
oc get installplans -n openshift-operators
```

### Redémarrer le déploiement
```bash
# Supprimer l'application ArgoCD
oc delete application openshift-ai-main -n openshift-gitops

# Redéployer
oc apply -f argocd/openshift-ai-application.yaml
```

## Personnalisation

Pour adapter à votre environnement :

1. Modifier `clusters/overlays/openshift-ai-dev/kustomization.yaml`
2. Ajuster les versions dans les subscriptions des opérateurs
3. Modifier les configurations des instances selon vos besoins

## Support

- Version OpenShift AI : 2.22 (canal stable-2.22)
- Version Kustomize : Compatible avec OpenShift 4.12+
- Modèle GitOps : Basé sur rh-aiservices-bu/rhoaibu-cluster

## Ressources additionnelles

- [Documentation OpenShift AI](https://docs.redhat.com/en/documentation/red_hat_openshift_ai)
- [Guide Kustomize](https://kustomize.io/)
- [Documentation ArgoCD](https://argo-cd.readthedocs.io/)
