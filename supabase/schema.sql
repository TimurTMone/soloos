-- ============================================================================
-- Solo OS — Supabase Database Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ============================================================================

-- ── Profiles ────────────────────────────────────────────────────────────────

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  api_key text default '',
  locale text default 'en',
  onboarding_done boolean default false,
  last_ai_digest text default '',
  last_digest_date text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table profiles enable row level security;
create policy "Users can read own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on profiles for insert with check (auth.uid() = id);

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ── Projects ────────────────────────────────────────────────────────────────

create table if not exists projects (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text default '',
  color integer default 3900860, -- 0xFF3B82F6
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_projects_user on projects(user_id);
alter table projects enable row level security;
create policy "Users own projects" on projects for all using (auth.uid() = user_id);

-- ── Tasks ───────────────────────────────────────────────────────────────────

create table if not exists tasks (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id text references projects(id) on delete cascade,
  title text not null,
  notes text default '',
  is_done boolean default false,
  priority text default 'medium',
  due_date timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_tasks_user on tasks(user_id);
create index idx_tasks_project on tasks(project_id);
alter table tasks enable row level security;
create policy "Users own tasks" on tasks for all using (auth.uid() = user_id);

-- ── Habits ──────────────────────────────────────────────────────────────────

create table if not exists habits (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  emoji text default '✅',
  frequency text default 'daily',
  color integer default 1096577, -- 0xFF10B981
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_habits_user on habits(user_id);
alter table habits enable row level security;
create policy "Users own habits" on habits for all using (auth.uid() = user_id);

-- Habit completions (normalized — no more JSON array)
create table if not exists habit_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id text not null references habits(id) on delete cascade,
  completed_date date not null,
  created_at timestamptz default now(),
  unique(habit_id, completed_date)
);

create index idx_habit_completions_user on habit_completions(user_id);
create index idx_habit_completions_habit on habit_completions(habit_id);
alter table habit_completions enable row level security;
create policy "Users own completions" on habit_completions for all using (auth.uid() = user_id);

-- ── Standup Logs ────────────────────────────────────────────────────────────

create table if not exists standup_logs (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date timestamptz default now(),
  wins text default '',
  challenges text default '',
  priorities text default '',
  ai_response text default '',
  created_at timestamptz default now()
);

create index idx_standups_user on standup_logs(user_id);
alter table standup_logs enable row level security;
create policy "Users own standups" on standup_logs for all using (auth.uid() = user_id);

-- ── Ideas ───────────────────────────────────────────────────────────────────

create table if not exists ideas (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text default '',
  status text default 'active', -- active, archived, completed
  notes jsonb default '[]'::jsonb,
  ai_script text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_ideas_user on ideas(user_id);
alter table ideas enable row level security;
create policy "Users own ideas" on ideas for all using (auth.uid() = user_id);

-- ── Contacts (birthday tracking) ────────────────────────────────────────────

create table if not exists contacts (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  emoji text default '👤',
  birthday timestamptz not null,
  relationship text default 'friend',
  notes text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_contacts_user on contacts(user_id);
alter table contacts enable row level security;
create policy "Users own contacts" on contacts for all using (auth.uid() = user_id);

-- ── Finance: Debts ──────────────────────────────────────────────────────────

create table if not exists debts (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  creditor_name text default '',
  category text default 'other',
  original_amount double precision not null,
  remaining_amount double precision not null,
  currency text default 'USD',
  due_date timestamptz,
  monthly_payment_goal double precision,
  priority text default 'medium',
  status text default 'active',
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_debts_user on debts(user_id);
alter table debts enable row level security;
create policy "Users own debts" on debts for all using (auth.uid() = user_id);

-- ── Finance: Obligations ────────────────────────────────────────────────────

create table if not exists obligations (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  category text default 'other',
  amount double precision not null,
  currency text default 'USD',
  frequency text default 'monthly',
  due_day_of_month integer,
  is_active boolean default true,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_obligations_user on obligations(user_id);
alter table obligations enable row level security;
create policy "Users own obligations" on obligations for all using (auth.uid() = user_id);

-- ── Finance: Income Streams ─────────────────────────────────────────────────

create table if not exists income_streams (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  category text default 'other',
  amount double precision not null,
  currency text default 'USD',
  frequency text default 'monthly',
  is_one_time boolean default false,
  date timestamptz,
  is_active boolean default true,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_income_streams_user on income_streams(user_id);
alter table income_streams enable row level security;
create policy "Users own income_streams" on income_streams for all using (auth.uid() = user_id);

-- ── Finance: Expenses ───────────────────────────────────────────────────────

create table if not exists expenses (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  amount double precision not null,
  currency text default 'USD',
  category text default 'other',
  date timestamptz default now(),
  notes text,
  created_at timestamptz default now()
);

create index idx_expenses_user on expenses(user_id);
alter table expenses enable row level security;
create policy "Users own expenses" on expenses for all using (auth.uid() = user_id);

-- ── Family: People ──────────────────────────────────────────────────────────

create table if not exists family_people (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  full_name text not null,
  relationship_type text not null,
  nickname text,
  birthday timestamptz,
  phone text,
  email text,
  notes_summary text default '',
  last_contact_at timestamptz,
  contact_frequency_goal_days integer,
  priority_level text default 'medium',
  tags jsonb default '[]'::jsonb,
  favorite_things jsonb default '[]'::jsonb,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_family_people_user on family_people(user_id);
alter table family_people enable row level security;
create policy "Users own family_people" on family_people for all using (auth.uid() = user_id);

-- ── Family: Reminders ───────────────────────────────────────────────────────

create table if not exists family_reminders (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  person_id text references family_people(id) on delete cascade,
  title text not null,
  description text,
  reminder_type text not null,
  due_at timestamptz not null,
  is_completed boolean default false,
  recurrence_type text default 'none',
  completed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_family_reminders_user on family_reminders(user_id);
create index idx_family_reminders_person on family_reminders(person_id);
alter table family_reminders enable row level security;
create policy "Users own family_reminders" on family_reminders for all using (auth.uid() = user_id);

-- ── Family: Relationship Notes ──────────────────────────────────────────────

create table if not exists relationship_notes (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  person_id text references family_people(id) on delete cascade,
  content text not null,
  note_type text default 'general',
  created_at timestamptz default now()
);

create index idx_relationship_notes_user on relationship_notes(user_id);
create index idx_relationship_notes_person on relationship_notes(person_id);
alter table relationship_notes enable row level security;
create policy "Users own relationship_notes" on relationship_notes for all using (auth.uid() = user_id);

-- ── Gamification: Events ────────────────────────────────────────────────────

create table if not exists gamification_events (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  event_type text not null,
  points double precision not null,
  occurred_at timestamptz not null,
  description text,
  created_at timestamptz default now()
);

create index idx_gam_events_user on gamification_events(user_id);
create index idx_gam_events_date on gamification_events(occurred_at);
alter table gamification_events enable row level security;
create policy "Users own gam_events" on gamification_events for all using (auth.uid() = user_id);

-- ── Gamification: Daily Scores ──────────────────────────────────────────────

create table if not exists daily_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  total_score integer not null,
  category_scores jsonb default '{}'::jsonb,
  xp_earned integer default 0,
  event_ids jsonb default '[]'::jsonb,
  created_at timestamptz default now(),
  unique(user_id, date)
);

create index idx_daily_scores_user on daily_scores(user_id);
alter table daily_scores enable row level security;
create policy "Users own daily_scores" on daily_scores for all using (auth.uid() = user_id);

-- ── Gamification: Streaks ───────────────────────────────────────────────────

create table if not exists streaks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  current_streak integer default 0,
  longest_streak integer default 0,
  last_activity_date date,
  is_broken boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, category)
);

create index idx_streaks_user on streaks(user_id);
alter table streaks enable row level security;
create policy "Users own streaks" on streaks for all using (auth.uid() = user_id);

-- ── Gamification: Daily Missions ────────────────────────────────────────────

create table if not exists daily_missions (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text default '',
  category text not null,
  difficulty text default 'medium',
  xp_reward integer default 0,
  is_completed boolean default false,
  date date not null,
  trigger_event_type text,
  created_at timestamptz default now()
);

create index idx_daily_missions_user on daily_missions(user_id);
alter table daily_missions enable row level security;
create policy "Users own daily_missions" on daily_missions for all using (auth.uid() = user_id);

-- ── Gamification: AI Coach Suggestions ──────────────────────────────────────

create table if not exists ai_coach_suggestions (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  message text not null,
  tone text default 'neutral',
  focus_category text,
  is_dismissed boolean default false,
  created_at timestamptz default now()
);

create index idx_ai_coach_user on ai_coach_suggestions(user_id);
alter table ai_coach_suggestions enable row level security;
create policy "Users own ai_coach_suggestions" on ai_coach_suggestions for all using (auth.uid() = user_id);

-- ── Gamification: User Progress ─────────────────────────────────────────────

create table if not exists user_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  total_xp integer default 0,
  level integer default 1,
  xp_to_next_level integer default 500,
  last_updated timestamptz default now()
);

alter table user_progress enable row level security;
create policy "Users own user_progress" on user_progress for all using (auth.uid() = user_id);

-- ── Updated_at trigger ──────────────────────────────────────────────────────

create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Apply to all tables with updated_at
do $$
declare
  t text;
begin
  for t in
    select unnest(array[
      'profiles', 'projects', 'tasks', 'habits', 'ideas', 'contacts',
      'debts', 'obligations', 'income_streams', 'family_people',
      'family_reminders', 'streaks'
    ])
  loop
    execute format(
      'drop trigger if exists set_updated_at on %I; create trigger set_updated_at before update on %I for each row execute procedure update_updated_at();',
      t, t
    );
  end loop;
end;
$$;
