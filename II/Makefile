# ===========================================================================
# Makefile - Escenario p3.5-flask - DOS aplicaciones Flask + Nginx
#
# Topologia "una maquina": Nginx, Gunicorn(mi_app) y Gunicorn(atletismo) en
# la misma EC2. Nginx se comunica con cada Gunicorn por un socket Unix.
#
# Terraform SOLO crea la maquina (EC2, SG, claves).
# Ansible SOLO aprovisiona (paquetes, usuario flask, uv, apps, systemd, Nginx).
#
# Uso:
#   make help          Lista los objetivos disponibles
#   make deploy        Despliega el escenario
#   make apply         Solo crea la infraestructura con Terraform
#   make configure     Solo configura el software con Ansible
#   make output        Muestra las IPs y las URLs del despliegue
#   make destroy       Destruye la infraestructura (y los costes)
#   make clean         Borra los ficheros locales generados
#   make check         Valida la sintaxis de Terraform y Ansible
# ===========================================================================

SHELL       := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

TF_DIR      := terraform
ANSIBLE_DIR := ansible
ENV_DIR     := $(TF_DIR)/environments
INVENTORY   := $(ANSIBLE_DIR)/inventory/hosts.ini

# El escenario es unico: no es parametrizable.
SCENARIO    := p3.5-flask-debug
TFVARS      := $(ENV_DIR)/p3.5-flask.tfvars
PLAYBOOK    := $(ANSIBLE_DIR)/playbooks/deploy.yml

ifdef $(wildcard $(TFVARS))
TFVARS_ARG  := -var-file=$(TFVARS)
else
TFVARS_ARG  :=
endif

