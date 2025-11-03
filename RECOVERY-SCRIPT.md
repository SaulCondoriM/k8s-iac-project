# 🔄 Script de Recuperación Automática

## Descripción
Script para recuperar automáticamente la aplicación cuando se cae debido a problemas de conexión con PostgreSQL durante pruebas de carga.

## Uso

### Opción 1: Ejecución Simple
```bash
./recover-app.sh
```

### Opción 2: Con logs detallados
```bash
./recover-app.sh 2>&1 | tee recovery-$(date +%Y%m%d-%H%M%S).log
```

## ¿Qué hace el script?

1. ✅ **Verifica** conectividad con el cluster de Kubernetes
2. 🔄 **Reinicia** PostgreSQL para limpiar conexiones corruptas
3. ⏳ **Espera** a que PostgreSQL esté completamente operativo
4. 🗑️ **Elimina** todos los pods de la aplicación con conexiones problemáticas
5. 🚀 **Recrea** pods nuevos con conexiones frescas
6. 🔍 **Verifica** que la aplicación responda correctamente
7. 📊 **Muestra** el estado final de todos los componentes

## Tiempo estimado
- **Total**: ~1-2 minutos
- PostgreSQL reinicio: 30-40 segundos
- Pods de aplicación: 20-30 segundos
- Verificaciones: 15-20 segundos

## Cuándo usarlo

### ✅ Usar cuando:
- La aplicación retorna 502 Bad Gateway
- Después de pruebas de carga intensas con Locust
- Ves errores "conn busy" en los logs
- Los pods están en CrashLoopBackOff

### ❌ No usar cuando:
- El cluster de Kubernetes no está accesible
- Hay problemas de red con DigitalOcean
- Los nodos del cluster están caídos

## Verificación Manual

Después de ejecutar el script, puedes verificar manualmente:

```bash
# Ver estado de los pods
kubectl get pods

# Ver logs de la aplicación
kubectl logs -l app=do-sample-app --tail=20

# Probar la aplicación
curl http://45.55.116.144/

# Ver métricas del HPA
kubectl get hpa do-sample-app-hpa
```

## Monitoreo en Tiempo Real

```bash
# Ver pods en tiempo real
kubectl get pods -l app=do-sample-app -w

# Ver HPA en tiempo real
kubectl get hpa -w

# Ver logs en streaming
kubectl logs -f -l app=do-sample-app
```

## Troubleshooting

### El script falla en PostgreSQL
```bash
# Verificar estado de PostgreSQL
kubectl get pods -l app.kubernetes.io/name=postgresql
kubectl logs postgresdb-postgresql-0 --tail=50

# Reinicio manual
kubectl delete pod postgresdb-postgresql-0
```

### Los pods no se levantan
```bash
# Ver qué está pasando
kubectl describe pods -l app=do-sample-app

# Ver eventos del cluster
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### La aplicación aún retorna 502
```bash
# Esperar más tiempo (a veces necesita 30-60 segundos)
sleep 30
curl http://45.55.116.144/

# O ejecutar el script de nuevo
./recover-app.sh
```

## Automatización con Cron

Para ejecutar automáticamente cada X minutos (no recomendado en producción):

```bash
# Editar crontab
crontab -e

# Agregar (ejecutar cada 10 minutos si falla)
*/10 * * * * /ruta/a/recover-app.sh >> /var/log/k8s-recovery.log 2>&1
```

## Notas Importantes

⚠️ **Este script es un workaround temporal**. El problema real es un bug en el código de la aplicación que no maneja correctamente el pool de conexiones de PostgreSQL.

### Solución Permanente Recomendada:
1. Modificar el código Go para usar un pool de conexiones (`pgxpool`)
2. Implementar retry logic para reconexiones
3. Agregar circuit breakers
4. Implementar health checks apropiados

## URLs de Acceso

- **Aplicación**: http://45.55.116.144/
- **Locust UI**: http://138.197.240.205:8089
- **Grafana**: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`

## Soporte

Si el script no funciona después de 2-3 intentos:
1. Verificar logs del cluster
2. Revisar cuotas de recursos en DigitalOcean
3. Considerar escalar los nodos del cluster
4. Verificar que no haya problemas de red

---

**Última actualización**: 25 de octubre de 2025
