# 🚀 Kubernetes Autoscaling Demo - Información de Acceso

## ✅ Estado del Despliegue

Todo está correctamente desplegado y funcionando:

### 📊 Componentes Activos

| Componente | Estado | Pods |
|------------|--------|------|
| Aplicación (do-sample-app) | ✅ Running | 3/3 |
| PostgreSQL | ✅ Running | 1/1 |
| Prometheus Stack | ✅ Running | 8/8 |
| Locust Master | ✅ Running | 1/1 |
| Locust Workers | ✅ Running | 2/2 |
| Metrics Server | ✅ Running | 1/1 |
| HPA | ✅ Active | Min:2 Max:10 |

---

## 🌐 URLs de Acceso

### 1. Aplicación Principal
- **URL Pública**: http://45.55.116.144
- **Estado**: ✅ Funcionando correctamente

### 2. Locust (Pruebas de Carga)
- **URL Web UI**: http://138.197.240.205:8089
- **Usuario**: No requiere autenticación
- **Target Host**: http://do-sample-app-service:8080
- **Estado**: ✅ Listo para generar carga

### 3. Grafana (Monitoreo)
- **URL Local**: http://localhost:3000 (requiere port-forward)
- **Usuario**: `admin`
- **Contraseña**: `prom-operator`
- **Comando para acceder**:
  ```bash
  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
  ```

### 4. Prometheus (Métricas)
- **URL Local**: http://localhost:9090 (requiere port-forward)
- **Comando para acceder**:
  ```bash
  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
  ```

---

## 🎯 Cómo Ejecutar las Pruebas de Autoscaling

### Opción 1: Usando Ansible (Recomendado)

```bash
cd ansible

# 1. Ver el estado actual
kubectl get hpa
kubectl get pods -l app=do-sample-app

# 2. Ejecutar prueba de carga con monitoreo automático
ansible-playbook run-load-test.yml
```

### Opción 2: Manual con Locust UI

1. **Abrir Locust**: http://138.197.240.205:8089

2. **Configurar la prueba**:
   - Host: `h`
   - Number of users: `100`
   - Spawn rate: `10` usuarios/segundo
   - Run time: `600` segundos (10 minutos)

3. **Iniciar la prueba**: Click en "Start swarming"

4. **Monitorear en tiempo real**:
   ```bash
   # Terminal 1: Monitorear HPA
   kubectl get hpa do-sample-app-hpa -w
   
   # Terminal 2: Monitorear Pods
   kubectl get pods -l app=do-sample-app -w
   
   # Terminal 3: Ver métricas
   kubectl top pods -l app=do-sample-app
   ```

5. **Abrir Grafana** para visualización gráfica:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
   # Ir a http://localhost:3000
   # Login: admin / prom-operator
   ```

---

## 📈 Qué Obttp://do-sample-app-service:8080servar Durante las Pruebas

### En Locust (http://138.197.240.205:8089)
- ✅ RPS (Requests per Second) incrementando
- ✅ Response times manteniéndose bajos
- ✅ Tasa de fallos cercana a 0%

### En kubectl (Terminal)
```bash
# Verás algo como esto:
NAME                REFERENCE                  TARGETS                  MINPODS   MAXPODS   REPLICAS
do-sample-app-hpa   Deployment/do-sample-app   cpu: 5%/50%             2         10        2

# Después de 1-2 minutos de carga:
do-sample-app-hpa   Deployment/do-sample-app   cpu: 65%/50%            2         10        4

# En el pico:
do-sample-app-hpa   Deployment/do-sample-app   cpu: 55%/50%            2         10        7

# Pods escalando:
kubectl get pods -l app=do-sample-app
# Verás nuevos pods creándose: ContainerCreating -> Running
```

### En Grafana (http://localhost:3000)

**Dashboards recomendados**:
1. **Kubernetes / Compute Resources / Namespace (Pods)**
   - Filtrar por namespace: `default`
   - Ver CPU y memoria de todos los pods

2. **Kubernetes / Compute Resources / Pod**
   - Seleccionar pods: `do-sample-app-*`
   - Ver métricas individuales

3. **Crear Dashboard personalizado**:
   - Panel 1: Número de réplicas del deployment
   - Panel 2: CPU usage por pod
   - Panel 3: Memory usage por pod
   - Panel 4: Request rate

---

## 🧪 Escenarios de Prueba Sugeridos

### Prueba 1: Scaling Progresivo (Recomendada para primera vez)
```
Usuarios: 50
Spawn Rate: 5/seg
Duración: 5 minutos
Resultado esperado: 3-5 pods
```

### Prueba 2: Scaling Agresivo
```
Usuarios: 100
Spawn Rate: 10/seg
Duración: 10 minutos
Resultado esperado: 6-8 pods
```

### Prueba 3: Máximo Stress
```
Usuarios: 200
Spawn Rate: 20/seg
Duración: 10 minutos
Resultado esperado: 9-10 pods (límite máximo)
```

### Prueba 4: Scale Down
```
1. Ejecutar prueba intensa (100-200 usuarios)
2. Detener la prueba en Locust
3. Observar cómo los pods se reducen gradualmente
4. Tiempo esperado: 5-10 minutos para volver a 2 pods
```

---

## 📊 Configuración del HPA

El HPA está configurado para:

```yaml
Mínimo de réplicas: 2
Máximo de réplicas: 10

