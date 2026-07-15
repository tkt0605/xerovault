FROM node:22-alpine
ENV CI=true
RUN apk add --no-cache openssl
RUN corepack enable && corepack prepare pnpm@11.7.0 --activate

WORKDIR /app
COPY pnpm-workspace.yaml pnpm-lock.yaml ./
COPY packages/shared ./packages/shared
COPY backend ./backend
RUN pnpm install --frozen-lockfile

WORKDIR /app/backend
RUN npx prisma generate

EXPOSE 8000
CMD ["pnpm", "run", "dev"]
