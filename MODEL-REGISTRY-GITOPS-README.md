# Model Registry - Déploiement GitOps Automatique

## 🎯 Vue d'ensemble

Ce dossier contient la configuration GitOps complète pour déployer automatiquement le Model Registry OpenShift AI 2.22 avec ses dépendances.

## 📦 Composants déployés automatiquement

### 1. Infrastructure de base de données
- **MySQL 8.0** avec authentification corrigée
- **PVC 10Gi** pour stockage persistant
- **Job d'initialisation** pour configuration automatique de l'authentification

### 2. Stockage S3
- **MinIO** pour stockage des artefacts de modèles
- **PVC 20Gi** pour stockage persistant
- **Job d'initialisation** pour création automatique du bucket
- **Route** pour accès à la console MinIO

### 3. Model Registry
- **Model Registry** managé automatiquement par OpenShift AI
- **API REST et GRPC** avec routes exposées
- **Intégration Service Mesh** automatique

## 🚀 Déploiement automatique

### Commande unique pour tout déployer :
```bash
oc apply -k clusters/overlays/openshift-ai-dev
```

### Ordonnancement automatique :
1. **Namespaces** créés en premier
2. **MySQL** déployé avec configuration automatique
3. **MinIO** déployé avec bucket initialisé
4. **Model Registry** activé dans DataScienceCluster
5. **Service Mesh** configuré automatiquement

## 🔧 Configuration automatique

### Authentification MySQL
- Le Job `mysql-auth-fix` corrige automatiquement l'authentification MySQL 8.0
- Configuration de `mysql_native_password` pour compatibilité avec MLMD
- Aucune intervention manuelle requise

### Stockage S3
- Le Job `minio-bucket-init` crée automatiquement le bucket `model-registry`
- Configuration des permissions automatique
- Console MinIO accessible via route

### Intégration Service Mesh
- ServiceMeshMember configuré automatiquement
- Gestion des conflits résolue automatiquement
- Aucune intervention manuelle requise

## 📋 Vérification du déploiement

### Commandes de vérification :
```bash
# Statut général
oc get all -n rhoai-model-registries

# Statut Model Registry
oc get modelregistry -A

# Logs de déploiement
oc get pods -n rhoai-model-registries
oc logs -l app=mysql-init -n rhoai-model-registries
oc logs -l app=minio-init -n rhoai-model-registries
```

### URLs d'accès automatiques :
- **Model Registry API :** `oc get route -n rhoai-model-registries | grep model-registry`
- **MinIO Console :** `oc get route -n rhoai-model-registries | grep minio-console`

## 🔐 Credentials

### MySQL :
- **Root :** `mysql123`
- **User :** `registry` / `registry123`
- **Database :** `model_registry`

### MinIO :
- **Access Key :** `minioadmin`
- **Secret Key :** `minioadmin123`
- **Bucket :** `model-registry`

## 🎯 Résultat attendu

Après déploiement, dans l'interface OpenShift AI :
- Model Registry visible avec statut "Ready"
- API accessible pour enregistrement de modèles
- Stockage S3 fonctionnel pour artefacts
- Base de données MySQL opérationnelle

## 🔄 Redéploiement

Le déploiement est **idempotent** :
```bash
# Suppression complète (optionnel)
oc delete namespace rhoai-model-registries

# Redéploiement automatique
oc apply -k clusters/overlays/openshift-ai-dev
```

Tout se reconfigure automatiquement sans intervention manuelle !

## 📊 Structure GitOps

```
components/instances/
├── model-registry-namespace/base/     # Namespace
├── mysql-model-registry/base/         # Base de données MySQL
├── minio-s3-storage/base/            # Stockage S3 MinIO
└── rhoai-instance/                   # DataScienceCluster avec Model Registry

clusters/overlays/openshift-ai-dev/    # Configuration complète
```

✅ **Aucune intervention manuelle requise après configuration initiale !**
