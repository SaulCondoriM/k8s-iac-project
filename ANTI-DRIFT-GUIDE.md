# Anti-Drift Monitoring Implementation
## Chapter 2: Principles of Cloud Age Infrastructure

### 📖 Concepto del Libro

**Ubicación**: Capítulo 2, sección "The Automation Fear Spiral" (páginas 19-20)

**Cita clave**: 
> "Schedule an hourly process that continuously applies the code to those servers to prevent configuration drift."

El libro describe el **"automation fear spiral"** donde la falta de confianza en automatización lleva a no usarla consistentemente, lo que perpetúa la inconsistencia del sistema.

---

### 🎯 Implementación

He implementado un **CronJob de Kubernetes** que ejecuta verificaciones de drift cada hora para asegurar que la infraestructura siempre coincida con el código declarativo.

#### Componentes Desplegados

1. **Imagen Docker**: `978848629209.dkr.ecr.us-east-1.amazonaws.com/drift-monitor:v1.0.0`
   - Basada en Alpine Linux
   - Incluye: kubectl, aws-cli, ansible, git, curl, jq
   
2. **CronJob**: `drift-monitor`
   - Schedule: `0 * * * *` (cada hora en punto)
   - Namespace: `default`
   - ServiceAccount: `drift-monitor` (con permisos RBAC)

3. **Checks Implementados**:
   - ✅ Número de nodos (min: 2, max: 5)
   - ✅ HPA configurado correctamente (min: 1, max: 10)
   - ✅ Cluster Autoscaler running
   - ✅ Aplicación desplegada con imagen correcta
   - ✅ PostgreSQL operacional
   - ✅ Metrics Server funcionando
   - ✅ LoadBalancers activos (≥2)

---

### 🚀 Uso

#### Ver el CronJob

```bash
kubectl get cronjob drift-monitor
```

**Output esperado**:
```
NAME            SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
drift-monitor   0 * * * *   False     0        45m             2h
```

#### Ejecutar Check Manual

```bash
# Crear Job manual
kubectl apply -f manifests-aws/drift-monitor.yaml

# Ver logs en tiempo real
kubectl logs -f job/drift-monitor-manual
```

#### Ver Historial de Ejecuciones

```bash
# Últimos 3 Jobs exitosos
kubectl get jobs -l app=drift-monitor --sort-by=.status.startTime

# Ver logs de una ejecución específica
kubectl logs job/drift-monitor-28450320  # Ejemplo de CronJob
```

#### Interpretar Resultados

**✅ Sin Drift**:
```
============================================
Drift Checks Completed: Mon Nov  3 04:31:09 UTC 2025
============================================
✅ RESULTADO: NO HAY DRIFT
   La infraestructura coincide con el código
   Implementando: 'Minimize Variation' (Chapter 2)
```

**❌ Con Drift**:
```
============================================
❌ RESULTADO: DRIFT DETECTADO
   Se requiere corrección manual o re-aplicación de código

Remediación sugerida:
   kubectl apply -f manifests-aws/
```

---

### 🔧 Remediación de Drift

Si se detecta drift, ejecutar:

```bash
# Re-aplicar toda la configuración
kubectl apply -f manifests-aws/

# O específicamente el recurso con drift
kubectl apply -f manifests-aws/hpa.yaml
kubectl apply -f manifests-aws/application.yaml
```

---

### 📊 Monitoreo Avanzado

#### Ver Schedule de Próxima Ejecución

```bash
kubectl get cronjob drift-monitor -o jsonpath='{.spec.schedule}'
# Output: 0 * * * *
```

#### Suspender Temporalmente

```bash
kubectl patch cronjob drift-monitor -p '{"spec":{"suspend":true}}'
```

#### Reanudar

```bash
kubectl patch cronjob drift-monitor -p '{"spec":{"suspend":false}}'
```

#### Modificar Frecuencia

```bash
# Cambiar a cada 30 minutos
kubectl patch cronjob drift-monitor -p '{"spec":{"schedule":"*/30 * * * *"}}'

# Cambiar a cada 6 horas
kubectl patch cronjob drift-monitor -p '{"spec":{"schedule":"0 */6 * * *"}}'
```

---

### 🎓 Principios Implementados

Este sistema implementa directamente 3 principios del Chapter 2:

1. **Minimize Variation**: Detecta cualquier desviación del estado declarado
2. **Face Your Fears**: Automatización continua en lugar de manual ocasional
3. **Reproducibility**: El código es la única fuente de verdad

---

### 📈 Métricas DORA Relacionadas

Este sistema impacta positivamente en:

- **Deployment Frequency**: Facilita despliegues frecuentes con confianza
- **Change Fail Percentage**: Reduce fallos al detectar drift temprano
- **Mean Time to Restore**: Recuperación rápida al identificar drift automáticamente

---

### 🔗 Archivos Relacionados

- **Dockerfile**: [`ansible-aws/Dockerfile.drift-monitor`](../ansible-aws/Dockerfile.drift-monitor)
- **Script**: [`ansible-aws/drift-check.sh`](../ansible-aws/drift-check.sh)
- **Manifest**: [`manifests-aws/drift-monitor.yaml`](../manifests-aws/drift-monitor.yaml)
- **Imagen ECR**: `978848629209.dkr.ecr.us-east-1.amazonaws.com/drift-monitor:v1.0.0`

---

### ✅ Estado Actual

```bash
# Verificar estado completo
kubectl get cronjob,job,pod -l app=drift-monitor

# Ejemplo de output:
NAME                      SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/drift-monitor   0 * * * *   False     0        45m             2h

NAME                                 COMPLETIONS   DURATION   AGE
job.batch/drift-monitor-28450320     1/1           8s         45m

NAME                                 READY   STATUS      RESTARTS   AGE
pod/drift-monitor-28450320-abcd      0/1     Completed   0          45m
```

---

### 🎯 Siguiente Paso

Implementar alertas a Slack/Email cuando se detecte drift:

```bash
# Agregar webhook de Slack al ConfigMap
kubectl edit configmap drift-monitor-config
# Agregar: SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

---

**Implementado por**: Anti-Drift Automation System  
**Fecha**: 2025-11-03  
**Versión**: 1.0.0  
**Estado**: ✅ Operacional
