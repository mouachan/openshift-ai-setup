# Custom Serving Runtimes Component

Ce composant ajoute des runtimes de service custom à OpenShift AI 2.22 suivant la documentation officielle Red Hat et le pattern BU "une feature = un répertoire".

## Runtimes Inclus

### 🚀 NVIDIA Triton Inference Server
**Source**: Chapitre 2.11.23 de la documentation OpenShift AI 2.22

**Frameworks supportés**:
- TensorFlow (v1 & v2)
- PyTorch (v1)
- ONNX (v1)
- TensorRT (v8)
- Python backend pour modèles custom

**Caractéristiques**:
- Multi-model serving
- Support GPU et CPU
- Metrics Prometheus intégrées
- Optimisé pour l'inférence haute performance
- Backend Python pour modèles personnalisés

**Configuration**:
```yaml
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  name: triton-runtime
spec:
  supportedModelFormats:
  - name: tensorflow
  - name: pytorch
  - name: onnx
  - name: tensorrt
  - name: python
```

### 🧠 Seldon MLServer
**Source**: Chapitre 2.11.3 de la documentation OpenShift AI 2.22

**Frameworks supportés**:
- Scikit-learn (v1)
- XGBoost (v1)
- LightGBM (v3)
- MLflow (v1)
- Hugging Face (v1)
- Tempo custom models (v1)

**Caractéristiques**:
- Multi-model serving
- Support Python ML ecosystem
- Metrics Prometheus intégrées
- Optimisé pour modèles Python
- Interface V2 protocol compatible

**Configuration**:
```yaml
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  name: seldon-mlserver-runtime
spec:
  supportedModelFormats:
  - name: sklearn
  - name: xgboost
  - name: lightgbm
  - name: mlflow
  - name: huggingface
```

## Structure du Composant

```
custom-serving-runtimes/
├── kustomization.yaml           # Configuration Kustomize
├── triton-runtime.yaml          # NVIDIA Triton runtime
├── seldon-mlserver-runtime.yaml # Seldon MLServer runtime
└── README.md                    # Cette documentation
```

## Déploiement GitOps

Ces runtimes sont automatiquement déployés avec l'instance RHOAI via GitOps :

```yaml
# Dans components/instances/rhoai-instance/kustomization.yaml
components:
  - components/model-registry/
  - components/custom-serving-runtimes/  # ✨ Nouveau composant
```

## Utilisation

Une fois déployés, ces runtimes apparaissent dans l'interface OpenShift AI :

1. **Model Serving** → **Deploy model**
2. Sélectionner le runtime approprié :
   - **Triton** pour TensorFlow, PyTorch, ONNX, TensorRT
   - **Seldon MLServer** pour scikit-learn, XGBoost, MLflow

## Monitoring et Observabilité

Les deux runtimes exposent des métriques Prometheus :
- **Triton** : port 8002, path `/metrics`
- **Seldon** : port 8080, path `/metrics`

## Sécurité et Resources

### Limits par défaut
- **CPU** : 2 cores max, 500m requests
- **Mémoire** : 4Gi max, 1Gi requests

### Health Checks
- **Liveness** : `/v2/health/live` (30s initial, 30s period)
- **Readiness** : `/v2/health/ready` (10s initial, 10s period)

## Troubleshooting

### Vérifier les runtimes
```bash
oc get servingruntime -n redhat-ods-applications
```

### Logs des runtimes
```bash
# Pour un InferenceService utilisant Triton
oc logs -n <namespace> deployment/<inference-service>-predictor -c triton

# Pour un InferenceService utilisant Seldon
oc logs -n <namespace> deployment/<inference-service>-predictor -c mlserver
```

### Status des runtimes
```bash
oc describe servingruntime triton-runtime -n redhat-ods-applications
oc describe servingruntime seldon-mlserver-runtime -n redhat-ods-applications
```

## Compatibilité

- **OpenShift AI** : 2.22+
- **KServe** : API v1alpha1
- **OpenShift** : 4.14+
- **Service Mesh** : Compatible Istio

## Références

- [Documentation OpenShift AI 2.22 - Chapitre 2.11.23 Triton](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.22/html/serving_models/)
- [Documentation OpenShift AI 2.22 - Chapitre 2.11.3 Seldon](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.22/html/serving_models/)
- [NVIDIA Triton Inference Server](https://github.com/triton-inference-server/server)
- [Seldon MLServer](https://mlserver.readthedocs.io/)
