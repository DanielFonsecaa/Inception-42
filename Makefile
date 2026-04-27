.DEFAULT_GOAL := all

.PHONY: all build down re clean fclean logs help

RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m

COMPOSE_FILE = srcs/docker-compose.yml
DOCKER_COMPOSE = docker-compose -f $(COMPOSE_FILE)
DATA_PATH = ${HOME}/data

help:
	@echo "$(BLUE)=== Inception 42 - Docker Project ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Available commands:$(NC)"
	@echo "  $(GREEN)make all$(NC)       - Create volumes, build images and start containers"
	@echo "  $(GREEN)make down$(NC)      - Stop and remove containers"
	@echo "  $(GREEN)make re$(NC)        - Rebuild everything (down + clean + build + up)"
	@echo "  $(GREEN)make clean$(NC)     - Remove containers and images"
	@echo "  $(GREEN)make fclean$(NC)    - Remove everything including volumes and data"
	@echo "  $(GREEN)make logs$(NC)      - Show logs from all containers"
	@echo "  $(GREEN)make ps$(NC)        - Show container status"
	@echo ""

all: setup
	@echo "$(GREEN)✓ Inception project started successfully!$(NC)"
	$(DOCKER_COMPOSE) up -d --build
	@echo "$(YELLOW)Access: https://dda-fons.42.fr$(NC)"

setup:
	@echo "Created data folders."
	@sudo mkdir -p $(DATA_PATH)/mariadb
	@sudo mkdir -p $(DATA_PATH)/wordpress
	@sudo chmod 777 $(DATA_PATH)/mariadb
	@sudo chmod 777 $(DATA_PATH)/wordpress

up:
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(BLUE)► Starting all containers...$(NC)"; \
		$(DOCKER_COMPOSE) up -d --build; \
	else \
		echo "$(BLUE)► Starting container: $(SERVICE)...$(NC)"; \
		$(DOCKER_COMPOSE) up -d --build $(SERVICE); \
	fi

down:
	@echo "$(BLUE)► Stopping containers...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

clean: down
	@echo "$(BLUE)► Removing Docker images...$(NC)"
	@docker rmi $$(docker images -q -f reference='inception*') 2>/dev/null || true
	@echo "$(GREEN)✓ Images removed$(NC)"

fclean: clean
	@echo "$(RED)► FULL CLEANUP - Removing EVERYTHING...$(NC)"
	@$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans >/dev/null 2>&1 || true
	@echo "$(BLUE)► Removing all Docker volumes...$(NC)"
	@docker volume prune -f >/dev/null 2>&1
	@echo "$(BLUE)► Removing all Docker images...$(NC)"
	@docker image prune -a -f >/dev/null 2>&1
	@echo "$(BLUE)► Removing all Docker networks...$(NC)"
	@docker network prune -f >/dev/null 2>&1
	@echo "$(BLUE)► Removing build cache...$(NC)"
	@docker builder prune -a -f >/dev/null 2>&1
	@echo "$(BLUE)► Fixing permissions...$(NC)"
	@sudo chown -R $(USER):$(USER) $(DATA_PATH) >/dev/null 2>&1 || true
	@echo "$(BLUE)► Removing persistent data...$(NC)"
	@rm -rf $(DATA_PATH)/* >/dev/null 2>&1
	@echo "$(GREEN)✓ COMPLETE CLEANUP DONE$(NC)"

re: fclean all
	@echo "$(GREEN)✓ Full rebuild completed$(NC)"

logs:
	@$(DOCKER_COMPOSE) logs -f
 
ps:
	@$(DOCKER_COMPOSE) ps

.PHONY: all setup stop down clean fclean re