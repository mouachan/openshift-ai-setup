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
**Problème** : Accès limité au Model Registry pour certains utilisateurs.

**Solution** : Ajout du groupe `system:authenticated` au RoleBinding pour permettre l'accès à tous les utilisateurs authentifiés.

**Fichier** : `rbac-access.yaml`

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

2. **Permissions RBAC** :
   ```bash
   oc auth can-i get modelregistry --as=system:serviceaccount:default:default -n rhoai-model-registries
   ```

3. **Service Mesh membership** :
   ```bash
   oc get namespace redhat-ods-applications -o jsonpath='{.metadata.labels.maistra\.io/member-of}'
   ```
