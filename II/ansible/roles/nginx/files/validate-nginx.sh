#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Valida la sintaxis de un virtual host de NGINX.
#
# NGINX no permite validar un bloque "server" suelto con "nginx -t -c",
# porque el fichero no tiene el contexto "http { }" que lo surrounda
# ("server directive is not allowed here").
#
# Este script genera una configuracion completa y temporal que incluye el
# fichero a validar dentro de un bloque http{}, y ejecuta "nginx -t" con ella.
#
# Detalle importante: los "include" de NGINX con ruta relativa (por ejemplo
# "include snippets/fastcgi-php.conf") se resuelven respecto al directorio
# del fichero principal de configuracion. Por eso la configuracion temporal
# se escribe en /etc/nginx/ (y no en /tmp), de modo que las rutas relativas
# sean las mismas que en el nginx.conf real.
#
# Uso: validate-nginx.sh /ruta/al/vhost.conf
# ---------------------------------------------------------------------------
set -uo pipefail

VHOST="$1"
if [[ -z "${VHOST}" ]]; then
    echo "Uso: $0 <fichero>" >&2
    exit 2
fi

if [[ ! -f "${VHOST}" ]]; then
    echo "No existe el fichero a validar: ${VHOST}" >&2
    exit 2
fi

# La configuracion temporal debe vivir en el mismo directorio que el
# nginx.conf real para que los "include" relativos funcionen.
TMP_CONF="/etc/nginx/.ansible-validate.conf"

cleanup() {
    rm -f "${TMP_CONF}"
}
trap cleanup EXIT

cat > "${TMP_CONF}" <<EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    include ${VHOST};
}
EOF

nginx -t -c "${TMP_CONF}"
