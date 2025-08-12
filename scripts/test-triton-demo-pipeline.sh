#!/bin/bash

# Script de test pour vérifier que le pipeline Triton Demo fonctionne
# Teste la connexion DSPA et la création de pipelines

set -e

echo "🧪 Test du pipeline Triton Demo"

# Vérifier que le namespace existe
echo "📋 Vérification du namespace..."
oc get namespace triton-demo

# Vérifier que DSPA est déployé
echo "🔍 Vérification de DSPA..."
oc get dspa -n triton-demo

# Vérifier que le workbench est en cours d'exécution
echo "📱 Vérification du workbench..."
oc get pods -n triton-demo -l app=triton-workbench

# Vérifier les services DSPA
echo "🔌 Vérification des services DSPA..."
oc get svc -n triton-demo | grep ds-pipeline

# Test de connexion au pipeline
echo "🔗 Test de connexion au pipeline..."
WORKBENCH_POD=$(oc get pod -n triton-demo -l app=triton-workbench -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "${WORKBENCH_POD}" ]; then
    echo "✅ Workbench trouvé: ${WORKBENCH_POD}"
    
    # Test de connexion KFP
    echo "🧪 Test de connexion KFP..."
    oc exec -n triton-demo "${WORKBENCH_POD}" -c triton-workbench -- python3 -c "
import urllib3
import ssl
urllib3.disable_warnings()
ssl._create_default_https_context = ssl._create_unverified_context

try:
    import kfp
    client = kfp.Client(host='https://ds-pipeline-dspa.triton-demo.svc:8443')
    print('✅ Connexion KFP réussie!')
    
    # Lister les expériences
    experiments = client.list_experiments()
    print(f'📊 Expériences trouvées: {len(experiments)}')
    
    # Tester la création d'une expérience
    experiment = client.create_experiment(name='test-triton-demo')
    print(f'✅ Expérience créée: {experiment.name}')
    
except Exception as e:
    print(f'❌ Erreur: {e}')
"
else
    echo "❌ Workbench non trouvé"
fi

# Vérifier les routes
echo "🛣️ Vérification des routes..."
oc get routes -n triton-demo

echo "🎉 Test terminé!"
