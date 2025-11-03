# 📊 DORA Four Key Metrics Dashboard

## 🎯 Implementación del Capítulo 1: "What Is Infrastructure as Code?"

**Ubicación en el libro**: Capítulo 1, sección "The Four Key Metrics" (página 9)

**Filosofía del capítulo**: "Making changes frequently and reliably is correlated to organizational success"

---

## 🔑 Las Cuatro Métricas Clave de DORA

### 1️⃣ **Deployment Lead Time** (Tiempo de Implementación)
**Qué mide**: Tiempo desde que se comienza un cambio hasta que se despliega en producción.

**En nuestro dashboard**: Medimos el tiempo promedio desde que se crea un pod hasta ahora.

**Interpretación**:
- ✅ **Elite**: < 1 hora (3600s)
- 🟡 **High**: < 1 día (86400s)
- 🟠 **Medium**: < 1 semana
- 🔴 **Low**: > 1 mes

**Query Prometheus**:
```promql
avg(time() - kube_pod_created{namespace="default", pod=~"do-sample-app.*"})
```

**Por qué es importante**: Ciclos cortos permiten iterar rápidamente, responder a bugs y entregar valor al negocio más frecuentemente.

---

### 2️⃣ **Deployment Frequency** (Frecuencia de Despliegues)
**Qué mide**: Con qué frecuencia se despliegan cambios a producción.

**En nuestro dashboard**: Rastreamos cambios en pods (restarts) y el número de pods activos en el tiempo.

**Interpretación**:
- ✅ **Elite**: On-demand (múltiples por día)
- 🟡 **High**: Entre 1 vez por día y 1 vez por semana
- 🟠 **Medium**: Entre 1 vez por semana y 1 vez por mes
- 🔴 **Low**: < 1 vez por mes

**Query Prometheus**:
```promql
# Tasa de cambios (restarts) en ventana de 5 minutos
sum(rate(kube_pod_container_status_restarts_total{namespace="default", pod=~"do-sample-app.*"}[5m]))

# Número de pods activos
count(kube_pod_info{namespace="default", pod=~"do-sample-app.*"})
```

**Por qué es importante**: Despliegues frecuentes reducen el riesgo (cambios más pequeños) y permiten feedback rápido del usuario.

---

### 3️⃣ **Change Fail Percentage** (Porcentaje de Fallos en Cambios)
**Qué mide**: Porcentaje de cambios que resultan en degradación del servicio y requieren remediación.

**En nuestro dashboard**: Calculamos la tasa de restarts de pods como proxy para fallos.

**Interpretación**:
- ✅ **Elite**: 0-15%
- 🟡 **High**: 16-30%
- 🟠 **Medium**: 31-45%
- 🔴 **Low**: > 45%

**Query Prometheus**:
```promql
(sum(kube_pod_container_status_restarts_total{namespace="default", pod=~"do-sample-app.*"}) / 
 sum(kube_pod_status_phase{namespace="default", pod=~"do-sample-app.*", phase="Running"})) * 100
```

**Por qué es importante**: Baja tasa de fallos indica procesos de testing y validación robustos, permitiendo desplegar con confianza.

---

### 4️⃣ **Mean Time to Restore (MTTR)** (Tiempo Medio de Recuperación)
**Qué mide**: Cuánto tiempo tarda en restaurarse el servicio después de un incidente.

**En nuestro dashboard**: Medimos el tiempo promedio desde que un pod inicia (después de un fallo) hasta ahora.

**Interpretación**:
- ✅ **Elite**: < 1 hora (3600s)
- 🟡 **High**: < 1 día (86400s)
- 🟠 **Medium**: < 1 semana
- 🔴 **Low**: > 1 semana

**Query Prometheus**:
```promql
avg(time() - kube_pod_start_time{namespace="default", pod=~"do-sample-app.*"})
```

**Por qué es importante**: Recuperación rápida minimiza el impacto al negocio y reduce la presión sobre los equipos durante incidentes.

---

## 🚀 Acceso al Dashboard

### **Credenciales de Grafana**

```bash
URL: http://a49bace222f1147d5b6b9846609d8abe-1817189291.us-east-1.elb.amazonaws.com
Usuario: admin
Contraseña: f8ksEBbWFnPWbMYkgXgqcgzMRmdzp9O3XlJRFQtZ
```

### **Ubicación del Dashboard**

1. Accede a Grafana con las credenciales anteriores
2. En el menú lateral izquierdo, haz clic en **"Dashboards"** (ícono de 4 cuadrados)
3. Busca: **"DORA Four Key Metrics - Infrastructure as Code"**
4. O accede directamente: `http://<grafana-url>/d/dora-four-key-metrics`

---

## 📈 Interpretación del Dashboard

