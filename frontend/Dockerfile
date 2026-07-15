FROM node:22-alpine
ENV CI=true
RUN corepack enable && corepack prepare pnpm@11.7.0 --activate

WORKDIR /app
COPY pnpm-workspace.yaml pnpm-lock.yaml ./
COPY packages/shared ./packages/shared
COPY frontend ./frontend
RUN pnpm install --frozen-lockfile

WORKDIR /app/frontend
EXPOSE 5173
CMD ["pnpm", "run", "dev", "--host"]
