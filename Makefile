# ===========================================================================
# Makefile - Escenario v3-debug - NGINX + PHP-FPM
#
# Topologia "split": NGINX y PHP-FPM en maquinas separadas, comunicandose
# por FastCGI/TCP.
#
# Uso:
#   make help          Lista los objetivos disponibles
#   make deploy        Despliega el escenario
#   make apply         Solo crea la infraestructura con Terraform
#   make configure     Solo configura el software con Ansible
#   make output        Muestra las IPs y la URL del despliegue
#   make destroy       Destruye la infraestructura (y los costes)
#   make clean         Borra los ficheros locales generados
# ===========================================================================

SHELL       := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

TF_DIR      := terraform
ANSIBLE_DIR := ansible
ENV_DIR     := $(TF_DIR)/environments
INVENTORY   := $(ANSIBLE_DIR)/inventory/hosts.ini

# El escenario es único: no es parametrizable.
SCENARIO    := v3-debug
TFVARS      := $(ENV_DIR)/$(SCENARIO).tfvars
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

# El ansible.cfg (en ansible/) no se carga al ejecutar desde la raíz del
# proyecto, así que se pasan estas opciones por entorno.
export ANSIBLE_CONFIG := $(CURDIR)/$(ANSIBLE_DIR)/ansible.cfg
export ANSIBLE_ROLES_PATH := $(CURDIR)/$(ANSIBLE_DIR)/roles
export ANSIBLE_HOST_KEY_CHECKING := False
export ANSIBLE_RETRY_FILES_ENABLED := False

.PHONY: help deploy apply configure destroy clean output check \
        check-tf check-ansible

# ===========================================================================
# Ayuda
# ===========================================================================
help: ## Muestra esta ayuda
	@printf '%b\n' ""
	@printf '%b\n' "$(BLUE)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' "$(BLUE)  Escenario v3-debug - NGINX + PHP-FPM$(NC)"
	@printf '%b\n' "$(BLUE)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' ""
	@printf '%b\n' "$(GREEN)Objetivos$(NC)"
	@printf '%b\n' "  $(GREEN)deploy$(NC)      Despliega el escenario"
	@printf '%b\n' "  $(GREEN)apply$(NC)       Solo crea la infraestructura con Terraform"
	@printf '%b\n' "  $(GREEN)configure$(NC)   Solo configura el software con Ansible"
	@printf '%b\n' "  $(GREEN)output$(NC)      Muestra las IPs y la URL del despliegue"
	@printf '%b\n' "  $(GREEN)destroy$(NC)     Destruye la infraestructura (y los costes)"
	@printf '%b\n' "  $(GREEN)clean$(NC)       Borra los ficheros locales generados"
	@printf '%b\n' "  $(GREEN)check$(NC)       Valida la sintaxis de Terraform y Ansible"
	@printf '%b\n' ""

# ===========================================================================
# Despliegue
# ===========================================================================
deploy: apply configure ## Despliega el escenario
	@printf '%b\n' ""
	@printf '%b\n' "$(YELLOW)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' "  Escenario v3-debug desplegado"
	@printf '%b\n' "$(YELLOW)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' ""
	@$(MAKE) --no-print-directory output

apply: ## Crea la infraestructura con Terraform (EC2, SG, claves)
	@printf '%b\n' "$(BLUE)[1/2] Terraform: creando la infraestructura...$(NC)"
	terraform -chdir=$(TF_DIR) init -input=false
	terraform -chdir=$(TF_DIR) apply $(TFVARS_ARG) -input=false -auto-approve
	@chmod 600 $(TF_DIR)/.ssh/*.pem 2>/dev/null || true

configure: ## Instala y configura el software con Ansible
	@printf '%b\n' "$(BLUE)[2/2] Ansible: instalando y configurando NGINX + PHP-FPM...$(NC)"
	@test -f $(INVENTORY) || { \
		printf '%b\n' "$(RED)ERROR: no existe $(INVENTORY). Ejecuta 'make apply' primero.$(NC)"; \
		exit 1; }
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) \
		--extra-vars "deploy_scenario=$(SCENARIO)"

output: ## Muestra la URL y las IPs del despliegue
	@printf '%b\n' ""
	@printf '%b\n' "$(GREEN)══════════════════════════════════════════════════════════════$(NC)"
	@printf '%b\n' "  Escenario: $(SCENARIO)"
	@printf '%b\n' "$(GREEN)══════════════════════════════════════════════════════════════$(NC)"
	@terraform -chdir=$(TF_DIR) output $(TFVARS_ARG) 2>/dev/null || true
	@WEB_IP="$$(terraform -chdir=$(TF_DIR) output -raw web_public_ip $(TFVARS_ARG) 2>/dev/null || true)"; \
	if [ -n "$$WEB_IP" ]; then \
		printf '%b\n' ""; \
		printf '%b\n' "$(BLUE)Diagnóstico desde la máquina web:$(NC)"; \
		printf '%b\n' "  ssh -i terraform/.ssh/*.pem ubuntu@$$WEB_IP"; \
		printf '%b\n' "  sudo tail -f /var/log/nginx/runningzones.error.log"; \
		printf '%b\n' ""; \
	fi

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

check-tf: ## Valida la configuración de Terraform
	@terraform -chdir=$(TF_DIR) fmt -check -recursive
	@terraform -chdir=$(TF_DIR) init -backend=false -input=false >/dev/null
	@terraform -chdir=$(TF_DIR) validate

check-ansible: ## Valida la sintaxis del playbook de Ansible
	@ansible-playbook --syntax-check -i $(ANSIBLE_DIR)/inventory/hosts.ini.example \
		$(PLAYBOOK) --extra-vars "deploy_scenario=$(SCENARIO)"
