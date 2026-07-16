.PHONY: dev stop restart clean

dev:
	docker compose up --build

stop:
	docker compose down

restart:
	docker compose restart

clean:
	docker compose down -v --remove-orphans
