# Configuration Distributed Workloads - OpenShift AI 2.22

## Vue d'ensemble

Les distributed workloads permettent d'utiliser plusieurs nœuds en parallèle pour entraîner des modèles ML ou traiter des données plus rapidement. Cette fonctionnalité est activée par défaut dans notre configuration GitOps.

## Composants activés

Selon la [documentation Red Hat OpenShift AI 2.22](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.22/html-single/installing_and_uninstalling_openshift_ai_self-managed/index#installing-the-distributed-workloads-components_install), les composants suivants sont activés :

### Components requis pour distributed workloads
- **codeflare**: Framework CodeFlare pour tuning de modèles
- **kueue**: Gestionnaire de queues pour workloads distribués  
- **ray**: Ray framework pour calcul distribué
- **trainingoperator**: Kubeflow Training Operator pour entraînement distribué

### Configuration dans le DataScienceCluster
```yaml
spec:
  components:
    codeflare:
      managementState: Managed
    kueue:
      managementState: Managed
    ray:
      managementState: Managed
    trainingoperator:
      managementState: Managed
```

## Pourquoi pas d'opérateur Kueue séparé ?

OpenShift AI 2.22 gère Kueue automatiquement via son propre opérateur. Il n'est **pas nécessaire** d'installer un opérateur Kueue séparé. Les tentatives d'installation d'un opérateur Kueue indépendant peuvent causer des conflits d'API versions.

## Vérification de l'installation

Après déploiement, vérifiez que les pods suivants sont en cours d'exécution dans `redhat-ods-applications` :

```bash
# Vérifier les pods distributed workloads
oc get pods -n redhat-ods-applications | grep -E "(codeflare|kuberay|kueue|training)"

# Résultat attendu:
# codeflare-operator-manager-xxxxx
# kuberay-operator-xxxxx  
# kueue-controller-manager-xxxxx
# kubeflow-training-operator-xxxxx
```

## Utilisation

Une fois installé, les utilisateurs peuvent :
1. Utiliser CodeFlare dans les notebooks pour distributed training
2. Créer des Ray clusters pour calcul parallèle
3. Utiliser Training Operator pour PyTorch/TensorFlow distribué
4. Bénéficier de la gestion automatique des queues par Kueue

## Dépannage

### Problème : API version v1beta1 Configuration not found
**Cause**: Tentative d'utilisation d'APIs Kueue externes incompatibles
**Solution**: S'assurer que seuls les composants gérés par OpenShift AI sont utilisés

### Problème : OutOfSync status in ArgoCD
**Cause**: Conflits entre ressources Kueue manuelles et gérées
**Solution**: Supprimer les ressources Kueue manuelles et laisser OpenShift AI les gérer
