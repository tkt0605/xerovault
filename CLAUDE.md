# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Xero Vault: グループを作り、メンバーで目標(Goal)を設定し、達成をYES/NO投票で承認し合うことでスコア・継続ストリークを競うゴール管理アプリ。コンセプトは `docs/vision.md`、ドメインモデルは `docs/domain-model.md`、スコア計算式は `docs/score-design.md` を参照。

## Commands

Root is a pnpm workspace (`frontend`, `packages/shared`). Run `pnpm install` from the repo root first.

```bash
# Dev server (frontend only; DB/API are provided by Supabase, no local backend)
make dev              # docker compose up --build → http://localhost:5173
make stop / make restart / make clean

# From frontend/ directly (or `pnpm --filter xerovault-frontend <script>` from root)
pnpm dev
pnpm build            # vue-tsc && vite build — this is the type-check step, there is no separate typecheck script
pnpm lint
pnpm format / pnpm format:check
```

There is no test suite/runner in this repo (no `*.test.*`/`*.spec.*` files, no test script). Treat `pnpm build` (type-checking) and `pnpm lint` as the correctness gates.

Supabase CLI (`supabase`, devDependency in `frontend/`) is used to push migrations and deploy Edge Functions — see README for the full manual setup (Resend API key, Vault secrets, pg_cron). Applying a new file in `supabase/migrations/` requires running it against the linked Supabase project; there is no local Supabase stack wired up in docker-compose.

## Architecture

**No custom backend.** This used to be an Express+Prisma app; that layer was fully migrated into Postgres. All business logic (validation, authorization, score/streak calculation) now lives in `SECURITY DEFINER` RPC functions defined in `supabase/migrations/`. The frontend talks to Supabase directly via `@supabase/supabase-js` — there are no `insert`/`update`/`delete` RLS policies on the app tables; writes only happen through `supabase.rpc(...)`. Reads are allowed via RLS SELECT policies (and, for `profiles`, column-level grants — see below).

- `frontend/` — Vue 3 + Vite SPA, Pinia (setup-store style, see `frontend/src/stores/*.ts`) for state, Tailwind for styling, `vue-router` with a global `beforeEach` guard (`frontend/src/router/index.ts`) that redirects to `/auth/login` unless `meta.public` is set.
  - `src/lib/rpc.ts` — thin wrapper around `supabase.rpc()` that throws on `{ error }` instead of returning it. Nearly all data mutations/reads that aren't plain `select` go through this.
  - `src/lib/supabase.ts` — the single Supabase client instance, configured from `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY`.
  - `src/stores/*.ts` — one Pinia store per domain entity (`goal`, `group`, `vote`, `message`, `notification`, `auth`, `ui`), each calling specific RPC function names (e.g. `get_goals`, `create_goal`, `cast_vote`). When adding a new store action, check whether the matching RPC already exists in `supabase/migrations/` before assuming one needs to be written.
  - `src/composables/use*Events.ts` — Supabase Realtime (`postgres_changes`) subscriptions scoped to one entity (e.g. `useGoalEvents(goalId, { onVote, onMessage })`), cleaned up via `onUnmounted`. Follow this pattern for new realtime subscriptions rather than subscribing ad hoc inside components.
- `packages/shared/` (`@xerovault/shared`) — zod schemas + inferred types (`createGoalSchema`/`CreateGoalInput`, etc.) plus plain TS interfaces (`Goal`, `Group`, ...) shared between form validation and store/RPC response typing. One file per domain entity, re-exported from `src/index.ts`. When an RPC's return shape changes, update the matching interface here.
- `supabase/migrations/` — numbered, sequential SQL migrations (schema, RLS policies, RPC functions). This is the source of truth for business rules — read the relevant migration before changing behavior that looks like it "should" be in the frontend (validation, scoring, permissions). Notable ones:
  - `0001_init.sql` — schema + initial RLS/RPCs (`is_group_member`, `cast_vote`/`cancel_vote`, `recalc_group_score`, `create_invite`/`join_group`).
  - Security-sensitive column-level grant pattern (see `0010_in_app_notifications.sql`/`0014_profiles_update_column_grant.sql`): RLS alone only restricts by row, not column, so `profiles` has table-level SELECT/UPDATE revoked from `authenticated`/`anon` and only specific columns granted back (e.g. `grant update (name, notifications_enabled) on public.profiles to authenticated`). If you add a client-writable/readable column to `profiles` (or any table where not all columns should be client-exposed), use this revoke-then-grant-columns pattern, not a blanket table grant.
- `supabase/functions/` — Deno Edge Functions:
  - `notify-digest/` — daily email digest (pending votes, approaching/expired deadlines), invoked by `pg_cron` + `pg_net`.
  - `unsubscribe/` — no-login one-tap unsubscribe from digest email links.

## Domain model

- `profiles` — account, auto-created via trigger on `auth.users` insert.
- `groups` — a team sharing goals; holds `score`/`streak`.
- `group_members` — group↔user join table (owner tracked separately via `groups.owner_id`).
- `goals` — a goal is "concrete" (`is_concrete`, generated column) iff it has both `deadline` and `assignee_id`; concrete goals score higher and can reach `status: 'missed'`. Vague goals only ever go `pending`→`completed`.
- `goal_votes` / `votes` — split into two tables on purpose: `goal_votes` is a persistent "voting slot" (one per goal×voter), `votes` holds the actual YES/NO value and is deleted on vote cancellation while the slot stays. Don't collapse these without checking `docs/domain-model.md`'s "未解決の設計課題" section — it's a known, intentionally-deferred simplification.
- `messages` — comments on a goal.

Scoring/streak: see `docs/score-design.md` for the full formula (concrete-goal points, vague-goal points, full-participation bonus, missed-goal penalty, streak bonus) and its known limitations (missed-status is lazily recalculated only when someone votes; no `pg_cron` sweep exists yet).

## Conventions

- Commit messages and in-code comments are written in Japanese in this repo; match that when editing existing files.
- Comments in migrations tend to explain *why* a security/behavior change was made (see `0014_profiles_update_column_grant.sql`) — keep that standard for new migrations touching RLS/grants.
- ESLint: `@typescript-eslint/no-unused-vars` is a warning (prefix intentionally-unused args with `_`); `vue/multi-word-component-names` is off, so single-word component names are fine.
