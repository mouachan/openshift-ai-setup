# Model Registry Component

This component consolidates all Model Registry infrastructure following the RH AI Services BU repository pattern where **"une feature = un répertoire"** (one feature = one directory).

## Structure

This consolidated approach groups all related components in a single directory:

```
model-registry/
├── kustomization.yaml          # Main kustomization file
├── namespace.yaml              # Namespace definition
├── model-registry.yaml         # Model Registry CR
├── model-registry-db-parameters.yaml # Database configuration
├── model-registry-secret.yaml  # S3 credentials
├── mysql-deployment.yaml       # MySQL database
├── mysql-pvc.yaml             # MySQL persistent storage
├── mysql-secret.yaml          # MySQL credentials
├── mysql-service.yaml         # MySQL service
├── minio-deployment.yaml      # MinIO S3 storage
├── minio-pvc.yaml            # MinIO persistent storage
├── minio-secret.yaml         # MinIO credentials
├── minio-service.yaml        # MinIO service
├── minio-route.yaml          # MinIO web console route
├── minio-bucket-init.yaml    # MinIO bucket initialization
├── rolebinding.yaml          # RBAC permissions
├── dashboard-restart-rbac.yaml # ArgoCD hook RBAC
├── http-annotation-rbac.yaml   # ArgoCD hook RBAC
├── pre-sync-dashboard-restart.yaml  # ArgoCD PreSync hook
└── post-sync-http-annotation.yaml   # ArgoCD PostSync hook
```

## Components

### Core Model Registry
- **ModelRegistry CR**: Main Model Registry service configuration
- **Secrets**: Database and S3 credentials management
- **Configuration**: Database connection parameters

### MySQL Backend
- **Deployment**: MySQL 8.0 database server
- **PVC**: Persistent storage for database data
- **Service**: Internal cluster access to database
- **Secret**: Database authentication credentials

### MinIO S3 Storage
- **Deployment**: MinIO S3-compatible object storage
- **PVC**: Persistent storage for object data
- **Service**: Internal cluster access to S3 API
- **Route**: External access to MinIO web console
- **Job**: Bucket initialization and configuration

### RBAC & Security
- **RoleBinding**: Grants access to `system:authenticated` group
- **RBAC for ArgoCD Hooks**: Permissions for SSL correction automation

### ArgoCD SSL Correction Hooks
- **PreSync Hook**: Dashboard restart to force certificate reload
- **PostSync Hook**: HTTP annotation addition for service access

## Benefits of Consolidated Structure

1. **Single Source of Truth**: All Model Registry components in one location
2. **Simplified Maintenance**: Easy to understand and modify the complete feature
3. **Better GitOps**: Clear dependency management and atomic deployments
4. **Industry Best Practices**: Follows RH AI Services BU patterns
5. **Improved Organization**: Logical grouping reduces confusion

## Migration

This structure replaces the previous scattered approach:
- `components/instances/model-registry-config/` ❌
- `components/instances/mysql-model-registry/` ❌  
- `components/instances/minio-s3-storage/` ❌
- `components/instances/model-registry-namespace/` ❌

All functionality is now consolidated in:
- `components/instances/rhoai-instance/components/model-registry/` ✅

## Usage

This component is automatically included when deploying the RHOAI instance:

```yaml
# In components/instances/rhoai-instance/kustomization.yaml
resources:
  - base/
  - components/model-registry/
```

The consolidation maintains all existing functionality while improving maintainability and following industry best practices from the RH AI Services BU.
