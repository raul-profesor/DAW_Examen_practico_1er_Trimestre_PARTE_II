# ---------------------------------------------------------------------------
# Escenario de DEBUGGING (v3-debug) - NGINX + PHP-FPM en maquinas separadas
#
# Se introducen DOS errores intencionados que los alumnos deben diagnosticar:
#
#   a) La maquina de NGINX habla con PHP-FPM por el puerto equivocado.
#      El security group de PHP-FPM es CORRECTO: abre el 9000 desde el SG
#      de la maquina de NGINX, que es donde realmente escucha PHP-FPM.
#      El que esta mal es el cliente: la directiva fastcgi_pass del NGINX
#      apunta al 9001, donde no escucha nadie.
#      -> Sintoma: "502 Bad Gateway". NGINX fala con el 9001 y no hay
#         nadie escuchando ahi.
#
#   b) El codigo de la aplicacion NO esta presente en la maquina de PHP-FPM
#      (lo borra el rol debug_scenarios de Ansible).
#      -> Sintoma: "File not found." (404) en /var/log/php8.3-fpm.log.
#
# Uso:
#   make deploy        (equivalente a terraform apply + ansible-playbook)
#
# Este escenario SOLO se despliega con los errores introducidos: no hay
# ninguna forma de desplegarlo "correcto" desde la automatizacion, porque
# diagnosticarlo y corregirlo es parte del ejercicio.
# ---------------------------------------------------------------------------

aws_region    = "us-east-1"
environment   = "v3-debug"
instance_type = "t3.small"
volume_size   = 20
allowed_cidr  = "0.0.0.0/0"

# ERROR INTENCIONADO (a): la directiva fastcgi_pass del NGINX apunta al
# puerto 9001, donde no escucha PHP-FPM (que escucha en el 9000).
#
# El security group de PHP-FPM es CORRECTO: abre el 9000 (fpm_fastcgi_port)
# desde el SG de la maquina de NGINX.
fpm_fastcgi_port       = 9000
fpm_fastcgi_wrong_port = 9001

tags = {
  Scenario    = "v3-debug"
  Description = "Escenario de debugging con errores introducidos"
}
