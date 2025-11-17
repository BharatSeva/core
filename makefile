################ Main Targets ################
init: init-submodules start rebuild-all

start:
	@docker compose up --build -d

stop:
	@docker compose down

################ Utility Targets ################
init-submodules:
	@git submodule update --init --recursive

update-submodule:
	@git submodule update --remote --merge --recursive

status:
	@docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

reload: reload-nginx reload-postgres

reload-nginx:
	@docker exec -it nginx nginx -s reload

reload-postgres:
	@docker compose down postgres -v
	@docker compose up -d postgres

rebuild-all: rebuild-client rebuild-healthcare

rebuild-client:
	@cd ./Client-Interface && npm i && npm run build
	@docker exec -it nginx nginx -s reload
	@cd ..

rebuild-healthcare:
	@cd ./healthcare-interface && npm i && npm run build
	@docker exec -it nginx nginx -s reload
	@cd ..

################ Colors and Variables ################
COLOR := "\e[1;36m%s\e[0m\n"
RED :=   "\e[1;31m%s\e[0m\n"
LIME := "\e[1;92m%s\e[0m\n"
PARENT_NAME := $(notdir $(abspath $(dir $(lastword $(MAKEFILE_LIST)))))