# 🚀 Déploiement GitOps OpenShift AI 2.22 avec ArgoCD

## Étapes de Déploiement

### 1. Push vers Git

```bash
# Depuis votre projet local
git add .
git commit -m "feat: Configuration complète OpenShift AI 2.22 GitOps"
git push origin main
```

### 2. Installer GitOps Operator (si pas déjà fait)

```bash
# Installer l'opérateur GitOps
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# Attendre que GitOps soit prêt
oc wait --for=condition=Ready pod -l name=openshift-gitops-operator -n openshift-operators --timeout=300s
```

### 3. Option A: Déploiement Application Unique

```bash
# Modifier l'URL Git dans le fichier
sed -i 's/VOTRE-USERNAME/votre-github-username/g' argocd/openshift-ai-application.yaml

# Déployer
oc apply -f argocd/openshift-ai-application.yaml
```

### 4. Option B: App of Apps (Recommandé)

```bash
# Modifier l'URL Git
sed -i 's/VOTRE-USERNAME/votre-github-username/g' argocd/app-of-apps.yaml
sed -i 's/VOTRE-USERNAME/votre-github-username/g' argocd/apps/applications.yaml

# Déployer
oc apply -f argocd/app-of-apps.yaml
```

### 5. Monitoring du Déploiement

```bash
# Voir les applications ArgoCD
oc get applications -n openshift-gitops

# Interface ArgoCD
oc get route argocd-server -n openshift-gitops

# Mot de passe admin ArgoCD
oc get secret argocd-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d
```

### 6. Vérification OpenShift AI

```bash
# Vérifier les opérateurs
oc get subscription -A | grep -E "(servicemesh|serverless|pipelines|rhods)"

# Vérifier Service Mesh
oc get servicemeshcontrolplane -n istio-system

# Vérifier Serverless
oc get knativeserving -n knative-serving

# Vérifier OpenShift AI
oc get datasciencecluster,dscinitialization -A

# Dashboard RHOAI
oc get route rhods-dashboard -n redhat-ods-applications
```

## 🎯 Avantages GitOps

- ✅ **Automatisation Complète** - Push Git → Déploiement automatique
- ✅ **Synchronisation Continue** - Détection des drifts et auto-correction
- ✅ **Rollback Facile** - Retour à l'état précédent via Git
- ✅ **Auditabilité** - Historique complet dans Git
- ✅ **Multi-Environnements** - dev/staging/prod avec branches
- ✅ **Sécurité** - Pas d'accès direct cluster nécessaire

## 🔧 Personnalisation

Pour modifier la configuration:
1. Éditer les fichiers dans `components/`
2. Commit et push vers Git  
3. ArgoCD synchronise automatiquement

## 🚨 Troubleshooting

```bash
# Logs ArgoCD
oc logs -f deployment/argocd-application-controller -n openshift-gitops

# Forcer la sync
oc patch application openshift-ai-dev -n openshift-gitops --type merge -p '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'

# Status détaillé
oc describe application openshift-ai-dev -n openshift-gitops
```
