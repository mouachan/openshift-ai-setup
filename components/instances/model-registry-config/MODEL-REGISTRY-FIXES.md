# Model Registry Configuration Fixes

## Problèmes résolus

### 1. Erreur SSL "packet length too long"
**Problème** : Le dashboard OpenShift AI tentait de faire des connexions HTTPS vers le service Model Registry qui ne supporte que HTTP.

**Solution** : Ajout de l'annotation `routing.opendatahub.io/external-address-rest` sur le service pour forcer l'utilisation de HTTP.

**Fichier** : `service-annotation-patch.yaml`

### 2. Connectivité réseau (Connect Timeout Error)
**Problème** : Les namespaces `redhat-ods-applications` (dashboard) et `rhoai-model-registries` (model registry) n'étaient pas dans le même Service Mesh.

**Solution** : Ajout du namespace `redhat-ods-applications` au ServiceMeshMemberRoll.

**Fichier** : `components/instances/service-mesh-instance/base/member-roll.yaml`

### 3. Permissions RBAC
**Problème** : Accès limité au Model Registry pour certains utilisateurs et impossibilité de gérer les permissions.

**Solutions** :
- Ajout du groupe `system:authenticated` au RoleBinding pour permettre l'accès à tous les utilisateurs authentifiés
- Création d'un rôle `model-registry-admin` avec permissions RBAC complètes
- Attribution des permissions admin et utilisateur à l'utilisateur `mouachan`

**Fichiers** : 
- `rbac-access.yaml` - Accès pour tous les utilisateurs authentifiés
- `rbac-admin-role.yaml` - Rôle administrateur complet
- `rbac-mouachan-admin.yaml` - Permissions admin pour mouachan
- `rbac-mouachan-user.yaml` - Permissions utilisateur pour mouachan

## Configuration RBAC complète

### Rôles créés
1. **registry-user-default-model-registry** (automatique) - Accès lecture au Model Registry
2. **model-registry-admin** (custom) - Gestion complète des permissions RBAC

### RoleBindings créés
1. **model-registry-all-users** - Groupe `system:authenticated` → rôle utilisateur
2. **model-registry-mouachan-admin** - Utilisateur `mouachan` → rôle admin
3. **model-registry-mouachan-access** - Utilisateur `mouachan` → rôle utilisateur

## Configuration GitOps complète

### Job d'annotation HTTP automatique
- **ServiceAccount** : `model-registry-http-fix` avec permissions sur les services
- **Job** : `model-registry-http-annotation` applique automatiquement l'annotation HTTP
- **Exécution** : Se lance après déploiement du Model Registry et applique l'annotation
- **Résultat** : Annotation `routing.opendatahub.io/external-address-rest` persistée

### Fichiers GitOps ajoutés
- `http-annotation-rbac.yaml` - ServiceAccount et permissions pour annotation
- `http-annotation-job.yaml` - Job automatique d'application de l'annotation
- `model-registry.yaml` - Configuration avec `serviceRoute: disabled`

## Configuration Service Mesh requise

Le namespace `redhat-ods-applications` doit être membre du Service Mesh pour permettre la communication avec le Model Registry :

```yaml
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: istio-system
spec:
  members:
    - rhoai-model-registries
    - knative-serving
    - redhat-ods-applications  # Requis pour le dashboard
```

## Tests de validation

1. **Connectivité réseau** :
   ```bash
   oc exec -n redhat-ods-applications deployment/rhods-dashboard -- curl -s http://default-model-registry.rhoai-model-registries.svc.cluster.local:8080/api/model_registry/v1alpha3/registered_models
   ```

2. **Permissions RBAC utilisateur** :
   ```bash
   oc auth can-i get modelregistry --as=mouachan -n rhoai-model-registries
   ```

3. **Permissions RBAC admin** :
   ```bash
   oc auth can-i create rolebindings --as=mouachan -n rhoai-model-registries
   ```

4. **Service Mesh membership** :
   ```bash
   oc get namespace redhat-ods-applications -o jsonpath='{.metadata.labels.maistra\.io/member-of}'
   ```
