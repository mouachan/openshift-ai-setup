# 🔍 DIAGNOSTIC COMPLET - Erreur SSL OpenShift AI

## 🎯 CAUSE RACINE IDENTIFIÉE

### Chaîne de Problèmes :
1. **Jaeger CRD manquant** → ServiceMesh échoue
2. **ServiceMesh not ready** → KServe échoue  
3. **KServe not ready** → DataScienceCluster NotReady
4. **Model Registry operator** redémarre (11 fois) à cause de l'instabilité
5. **Interface OpenShift AI** montre erreurs SSL/TLS

## 📊 Statut Détaillé

### ❌ Problèmes
- **ServiceMeshControlPlane**: `DependencyMissingError - Jaeger CRD missing`
- **DataScienceCluster**: `NotReady - Some components are not ready: kserve`
- **KServe**: `Error - ServiceMesh is not ready`
- **Model Registry Operator**: 11 redémarrages

### ✅ Composants Fonctionnels
- **Model Registry**: Ready et opérationnel
- **Model Catalog**: Enabled (`disableModelCatalog: false`)
- **Dashboard**: Running
- **MySQL + MinIO**: Opérationnels

## 🔧 SOLUTION IMMÉDIATE

### 1. Installer l'opérateur Jaeger
```bash
# Créer la subscription Jaeger
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger-product
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: jaeger-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

### 2. Vérifier l'installation Jaeger
```bash
# Attendre que les CRDs Jaeger soient disponibles
oc get crd | grep jaeger

# Vérifier l'opérateur
oc get csv -n openshift-operators | grep jaeger
```

### 3. Redémarrer le ServiceMesh
```bash
# Le ServiceMesh devrait se reconcilier automatiquement
# Sinon, forcer avec :
oc patch servicemeshcontrolplane basic -n istio-system --type='merge' -p='{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt":"'$(date +%Y-%m-%dT%H:%M:%S%z)'"}}}'
```

### 4. Vérification finale
```bash
# 1. ServiceMesh
oc get servicemeshcontrolplane -n istio-system

# 2. DataScienceCluster  
oc get datasciencecluster -A

# 3. Interface OpenShift AI
# → Tester dans le navigateur
```

## 🎯 RÉSOLUTION ATTENDUE

Après installation de Jaeger :
- **ServiceMesh** → Ready
- **KServe** → Ready  
- **DataScienceCluster** → Ready
- **Model Registry operator** → Stable
- **Interface OpenShift AI** → Erreurs SSL résolues

## 📋 Actions GitOps

Après résolution, ajouter Jaeger à notre GitOps :
```yaml
# À ajouter dans operators subscription
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger-product
  namespace: openshift-operators
spec:
  channel: stable
  name: jaeger-product
  source: redhat-operators
```

## 🚨 Leçon Apprise

Le Service Mesh nécessite Jaeger comme dépendance obligatoire. Notre GitOps doit inclure **toutes** les dépendances des opérateurs.
