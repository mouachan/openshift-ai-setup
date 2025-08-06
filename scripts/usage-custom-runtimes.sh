#!/bin/bash
# Guide d'utilisation des Custom Serving Runtimes
# Après déploiement des templates Triton et Seldon

echo "🎯 Custom Serving Runtimes - Guide d'Utilisation"
echo "================================================"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}📋 Runtimes Déployés${NC}"
echo "======================"

# Vérifier les templates
TRITON_TEMPLATE=$(oc get template triton-runtime-template -n redhat-ods-applications --no-headers 2>/dev/null | awk '{print $1}')
SELDON_TEMPLATE=$(oc get template seldon-mlserver-runtime-template -n redhat-ods-applications --no-headers 2>/dev/null | awk '{print $1}')

if [ ! -z "$TRITON_TEMPLATE" ]; then
    echo -e "${GREEN}✅ NVIDIA Triton Inference Server${NC}"
    echo "   - Formats: TensorFlow, PyTorch, ONNX, TensorRT, Python"
    echo "   - Template: $TRITON_TEMPLATE"
    echo ""
fi

if [ ! -z "$SELDON_TEMPLATE" ]; then
    echo -e "${GREEN}✅ Seldon MLServer${NC}"  
    echo "   - Formats: scikit-learn, XGBoost, LightGBM, MLflow, Hugging Face"
    echo "   - Template: $SELDON_TEMPLATE"
    echo ""
fi

# Vérifier les serving runtimes
echo -e "${BLUE}🚀 Serving Runtimes Actifs${NC}"
echo "==========================="
oc get servingruntimes -n redhat-ods-applications --no-headers 2>/dev/null | while read line; do
    name=$(echo $line | awk '{print $1}')
    modeltype=$(echo $line | awk '{print $3}')
    echo -e "${GREEN}✅${NC} $name (type: $modeltype)"
done

echo ""
echo -e "${BLUE}🌐 Accès Interface OpenShift AI${NC}"
echo "==============================="
DASHBOARD_URL=$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null)
if [ ! -z "$DASHBOARD_URL" ]; then
    echo -e "🔗 Dashboard: ${YELLOW}https://$DASHBOARD_URL${NC}"
    echo ""
    echo "📍 Pour voir les custom runtimes :"
    echo "   1. Connectez-vous au dashboard OpenShift AI"
    echo "   2. Allez dans Settings → Serving Runtimes"
    echo "   3. Vous devriez voir :"
    echo "      • Triton Runtime 23.10"
    echo "      • Seldon MLServer Runtime" 
    echo ""
    echo "📍 Pour utiliser les runtimes :"
    echo "   1. Créez un Data Science Project"
    echo "   2. Configure Server → Choisissez le runtime approprié"
    echo "   3. Deploy Model → Sélectionnez le format de modèle"
    echo ""
else
    echo -e "${YELLOW}⚠️  Dashboard OpenShift AI non trouvé${NC}"
fi

echo -e "${BLUE}🔧 Validation${NC}"
echo "=============="
echo "Pour valider le déploiement :"
echo "   ./scripts/test-custom-runtimes.sh"
echo ""

echo -e "${BLUE}📚 Documentation${NC}"  
echo "================="
echo "• Triton: Chapitre 2.11.23 OpenShift AI 2.22"
echo "• Seldon: Chapitre 2.11.3 OpenShift AI 2.22"
echo "• Référence: https://ai-on-openshift.io/odh-rhoai/custom-runtime-triton/"
echo ""

echo -e "${GREEN}🎉 Installation Terminée !${NC}"
echo "Les custom serving runtimes sont maintenant disponibles dans l'interface OpenShift AI."
