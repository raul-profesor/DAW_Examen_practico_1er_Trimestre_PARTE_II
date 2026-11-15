# Escenario de debugging — NGINX + PHP-FPM (v3-debug)

Automatización (Terraform + Ansible) del **escenario de debugging** de la
práctica 3.1: la misma topología que el escenario "split" (NGINX y PHP-FPM
en máquinas separadas, comunicándose por FastCGI sobre TCP), pero con **dos
errores introducidos intencionadamente** que los alumnos deben diagnosticar.

> Este repositorio es **independiente**: contiene solo el escenario de
> debugging. Los escenarios "v1-single" y "v2-split" viven en el repositorio
> principal de la asignatura.
>
> 📖 **[Guía de despliegue paso a paso →](../automatizacion.P3.4/DEPLOY.md)**
> Cómo desplegar cada escenario, con los comandos exactos, la verificación
> y la solución del escenario de debugging.

---

## Los dos errores

### (a) El NGINX habla con PHP-FPM por el puerto equivocado

La máquina de NGINX apunta, en su directiva `fastcgi_pass`, al **puerto
9001**, donde no escucha nadie. PHP-FPM realmente escucha en el **9000**.

```hcl
# terraform/environments/v3-debug.tfvars
fpm_fastcgi_port       = 9000   # puerto que abre el SG (correcto)
fpm_fastcgi_wrong_port = 9001   # <- error introducido a propósito
```

El **security group de PHP-FPM es correcto**: abre el 9000 desde el SG de la
máquina de NGINX, que es exactamente donde escucha PHP-FPM.

```text
Security Group: running-zones-v3-debug-fpm-sg
  Inbound:
    TCP 22    from 0.0.0.0/0
    TCP 9000  from sg-running-zones-v3-debug-web-sg   <- correcto
```

En la máquina de NGINX:

```bash
grep fastcgi_pass /etc/nginx/sites-available/zonasrunning
# fastcgi_pass 172.31.x.x:9001;   <- debería ser 9000
```

**Síntoma:** `502 Bad Gateway`. NGINX abre la conexión contra el 9001 y no
hay ningún proceso escuchando ahí, así que la conexión falla.

```bash
# El log de NGINX lo dice todo
sudo tail -f /var/log/nginx/runningzones.error.log
# upstream timed out (110: Connection timed out) while connecting to upstream,
# upstream: "fastcgi://172.31.x.x:9001"
```

### (b) El código no está en la máquina de PHP-FPM

Se borran **todas** las carpetas del código de la aplicación (`public/`,
`src/`, `nginx/`, `fpm/` y `php/`) del servidor de PHP-FPM, que es la máquina
que ejecuta el código. Solo se deja intacto el directorio `.git`.

La máquina de NGINX (el proxy) **conserva todo el código**: NGINX resuelve
`SCRIPT_FILENAME` en local y se lo pasa a PHP-FPM, que lo ejecuta en la otra
máquina. Por eso el código tiene que estar también en el proxy.

**Lo único que falta en la máquina de PHP-FPM es el código.** El resto está
perfectamente configurado:

```bash
# El virtual host de NGINX existe y está bien configurado (fastcgi_pass al 9000)
ls -la /etc/nginx/sites-available/
cat /etc/nginx/sites-available/zonasrunning
sudo nginx -t        # syntax is ok

# PHP-FPM escuchando en el puerto correcto
sudo grep -nE '^\s*listen =' /etc/php/8.3/fpm/pool.d/www.conf
# listen = 0.0.0.0:9000
```

!!! note "Este vhost no se activa"
    El fichero `zonasrunning` se deja en `sites-available` pero **no** se
    enlaza en `sites-enabled`: en la máquina de PHP-FPM no tiene que
    servir nada, porque el tráfico entra por la máquina "web" (el proxy) y
    se reenvía a PHP-FPM por FastCGI. Su `fastcgi_pass` apunta al 9000,
    que es el puerto correcto: **no** es el sitio donde está el error.

**Síntoma:** `404 Not Found` y en el log de PHP-FPM:

```
WARNING: [pool www] child 123 said into stderr: "PHP message: PHP Warning:
include(): Failed opening '/var/www/running-zones/public/index.php'"
```

