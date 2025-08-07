# Architecture Modulaire OpenShift AI

## Vue d'ensemble

Cette architecture modulaire sépare les services de base (MinIO et MySQL) dans leurs propres namespaces, permettant leur réutilisation par d'autres applications.

## Architecture

### 1. Namespace `minio` - Service S3
- **MinIO** : Service de stockage d'objets S3-compatible
- **Buckets** : `model-registry-bucket`, `mlpipeline`
- **Service** : `minio-api.minio.svc.cluster.local:9000`
- **Credentials** : `minio` / `minio123`

### 2. Namespace `db-ai` - Base de données
- **MySQL 8.0** : Base de données relationnelle
- **Base** : `model_registry`
- **Service** : `mysql.db-ai.svc.cluster.local:3306`
- **Credentials** : `model_registry` / `password`

### 3. Namespace `rhoai-model-registries` - Model Registry
- **Configuration** : Utilise les services externes
- **Connectivité** : Vers MinIO et MySQL externes
- **Fonction** : Gestion des modèles ML

## Ordre de déploiement (Sync Waves)

1. **Wave 0** : Opérateurs (Service Mesh, Serverless, Pipelines, RHOAI)
2. **Wave 1** : Infrastructure de base (MinIO, MySQL)
3. **Wave 2** : Composants OpenShift (Serverless, Pipelines)
4. **Wave 3** : RHOAI et Model Registry
5. **Wave 4** : Démo Triton

## Avantages

### Réutilisabilité
- MinIO peut être utilisé par d'autres applications
- MySQL peut héberger d'autres bases de données
- Services isolés et indépendants

### Maintenance
- Mise à jour des services indépendamment
- Isolation des problèmes
- Scaling indépendant

### Sécurité
- Namespaces séparés
- Permissions granulaires
- Isolation réseau

## Configuration

### MinIO
```yaml
# Service
minio-api.minio.svc.cluster.local:9000

# Buckets
- model-registry-bucket
- mlpipeline

# Credentials
accessKey: minio
secretKey: minio123
```

### MySQL
```yaml
# Service
mysql.db-ai.svc.cluster.local:3306

# Base de données
database: model_registry
user: model_registry
password: password
```

### Model Registry
```yaml
# Configuration externe
DB_HOST: mysql.db-ai.svc.cluster.local
S3_ENDPOINT: minio-api.minio.svc.cluster.local:9000
```

## Tests

Utilisez le script de test pour vérifier l'architecture :

```bash
./scripts/test-modular-architecture.sh
```

## Migration

Cette architecture remplace l'ancienne configuration où :
- MySQL était dans `redhat-ods-applications`
- MinIO était dans `rhoai-model-registries`
- Tous les services étaient couplés

## Utilisation par d'autres applications

### Ajouter MinIO à une nouvelle application
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-s3-connection
type: Opaque
data:
  AWS_ACCESS_KEY_ID: bWluaW8=
  AWS_SECRET_ACCESS_KEY: bWluaW8xMjM=
  AWS_S3_ENDPOINT: bWluaW8tYXBpLm1pbmlvLnN2Yy5jbHVzdGVyLmxvY2FsOjkwMDA=
```

### Ajouter MySQL à une nouvelle application
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-db-connection
type: Opaque
data:
  DB_HOST: bXlzcWwuZGItYWkuc3ZjLmNsdXN0ZXIubG9jYWw=
  DB_PORT: MzMwNg==
  DB_USER: bW9kZWxfcmVnaXN0cnk=
  DB_PASSWORD: cGFzc3dvcmQ=
``` 