### **Panel 1: Deployment Lead Time (Gauge)**
- **Verde**: Pods jóvenes (< 1 hora) = Despliegues recientes y frecuentes ✅
- **Amarillo**: Pods de 1-24 horas = Ritmo moderado 🟡
- **Rojo**: Pods > 1 día = Falta de actualización 🔴

### **Panel 2: Deployment Frequency (Time Series)**
- **Línea plana (restarts=0)**: Sistema estable, sin despliegues
- **Picos frecuentes**: Despliegues activos o problemas que causan restarts
- **Línea de "Active Pods"**: Muestra el escalado del HPA

### **Panel 3: Change Fail Percentage (Gauge)**
- **Verde (< 15%)**: Tasa de fallos aceptable ✅
- **Amarillo (15-30%)**: Revisar procesos de testing 🟡
- **Rojo (> 30%)**: Problemas serios en calidad 🔴

### **Panel 4: MTTR (Gauge)**
- **Verde (< 5 min)**: Recuperación casi instantánea (HPA/K8s) ✅
- **Amarillo (5-60 min)**: Recuperación lenta 🟡
- **Rojo (> 1 hora)**: Problemas críticos de recuperabilidad 🔴

### **Panel 5: Pod Health Timeline**
Vista contextual que muestra:
- Restarts por pod en el tiempo
- Estado de pods (Running/Pending)
- Correlación entre eventos

### **Panel 6: Hourly Deployment Changes**
Histograma de cambios por hora:
- Identifica horas pico de despliegues
- Detecta patrones de cambio
- Visualiza impacto de cambios automáticos (HPA)

---

## 🔬 Escenarios de Prueba

### **Escenario 1: Sistema Estable**
```bash
# Estado actual sin carga
kubectl get pods -l app=do-sample-app
```

**Métricas esperadas**:
- Deployment Lead Time: ~6-9 horas (edad de los pods actuales)
- Deployment Frequency: ~0 (sin cambios)
- Change Fail %: 0% (sin restarts)
- MTTR: ~6-9 horas (sin incidentes recientes)

---

### **Escenario 2: Despliegue Manual**
```bash
# Forzar rolling update
kubectl set image deployment/do-sample-app \
  do-sample-app=978848629209.dkr.ecr.us-east-1.amazonaws.com/do-sample-app:v1.0.0

# Observar en Grafana (refresca cada 10s)
```

**Cambios esperados en 2-5 minutos**:
- Deployment Lead Time: ⬇️ < 5 minutos (pods nuevos)
- Deployment Frequency: ⬆️ Pico en el gráfico
- Change Fail %: Se mantiene en 0% (despliegue exitoso)
- MTTR: ⬇️ < 5 minutos (recuperación rápida)

---

### **Escenario 3: Autoescalado con Locust**
```bash
# Iniciar prueba de carga en Locust
# 100 usuarios, spawn rate 10
# URL: http://ab20cfd153585465bbd3873a31e2ebe9-658130050.us-east-1.elb.amazonaws.com:8089
```

**Cambios esperados en 5-10 minutos**:
- Deployment Lead Time: ⬇️ Disminuye (pods nuevos del HPA)
- Deployment Frequency: ⬆️ Múltiples picos (HPA crea/destruye pods)
- Change Fail %: Se mantiene bajo (< 5%)
- MTTR: ⬇️ < 1 minuto (Kubernetes recupera pods rápidamente)

---

### **Escenario 4: Simular Fallo**
```bash
# Eliminar un pod para simular fallo
kubectl delete pod -l app=do-sample-app --force --grace-period=0

# Kubernetes lo recreará automáticamente
watch kubectl get pods -l app=do-sample-app
```

**Cambios esperados en 30-60 segundos**:
- Deployment Lead Time: ⬇️ < 1 minuto (pod nuevo)
- Deployment Frequency: ⬆️ Pico (evento de reemplazo)
- Change Fail %: ⬆️ Aumenta temporalmente
- MTTR: ⬆️ ~30-45s (tiempo de recreación + readiness)

---

## 📊 Correlación con el Libro

### **Cita del Capítulo 1 (página 9)**:
> "DORA's research found that making changes frequently and reliably is correlated to organizational success. The Four Key Metrics provide a way to measure this capability."

### **Implementación en este Dashboard**:

| Métrica | Cómo la medimos | Tecnología usada |
|---------|-----------------|------------------|
| **Lead Time** | Edad de pods desde creación | `kube_pod_created` de kube-state-metrics |
| **Frequency** | Rate de restarts + pod count | `kube_pod_container_status_restarts_total` |
| **Fail %** | Restarts / Pods Running | Combinación de métricas de estado |
| **MTTR** | Tiempo desde pod start | `kube_pod_start_time` |

### **Filosofía IaC aplicada**:
- ✅ **Automatización total**: Todo vía Kubernetes manifests
- ✅ **Observabilidad**: Prometheus captura métricas automáticamente
- ✅ **Self-healing**: Kubernetes recupera pods automáticamente (MTTR bajo)
- ✅ **Escalado declarativo**: HPA ajusta réplicas según demanda (Frequency)