Métricas de trigger:
- CPU: 50% de utilización promedio
- Memory: 70% de utilización promedio

Comportamiento de scaling:
Scale Up:
  - Duplica pods cada 15 segundos si es necesario
  - Máximo 4 pods por vez
  
Scale Down:
  - Espera 5 minutos de estabilidad
  - Reduce 50% de pods cada vez
  - Comportamiento conservador
```

---

## 🔍 Comandos Útiles

```bash
# Ver estado general
kubectl get all -n default
kubectl get all -n monitoring

# HPA
kubectl get hpa
kubectl describe hpa do-sample-app-hpa

# Pods y recursos
kubectl get pods -l app=do-sample-app
kubectl top pods -l app=do-sample-app
kubectl top nodes

# Logs
kubectl logs -f deployment/do-sample-app
kubectl logs -f -l app=locust-master

# Eventos de scaling
kubectl get events --sort-by='.lastTimestamp' | grep -i scale

# Métricas del Metrics Server
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods
```

---

## 🎬 Workflow Completo de Demostración

1. **Preparación** (2 minutos):
   ```bash
   # Abrir 3 terminales
   # Terminal 1:
   kubectl get hpa -w
   
   # Terminal 2:
   kubectl get pods -l app=do-sample-app -w
   
   # Terminal 3:
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
   ```

2. **Abrir Dashboards** (1 minuto):
   - Locust: http://138.197.240.205:8089
   - Grafana: http://localhost:3000
   - Aplicación: http://45.55.116.144

3. **Estado Inicial** (1 minuto):
   - Mostrar HPA con CPU/Memory bajo
   - Mostrar 2-3 pods activos
   - Mostrar gráficas en Grafana en estado normal

4. **Iniciar Carga** (30 segundos):
   - En Locust: 100 users, 10 spawn rate
   - Click "Start swarming"

5. **Observar Scaling Up** (3-5 minutos):
   - Ver CPU subiendo en HPA
   - Ver nuevos pods creándose
   - Ver métricas en Grafana incrementando
   - Ver RPS en Locust aumentando

6. **Pico de Carga** (2-3 minutos):
   - Observar estabilización en 6-8 pods
   - CPU mantenido alrededor del 50%
   - Response times estables

7. **Detener Carga** (30 segundos):
   - Click "Stop" en Locust

8. **Observar Scale Down** (5-10 minutos):
   - Ver CPU bajando gradualmente
   - Ver pods terminándose uno por uno
   - Vuelta a 2 pods mínimos

---

## 🧹 Limpieza

Cuando termines las pruebas:

```bash
# Opción 1: Con Ansible
cd ansible
ansible-playbook cleanup.yml

# Opción 2: Manual
kubectl delete -f ../manifests/locust.yaml
kubectl delete -f ../manifests/hpa.yaml
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

**Nota**: La aplicación principal permanece activa.

---

## 💡 Tips para una Buena Demostración

1. **Primero sin carga**: Muestra el estado normal (2-3 pods, CPU bajo)

2. **Explica el HPA**: Muestra la configuración antes de empezar

3. **Carga gradual**: Empieza con 50 usuarios, luego sube a 100-200

4. **Múltiples pantallas**: Locust + Grafana + Terminal es impactante

5. **Explica las métricas**: CPU%, número de réplicas, response time

6. **Muestra el scale down**: Demuestra que también escala hacia abajo

7. **Compara con/sin autoscaling**: Explica qué pasaría sin HPA

---

## 📞 Troubleshooting

### HPA muestra `<unknown>`
```bash
# Esperar 1-2 minutos para métricas
kubectl get deployment metrics-server -n kube-system
kubectl logs -n kube-system deployment/metrics-server
```

### Pods no escalan
```bash
kubectl describe hpa do-sample-app-hpa
# Verificar que resources estén configurados
kubectl describe deployment do-sample-app | grep -A 5 "Limits:"
```

### Locust no conecta
```bash
kubectl logs -l app=locust-master
# Verificar que el servicio de la app esté correcto
kubectl get svc do-sample-app-service
```

---

## 🎉 ¡Todo Listo!

Tu entorno de autoscaling está completamente configurado y listo para demostraciones.

**Próximos pasos recomendados**:
- ✅ Familiarízate con los dashboards de Grafana
- ✅ Prueba diferentes escenarios de carga
- ✅ Documenta los resultados y tiempos de scaling
- ✅ Considera implementar VPA (Vertical Pod Autoscaler)
- ✅ Configura alertas en Prometheus

**Documentación completa**: Ver `ansible/README.md`
