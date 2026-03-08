################ Main Targets ################
init: check-system init-submodules rebuild start reload-nginx

check-system:
	@chmod +x check-system.sh
	@./check-system.sh || (printf "\e[1;31mSystem check failed. Fix above errors and re-run make init.\e[0m\n" && exit 1)

start:
	@docker compose up --build -d

stop:
	@docker compose down

################ Utility Targets ################
init-submodules:
	@git submodule update --init --recursive --force
	@git submodule foreach git checkout main
	@git submodule foreach git pull origin main

update-submodule:
	@git submodule update --remote --merge --recursive

status:
	@docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

reload: reload-nginx reload-postgres

reload-nginx:
	@docker exec nginx nginx -s reload

reload-postgres:
	@docker compose down postgres -v
	@docker compose up -d postgres

rebuild: rebuild-client rebuild-healthcare

rebuild-client:
	@cd ./Client-Interface && npm ci && npm run build

rebuild-healthcare:
	@cd ./healthcare-interface && npm ci && npm run build

################ Colors and Variables ################
COLOR := "\e[1;36m%s\e[0m\n"
RED :=   "\e[1;31m%s\e[0m\n"
LIME := "\e[1;92m%s\e[0m\n"
PARENT_NAME := $(notdir $(abspath $(dir $(lastword $(MAKEFILE_LIST)))))