# Model Registry Consolidation Migration

## Migration Overview

This migration consolidates all Model Registry components following the RH AI Services BU pattern of **"une feature = un répertoire"** (one feature = one directory).

## Before (Scattered Structure) ❌

```
components/instances/
├── model-registry-config/base/           # Model Registry service
├── mysql-model-registry/base/           # MySQL database
├── minio-s3-storage/base/               # MinIO S3 storage  
└── model-registry-namespace/base/       # Namespace
```

## After (Consolidated Structure) ✅

```
components/instances/rhoai-instance/components/
└── model-registry/                      # Single consolidated directory
    ├── kustomization.yaml              # Main kustomization
    ├── namespace.yaml                  # Namespace
    ├── model-registry.yaml             # Model Registry CR
    ├── model-registry-db-parameters.yaml # Database config
    ├── model-registry-secret.yaml      # S3 credentials
    ├── mysql-deployment.yaml           # MySQL database
    ├── mysql-pvc.yaml                 # MySQL storage
    ├── mysql-secret.yaml              # MySQL credentials
    ├── mysql-service.yaml             # MySQL service
    ├── minio-deployment.yaml          # MinIO S3 storage
    ├── minio-pvc.yaml                 # MinIO storage
    ├── minio-secret.yaml              # MinIO credentials
    ├── minio-service.yaml             # MinIO service
    ├── minio-route.yaml               # MinIO console
    ├── minio-bucket-init.yaml         # MinIO initialization
    ├── rolebinding.yaml               # RBAC permissions
    ├── dashboard-restart-rbac.yaml     # ArgoCD hook RBAC
    ├── http-annotation-rbac.yaml       # ArgoCD hook RBAC
    ├── pre-sync-dashboard-restart.yaml # ArgoCD PreSync hook
    └── post-sync-http-annotation.yaml  # ArgoCD PostSync hook
```

## Benefits

1. **Single Source of Truth**: All Model Registry components in one place
2. **Simplified Maintenance**: Easier to understand and modify the complete feature
3. **Better GitOps**: Clear dependency management and atomic deployments
4. **Industry Best Practices**: Follows RH AI Services BU patterns
5. **Improved Organization**: Logical grouping reduces confusion

## Changes Made

### Cluster Configuration
- Updated `clusters/overlays/openshift-ai-dev/kustomization.yaml` to remove scattered references
- Consolidated all Model Registry components into `rhoai-instance`

### ArgoCD Application
- No changes required to `argocd-apps/openshift-ai-application.yaml` 
- Application already pointed to cluster overlay which now uses consolidated structure

### Component Structure
- All Model Registry components now live in `components/instances/rhoai-instance/components/model-registry/`
- Maintained all existing functionality and SSL fixes
- Preserved ArgoCD hooks for dashboard restart and HTTP annotation

## Validation

The consolidated structure has been tested and validated:

```bash
cd /Users/mouchan/projects/openshift-ai-setup
kustomize build components/instances/rhoai-instance/components/model-registry
kustomize build clusters/overlays/openshift-ai-dev
```

All builds successfully with no errors.

## Migration Complete

✅ **Model Registry consolidation complete**
✅ **All functionality preserved**  
✅ **SSL fixes maintained**
✅ **ArgoCD hooks working**
✅ **GitOps deployment ready**

The structure now follows RH AI Services BU best practices while maintaining full compatibility with the existing deployment.
