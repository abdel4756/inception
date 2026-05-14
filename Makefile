COMPOSE = docker compose

DATA = $(HOME)/data
WP = $(DATA)/wordpress
DB = $(DATA)/mariadb

all: up

up:
	@mkdir -p $(WP) $(DB)
	@$(COMPOSE) up -d --build

ps:
	@$(COMPOSE) ps

logs:
	@$(COMPOSE) logs -f

down:
	@$(COMPOSE) down

clean: down

fclean:
	@$(COMPOSE) down -v
	@sudo rm -rf $(DATA)

re: fclean all

.PHONY: all up ps logs down clean fclean re