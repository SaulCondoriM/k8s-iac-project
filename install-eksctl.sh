#!/bin/bash

# Script para instalar eksctl en sistemas Linux
# Se requieren permisos de sudo

set -e

echo "=== Instalando eksctl ==="
echo ""

# Descargar eksctl
echo "📥 Descargando eksctl..."
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

# Mover a /usr/local/bin con sudo
echo "📦 Instalando en /usr/local/bin..."
sudo mv /tmp/eksctl /usr/local/bin/

# Verificar instalación
if command -v eksctl &> /dev/null; then
    echo "✅ eksctl instalado exitosamente"
    echo ""
    eksctl version
else
    echo "❌ Error al instalar eksctl"
    exit 1
fi

echo ""
echo "🎉 Instalación completa!"
echo ""
echo "Puedes verificar con: eksctl version"
