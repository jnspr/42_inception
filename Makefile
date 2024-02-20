COMPOSE_FLAGS=--project-name inception -f srcs/docker-compose.yml

# Sets up the whole application
up: ensure_data
	docker-compose $(COMPOSE_FLAGS) build
	docker-compose $(COMPOSE_FLAGS) up

# Destroys containers and networks
down:
	docker-compose $(COMPOSE_FLAGS) down

# Full container, network and image rebuild
re:
	make clean
	make all

# Makes sure the data directory structure exists
ensure_data:
	mkdir -p $(HOME)/data/mariadb 2>/dev/null || true
	mkdir -p $(HOME)/data/wordpress 2>/dev/null || true

.PHONY: up down re ensure_data
