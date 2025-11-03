#!/bin/bash

# Script de recuperación automática para la aplicación
# Autor: Sistema de Monitoreo
# Descripción: Reinicia PostgreSQL y la aplicación cuando hay problemas

set -e

echo "======================================"
echo "🔄 INICIANDO RECUPERACIÓN DE LA APP"
echo "======================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Paso 1: Verificar conectividad del cluster
print_warning "Verificando conectividad con el cluster..."
if kubectl cluster-info &> /dev/null; then
    print_status "Cluster accesible"
else
    print_error "No se puede conectar al cluster"
    exit 1
fi

# Paso 2: Reiniciar PostgreSQL
print_warning "Reiniciando PostgreSQL para limpiar conexiones..."
kubectl delete pod postgresdb-postgresql-0 --force --grace-period=0 2>/dev/null || true

print_warning "Esperando a que PostgreSQL se reinicie (30 segundos)..."
sleep 30

# Verificar que PostgreSQL esté listo
print_warning "Verificando estado de PostgreSQL..."
for i in {1..12}; do
    if kubectl get pod postgresdb-postgresql-0 -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Running"; then
        READY=$(kubectl get pod postgresdb-postgresql-0 -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
        if [ "$READY" = "true" ]; then
            print_status "PostgreSQL está listo"
            break
        fi
    fi
    if [ $i -eq 12 ]; then
        print_error "PostgreSQL no se pudo levantar"
        exit 1
    fi
    echo "   Esperando... intento $i/12"
    sleep 5
done

# Paso 3: Eliminar todos los pods de la aplicación
print_warning "Eliminando pods corruptos de la aplicación..."
kubectl delete pods -l app=do-sample-app --force --grace-period=0 2>/dev/null || true

print_warning "Esperando a que se eliminen los pods (10 segundos)..."
sleep 10

# Paso 4: Verificar que los nuevos pods se estén creando
print_warning "Verificando que los nuevos pods se estén creando..."
sleep 5

EXPECTED_REPLICAS=$(kubectl get deployment do-sample-app -o jsonpath='{.spec.replicas}')
print_status "Esperando $EXPECTED_REPLICAS réplicas..."

# Esperar a que todos los pods estén Running
for i in {1..24}; do
    RUNNING_PODS=$(kubectl get pods -l app=do-sample-app --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    
    if [ "$RUNNING_PODS" -ge "$EXPECTED_REPLICAS" ]; then
        print_status "Todos los pods están corriendo ($RUNNING_PODS/$EXPECTED_REPLICAS)"
        break
    fi
    
    if [ $i -eq 24 ]; then
        print_error "Los pods no se levantaron correctamente"
        kubectl get pods -l app=do-sample-app
        exit 1
    fi
    
    echo "   Pods corriendo: $RUNNING_PODS/$EXPECTED_REPLICAS - intento $i/24"
    sleep 5
done

# Paso 5: Esperar un poco más para que la app se estabilice
print_warning "Esperando a que la aplicación se estabilice (15 segundos)..."
sleep 15

# Paso 6: Verificar que la aplicación responda
print_warning "Verificando que la aplicación responda..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://45.55.116.144/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    print_status "Aplicación respondiendo correctamente (HTTP $HTTP_CODE)"
else
    print_warning "Aplicación respondió con HTTP $HTTP_CODE (puede necesitar más tiempo)"
    
    # Intentar una vez más después de esperar
    sleep 10
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://45.55.116.144/ 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_status "Aplicación respondiendo correctamente (HTTP $HTTP_CODE)"
    else
        print_warning "Aplicación aún no responde correctamente (HTTP $HTTP_CODE)"
        print_warning "Puede necesitar más tiempo para estabilizarse"
    fi
fi

# Paso 7: Mostrar estado final
echo ""
echo "======================================"
echo "📊 ESTADO FINAL"
echo "======================================"
echo ""

echo "Pods de la aplicación:"
kubectl get pods -l app=do-sample-app

echo ""
echo "PostgreSQL:"
kubectl get pods -l app.kubernetes.io/name=postgresql

echo ""
echo "HPA:"
kubectl get hpa do-sample-app-hpa 2>/dev/null || echo "HPA no encontrado"

echo ""
echo "======================================"
echo -e "${GREEN}✅ RECUPERACIÓN COMPLETADA${NC}"
echo "======================================"
echo ""
echo "La aplicación debería estar accesible en:"
echo "🌐 http://45.55.116.144/"
echo ""
echo "Para monitorear en tiempo real:"
echo "   kubectl get pods -l app=do-sample-app -w"
echo ""