---

## 🎯 Valores Objetivo para este Proyecto

Basados en el contexto de un entorno de aprendizaje con autoescalado:

| Métrica | Objetivo | Razonamiento |
|---------|----------|--------------|
| **Lead Time** | < 1 hora | Pods se recrean frecuentemente con HPA |
| **Frequency** | 5-10 eventos/hora | HPA + Cluster Autoscaler activos |
| **Fail %** | < 10% | Imagen corregida con connection pooling |
| **MTTR** | < 2 minutos | K8s liveness/readiness probes + HPA |

---

## 🔍 Validación de Implementación

### **Verificar que Prometheus recolecta datos**:
```bash
# Conectarse a Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Abrir en navegador: http://localhost:9090
# Ejecutar query: kube_pod_info{namespace="default"}
```

### **Verificar que Grafana detectó el dashboard**:
```bash
# Ver logs del sidecar
kubectl logs deployment/prometheus-grafana -n monitoring -c grafana-sc-dashboard --tail=5

# Debe mostrar: "Writing /tmp/dashboards/dora-metrics.json"
```

### **Verificar métricas actuales**:
```bash
# Deployment Lead Time
kubectl get pods -l app=do-sample-app -o json | jq '.items[0].metadata.creationTimestamp'

# Change Fail Percentage
kubectl get pods -l app=do-sample-app -o json | jq '[.items[].status.containerStatuses[0].restartCount] | add'

# MTTR
kubectl get pods -l app=do-sample-app -o json | jq '.items[0].status.startTime'
```

---

## 📚 Relación con otros Capítulos del Libro

### **Capítulo 2: Principles of Infrastructure as Code**
- Principio 3: "Make Systems Reliable and Repeatable" → MTTR bajo
- Principio 5: "Test and Validate Changes" → Change Fail % bajo

### **Capítulo 3: Infrastructure Platforms**
- Kubernetes como plataforma de IaC → Métricas automáticas vía kube-state-metrics

### **Capítulo 5: Building Infrastructure Stacks**
- Stack completo (App + DB + Monitoring) → Métricas integradas en el pipeline

### **Capítulo 11: Testing Infrastructure Changes**
- Test de carga con Locust → Valida las métricas bajo estrés

---

## 🎬 Demo Script para Presentación

### **1. Mostrar estado inicial (2 min)**
```bash
# Terminal 1: Grafana dashboard abierto
# Terminal 2: Mostrar pods estables
kubectl get pods -l app=do-sample-app

# Explicar: "Estado base - 2 pods, sin cambios recientes"
```

### **2. Generar carga (5 min)**
```bash
# Abrir Locust en navegador
# Configurar: 50 usuarios, spawn rate 5
# Click "Start Swarming"

# Narración: "Observen cómo Deployment Frequency aumenta cuando HPA crea pods"
```

### **3. Simular fallo (3 min)**
```bash
kubectl delete pod -l app=do-sample-app --force --grace-period=0

# Narración: "MTTR muestra recuperación en < 1 minuto gracias a K8s"
```

### **4. Analizar resultados (5 min)**
```bash
# En Grafana, señalar:
# - Lead Time disminuyó (pods nuevos)
# - Frequency aumentó (múltiples cambios)
# - Fail % se mantuvo bajo (calidad)
# - MTTR < 2 min (recuperación rápida)

# Conclusión: "Estas métricas prueban que IaC permite cambios frecuentes y confiables"
```

---

## 🛠️ Troubleshooting

### **Dashboard no aparece en Grafana**
```bash
# Verificar ConfigMap
kubectl get cm dora-metrics-dashboard -n monitoring

# Verificar logs del sidecar
kubectl logs deployment/prometheus-grafana -n monitoring -c grafana-sc-dashboard

# Reiniciar Grafana
kubectl rollout restart deployment/prometheus-grafana -n monitoring
```

### **Métricas muestran "No Data"**
```bash
# Verificar Prometheus está scrapeando
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Abrir http://localhost:9090/targets

# Verificar kube-state-metrics
kubectl get pods -n monitoring | grep kube-state-metrics
```

### **Valores de métricas no parecen correctos**
```bash
# Forzar actualización de pods para generar datos
kubectl rollout restart deployment/do-sample-app

# Esperar 2-3 minutos para que Prometheus actualice
```

---

## 📖 Referencias

- **Libro**: "Infrastructure as Code" por Kief Morris (3rd Edition)
- **DORA Research**: https://dora.dev/
- **Prometheus Queries**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Grafana Dashboards**: https://grafana.com/docs/grafana/latest/dashboards/

---

**✅ Dashboard implementado exitosamente**

Este dashboard representa fielmente la filosofía del Capítulo 1: "hacer cambios frecuentes y confiables" mediante métricas objetivas que Kubernetes y Prometheus capturan automáticamente.
