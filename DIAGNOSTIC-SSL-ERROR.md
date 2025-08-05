# 🔍 Diagnostic OpenShift AI - Erreur SSL Model Registry

## 📊 État Actuel ($(date))

### ✅ Composants Opérationnels
- **Model Registry**: ✅ Ready (default-modelregistry)
- **Model Catalog**: ✅ Enabled (disableModelCatalog: false)
- **Dashboard Pods**: ✅ Running (redémarrés)
- **Infrastructure**: ✅ MySQL + MinIO opérationnels

### ⚠️ Problèmes Identifiés
- **DataScienceCluster**: ❌ NotReady
- **ArgoCD**: OutOfSync (désactivé temporairement)
- **Interface**: Erreur SSL "Error loading components"

## 🔧 Actions de Récupération Appliquées

1. **Désactivation ArgoCD auto-sync**
   ```bash
   oc patch application.argoproj.io openshift-ai-complete -n openshift-gitops --type='merge' -p='{"spec":{"syncPolicy":{"automated":null}}}'
   ```

2. **Redémarrage Dashboard**
   ```bash
   oc rollout restart deployment rhods-dashboard -n redhat-ods-applications
   ```

## 🎯 Solutions Recommandées

### Option 1: Redémarrage complet DataScienceCluster
```bash
# Redémarrer le DSC pour forcer la resynchronisation
oc patch datasciencecluster default-dsc -n redhat-ods-applications --type='merge' -p='{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt":"'$(date +%Y-%m-%dT%H:%M:%S%z)'"}}}'
```

### Option 2: Vérification réseau/SSL
```bash
# Vérifier les certificats et connectivité
oc get pods -n redhat-ods-applications -o wide
oc describe service rhods-dashboard -n redhat-ods-applications
```

### Option 3: Reset Model Registry Config
```bash
# Si le problème persiste, désactiver/réactiver Model Registry
oc patch datasciencecluster default-dsc -n redhat-ods-applications --type='merge' -p='{"spec":{"components":{"modelregistry":{"managementState":"Removed"}}}}'
sleep 30
oc patch datasciencecluster default-dsc -n redhat-ods-applications --type='merge' -p='{"spec":{"components":{"modelregistry":{"managementState":"Managed","registriesNamespace":"rhoai-model-registries"}}}}'
```

## 📋 Vérifications Post-Récupération

```bash
# 1. Vérifier DSC
oc get datasciencecluster -A

# 2. Vérifier Model Registry
oc get modelregistry -A

# 3. Vérifier dashboard
oc get pods -n redhat-ods-applications | grep dashboard

# 4. Tester l'interface OpenShift AI
# Accéder via Console OpenShift → Application Launcher → Red Hat OpenShift AI
```

## 🚨 Si le problème persiste

L'erreur SSL "packet length too long" peut indiquer:
- Conflit de ports (HTTP vs HTTPS)
- Problème de proxy/ingress
- Configuration réseau corrompue
- Cache navigateur

**Solution radicale**: Redéploiement complet via GitOps après stabilisation.