---

## Diagnóstico guiado

| Error | Síntoma | Dónde está la pista |
|---|---|---|
| (a) `fastcgi_pass` con puerto equivocado | **502 Bad Gateway** | `/var/log/nginx/runningzones.error.log` |
| (b) Código ausente en PHP-FPM | **404 Not Found** | `/var/log/php8.3-fpm.log` |

El orden de diagnóstico correcto es:

1. ¿El código HTTP es 502 o 404? Distingue los dos errores.
2. **502** → el problema está en la comunicación NGINX ↔ PHP-FPM. Compara
   **los tres puertos**:
   - el del security group: `aws ec2 describe-security-groups ...`
   - el de `fastcgi_pass`: `grep fastcgi_pass /etc/nginx/sites-available/zonasrunning`
   - el de escucha de PHP-FPM: `sudo ss -tln | grep 9000`
3. **404** → el problema está en el despliegue del código:
   `ls -la /var/www/running-zones/`

!!! note "El error (a) está en el cliente, no en el firewall"
    Todo el software está correctamente instalado y configurado: PHP-FPM
    escucha en el 9000 y el security group abre el 9000 desde el SG de
    NGINX. El único que está mal es el **cliente**: la directiva
    `fastcgi_pass` del NGINX apunta al 9001, donde no escucha nadie.

    Por eso el log de NGINX dice "Connection timed out" (o "Connection
    refused") y no "No such file or directory": la conexión se intenta
    establecer contra un puerto donde no hay ningún proceso.

    Ojo: el security group y `ss -tln` **coinciden** (9000 en ambos), así
    que la comparación entre ellos no revela nada. La pista está en el
    `fastcgi_pass` del NGINX, que es el tercer puerto de la lista.

---

## Uso

### Requisitos previos

- **Terraform** >= 1.5 instalado.
- **Ansible** >= 2.15 instalado.
- **AWS CLI** v2 (para consultar los security groups al diagnosticar).
- Credenciales de AWS configuradas (`~/.aws/credentials` o variables de
  entorno).
- Una cuenta AWS con una VPC por defecto, y con permisos en la región
  configurada en `terraform/environments/v3-debug.tfvars` (`us-east-1` por
  defecto).

### Despliegue

```bash
make help              # Lista los objetivos disponibles
make deploy            # Despliega el escenario (siempre con los 2 errores)
make output            # Muestra las IPs y la URL
make destroy           # Destruye la infraestructura (y los costes)
```

!!! warning "Este escenario solo se despliega de una manera"
    No existe ninguna forma de desplegarlo "correcto". Los dos errores se
    introducen siempre, y la automatización **no** ofrece ningún objetivo
    para revertirlos: diagnosticarlos y corregirlos es precisamente el
    trabajo del alumno.

    Si el profesor quiere comprobar que la parte "correcta" de la
    automatización funciona, puede hacerlo sobre los repositorios de los
    escenarios `v1-single` y `v2-split`, que sí se despliegan correctamente.

### Objetivos

| Objetivo | Descripción |
|---|---|
| `deploy` | Despliegue completo: Terraform + Ansible, **con los errores introducidos**. |
| `apply` | Solo crea la infraestructura con Terraform. |
| `configure` | Solo instala y configura el software con Ansible (con los errores). |
| `output` | Muestra las IPs y la URL del despliegue. |
| `destroy` | Destruye la infraestructura. |
| `clean` | Borra los ficheros locales generados (no toca AWS). |
| `check` | Valida la sintaxis de Terraform y Ansible. |

### Verificación

```bash
# Código de estado
curl -s -o /dev/null -w "%{http_code}\n" http://<IP_WEB>

# Con el nombre del virtual host
curl -H "Host: zonasrunning" http://<IP_WEB>/
```

---

## Estructura

```text
automatizacion.P3.4-debug/
├── Makefile                     # Objetivos de despliegue
├── terraform/
│   ├── versions.tf              # Versiones de Terraform y providers
│   ├── providers.tf             # Provider AWS + VPC/subred por defecto
│   ├── ami.tf                   # Data source: AMI de Ubuntu 24.04
│   ├── keys.tf                  # Generación del par de claves SSH
│   ├── security_groups.tf       # SG "web" y SG "fpm" + regla FastCGI (9000)
│   ├── instances.tf             # Las 2 instancias EC2
│   ├── variables.tf             # Variables parametrizables
│   ├── outputs.tf               # Outputs + generación del inventario
│   ├── modules/instances/       # Módulo reutilizable de EC2
│   └── environments/
│       └── v3-debug.tfvars      # Variables del escenario (con el error)
└── ansible/
    ├── ansible.cfg
    ├── inventory/
    │   ├── hosts.ini            # GENERADO por Terraform
    │   └── group_vars/          # Variables de Ansible
    ├── playbooks/
    │   └── deploy.yml           # Playbook principal
    └── roles/
        ├── common/              # Actualizar el sistema y paquetes base
        ├── php_fpm/             # Instalar PHP-FPM, configurar el pool y desplegar
        │                        #   el vhost de NGINX en sites-available
        ├── nginx/               # Instalar NGINX y el virtual host
        ├── app_deploy/          # Clonar la app y ajustar permisos
        └── debug_scenarios/     # Introduce los 2 errores (no hay forma de revertirlos)
```

---

## Solución del ejercicio (para el profesor)

!!! note "No la repartas antes de la práctica"
    Los comandos que siguen son la solución. Están aquí para que el
    profesor pueda preparar la práctica o verificar el resultado.

Corrige el puerto del `fastcgi_pass` en la máquina de NGINX:

```bash
# La IP privada de PHP-FPM (la que aparece en el fastcgi_pass)
FPM_IP=$(terraform -chdir=terraform output -raw fpm_private_ip)

ssh -i terraform/.ssh/running-zones-v3-debug.pem ubuntu@$(terraform -chdir=terraform output -raw web_public_ip)
sudo sed -i "s/fastcgi_pass ${FPM_IP}:9001/fastcgi_pass ${FPM_IP}:9000/" \
    /etc/nginx/sites-available/zonasrunning
sudo nginx -t && sudo systemctl reload nginx
```

!!! tip "Alternativa: corregirlo desde la automatización"
    Si prefieres no editar el fichero a mano, ponle 9000 a la variable
    `fpm_fastcgi_wrong_port` del `terraform/environments/v3-debug.tfvars`,
    reaplica Terraform y vuelve a ejecutar `make configure`. Ojo: eso
    **elimina el error del ejercicio**, así que úsalo solo para verificar
    la parte "correcta" de la automatización, no con los alumnos.

Y redespliega el código de la aplicación en la máquina de PHP-FPM (allí se
han borrado **todas** las carpetas del código):

```bash
ssh -i terraform/.ssh/running-zones-v3-debug.pem ubuntu@<IP_FPM>
sudo rm -rf /var/www/running-zones
sudo git clone https://github.com/raul-profesor/nginx-php-fpm.git /var/www/running-zones
sudo chown -R www-data:www-data /var/www/running-zones
sudo chmod -R 755 /var/www/running-zones
```

!!! note "No hay que tocar la configuración de NGINX en PHP-FPM"
    El virtual host de la máquina de PHP-FPM (`/etc/nginx/sites-available/
    zonasrunning`) ya está desplegado y **correctamente configurado** (su
    `fastcgi_pass` apunta al 9000, que es el puerto real de PHP-FPM). Solo
    falta el código, así que la solución del error (b) consiste únicamente
    en redesplegar la aplicación.

!!! note "El security group no hay que tocarlo"
    En este escenario la regla de ingress del SG de PHP-FPM es correcta
    (abre el 9000 desde el SG de NGINX). El error está solo en el
    `fastcgi_pass` del NGINX, así que no hay que autorizar ni revocar
    ninguna regla del security group.

---

## Referencias

- Práctica 3.1 (enunciado): `docs/Tema3/P3.1.nueva.md` del repositorio principal.
- Aplicación: <https://github.com/raul-profesor/nginx-php-fpm>
- Documentación de NGINX: <https://nginx.org/en/docs/>
- Documentación de PHP-FPM: <https://www.php.net/manual/en/install.fpm.php>