BLUE   := \033[0;34m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m

# El ansible.cfg (en ansible/) no se carga al ejecutar desde la raiz del
# proyecto, asi que se pasan estas opciones por entorno.
export ANSIBLE_CONFIG := $(CURDIR)/$(ANSIBLE_DIR)/ansible.cfg
export ANSIBLE_ROLES_PATH := $(CURDIR)/$(ANSIBLE_DIR)/roles
export ANSIBLE_HOST_KEY_CHECKING := False
export ANSIBLE_RETRY_FILES_ENABLED := False

.PHONY: help deploy apply configure destroy clean output check verify \
        check-tf check-ansible

# ===========================================================================
# Ayuda
# ===========================================================================
help: ## Muestra esta ayuda
	@printf '%b\n' ""
	@printf '%b\n' "$(BLUE)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' "$(BLUE)  Escenario p3.5-flask - Flask + Gunicorn + Nginx$(NC)"
	@printf '%b\n' "$(BLUE)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' ""
	@printf '%b\n' "$(GREEN)Objetivos$(NC)"
	@printf '%b\n' "  $(GREEN)deploy$(NC)      Despliega el escenario"
	@printf '%b\n' "  $(GREEN)apply$(NC)       Solo crea la infraestructura con Terraform"
	@printf '%b\n' "  $(GREEN)configure$(NC)   Solo configura el software con Ansible"
	@printf '%b\n' "  $(GREEN)output$(NC)      Muestra las IPs y las URLs del despliegue"
	@printf '%b\n' "  $(GREEN)destroy$(NC)     Destruye la infraestructura (y los costes)"
	@printf '%b\n' "  $(GREEN)clean$(NC)       Borra los ficheros locales generados"
	@printf '%b\n' "  $(GREEN)check$(NC)       Valida la sintaxis de Terraform y Ansible"
	@printf '%b\n' "  $(GREEN)verify$(NC)     Comprueba que las dos aplicaciones responden"
	@printf '%b\n' ""

# ===========================================================================
# Despliegue
# ===========================================================================
deploy: apply configure ## Despliega el escenario
	@printf '%b\n' ""
	@printf '%b\n' "$(YELLOW)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' "  Escenario p3.5-flask desplegado"
	@printf '%b\n' "$(YELLOW)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' ""
	@$(MAKE) --no-print-directory output

apply: ## Crea la infraestructura con Terraform (EC2, SG, claves)
	@printf '%b\n' "$(BLUE)[1/2] Terraform: creando la infraestructura...$(NC)"
	terraform -chdir=$(TF_DIR) init -input=false
	terraform -chdir=$(TF_DIR) apply $(TFVARS_ARG) -input=false -auto-approve
	@chmod 600 $(TF_DIR)/.ssh/*.pem 2>/dev/null || true

configure: ## Instala y configura el software con Ansible
	@printf '%b\n' "$(BLUE)[2/2] Ansible: instalando y configurando Flask + Gunicorn + Nginx...$(NC)"
	@test -f $(INVENTORY) || { \
		printf '%b\n' "$(RED)ERROR: no existe $(INVENTORY). Ejecuta 'make apply' primero.$(NC)"; \
		exit 1; }
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

output: ## Muestra las IPs y las URLs del despliegue
	@printf '%b\n' ""
	@printf '%b\n' "$(GREEN)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' "  Escenario: $(SCENARIO)"
	@printf '%b\n' "$(GREEN)══════════════════════════════════════════════════════════════$(NC)"
	@terraform -chdir=$(TF_DIR) output $(TFVARS_ARG) 2>/dev/null || true
	@IP="$$(terraform -chdir=$(TF_DIR) output -raw public_ip $(TFVARS_ARG) 2>/dev/null || true)"; \
	if [ -n "$$IP" ]; then \
		printf '%b\n' ""; \
		printf '%b\n' "$(BLUE)Las dos aplicaciones se sirven por la misma IP,$(NC)"; \
		printf '%b\n' "$(BLUE)cada una en su virtual host:$(NC)"; \
		printf '%b\n' ""; \
		printf '%b\n' "  mi_app      -> curl -H 'Host: flask-app.local' http://$$IP/"; \
		printf '%b\n' "  atletismo  -> curl -H 'Host: atletismo.local' http://$$IP/"; \
		printf '%b\n' ""; \
		printf '%b\n' "$(BLUE)Para usarlas por nombre, anade en el /etc/hosts de TU maquina:$(NC)"; \
		printf '%b\n' "  $$IP flask-app.local atletismo.local"; \
		printf '%b\n' ""; \
		printf '%b\n' "$(BLUE)Diagnostico en la maquina:$(NC)"; \
		printf '%b\n' "  ssh -i terraform/.ssh/*.pem ubuntu@$$IP"; \
		printf '%b\n' ""; \
	fi

# ===========================================================================
# Verificacion posterior al despliegue
# ===========================================================================
verify: ## Comprueba que las dos aplicaciones responden a traves de Nginx
	@printf '%b\n' ""
	@printf '%b\n' "$(BLUE)Verificando las dos aplicaciones...$(NC)"
	@IP="$$(terraform -chdir=$(TF_DIR) output -raw public_ip $(TFVARS_ARG) 2>/dev/null || true)"; \
	HOST=$${IP:-127.0.0.1}; \
	printf '%b\n' ""; \
	printf '%b\n' "  mi_app     (flask-app.local):"; \
	curl -sS -o /dev/null -w "    HTTP %{http_code}\n" -H "Host: flask-app.local" http://$$HOST/ || true; \
	printf '%b\n' "  atletismo (atletismo.local):"; \
	curl -sS -o /dev/null -w "    HTTP %{http_code}\n" -H "Host: atletismo.local" http://$$HOST/ || true; \
	printf '%b\n' "  atletismo /health:"; \
	curl -sS -w "\n" -H "Host: atletismo.local" http://$$HOST/health || true; \
	printf '%b\n' ""

# ===========================================================================
# Limpieza
# ===========================================================================
destroy: ## Destruye la infraestructura del escenario
	@printf '%b\n' "$(RED)Destruyendo la infraestructura del escenario $(SCENARIO)...$(NC)"
	terraform -chdir=$(TF_DIR) init -input=false
	terraform -chdir=$(TF_DIR) destroy $(TFVARS_ARG) -auto-approve
	@printf '%b\n' "$(GREEN)Infraestructura destruida.$(NC)"

clean: ## Borra los ficheros locales generados (no toca AWS)
	rm -rf $(TF_DIR)/.terraform $(TF_DIR)/.ssh
	rm -f $(TF_DIR)/*.tfstate $(TF_DIR)/*.tfstate.* $(TF_DIR)/crash.log
	rm -f $(INVENTORY)
	@printf '%b\n' "$(GREEN)Ficheros locales borrados.$(NC)"

# ===========================================================================
# Comprobaciones
# ===========================================================================
check: check-tf check-ansible ## Valida la sintaxis de Terraform y Ansible

check-tf: ## Valida la configuracion de Terraform
	@terraform -chdir=$(TF_DIR) fmt -check -recursive
	@terraform -chdir=$(TF_DIR) init -backend=false -input=false >/dev/null
	@terraform -chdir=$(TF_DIR) validate

check-ansible: ## Valida la sintaxis del playbook de Ansible
	@ansible-playbook --syntax-check -i $(ANSIBLE_DIR)/inventory/hosts.ini.example \
		$(PLAYBOOK)
