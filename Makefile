.PHONY: dev stop restart migrate db-studio clean

dev:
	docker compose up --build

stop:
	docker compose down

restart:
	docker compose restart

migrate:
	docker compose exec backend npx prisma migrate dev

db-studio:
	cd backend && npx prisma studio

clean:
	docker compose down -v --remove-orphans
