-- ═══════════════════════════════════════════════════════════════════
-- NOLDEX Fleet — Schéma complet (v3 — 25/05/2026 — sécurisé)
-- Exécuter dans : Supabase → SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. Galerie équipements ────────────────────────────────────────
create table if not exists nx_galerie (
  id         text primary key,
  public_id  text,
  nom        text not null,
  type       text,
  ville      text,
  statut     text default 'Disponible',
  cap        text,
  annee      text,
  marque     text,
  modele     text,
  prix       integer default 0,
  gps        boolean default false,
  descr      text,
  created_at timestamptz default now()
);

-- ── 2. Vidéos ────────────────────────────────────────────────────
create table if not exists nx_videos (
  id         text primary key,
  source     text default 'cloudinary',
  public_id  text,
  youtube_id text,
  title      text,
  type       text,
  descr      text,
  featured   boolean default false,
  ordre      integer default 0,
  lead_text  text,
  created_at timestamptz default now()
);

-- ── 3. Équipe — membres ──────────────────────────────────────────
create table if not exists nx_equipe (
  id         text primary key,
  public_id  text,
  nom        text not null,
  role       text,
  dept       text,
  dept_type  text,
  bio        text,
  tel        text,
  whatsapp   text,
  email      text,
  linkedin   text,
  location   text,
  is_pdg     boolean default false,
  ordre      integer default 0,
  enabled    boolean default true,
  created_at timestamptz default now()
);

-- ── 4. Valeurs de l'entreprise ───────────────────────────────────
-- NOTE : champ "descr" (pas "desc" — mot réservé SQL)
create table if not exists nx_valeurs (
  id    text primary key,
  icon  text,
  titre text,
  descr text,
  ordre integer default 0
);

-- ═══ RLS — Row Level Security ════════════════════════════════════
alter table nx_galerie enable row level security;
alter table nx_videos  enable row level security;
alter table nx_equipe  enable row level security;
alter table nx_valeurs enable row level security;

-- ── Lecture publique (site vitrine, clé anon) ─────────────────────
create policy "lecture publique" on nx_galerie for select using (true);
create policy "lecture publique" on nx_videos  for select using (true);
create policy "lecture publique" on nx_equipe  for select using (true);
create policy "lecture publique" on nx_valeurs for select using (true);

-- ── Écriture réservée aux utilisateurs authentifiés avec rôle admin ─
-- SÉCURITÉ : L'ancienne politique "ecriture anon" avec (true) permettait
-- à n'importe qui connaissant la clé anon d'écrire en base. Remplacée
-- par une vérification du rôle dans user_metadata Supabase.
-- Pour attribuer le rôle admin : Dashboard → Auth → Users → Edit →
--   user_metadata : {"role":"admin"}

create policy "ecriture admin" on nx_galerie
  for all
  using  ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' )
  with check ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' );

create policy "ecriture admin" on nx_videos
  for all
  using  ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' )
  with check ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' );

create policy "ecriture admin" on nx_equipe
  for all
  using  ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' )
  with check ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' );

create policy "ecriture admin" on nx_valeurs
  for all
  using  ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' )
  with check ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' );

-- ═══ Index utiles ════════════════════════════════════════════════
create index if not exists idx_nx_galerie_created  on nx_galerie (created_at);
create index if not exists idx_nx_videos_ordre     on nx_videos  (ordre);
create index if not exists idx_nx_equipe_ordre     on nx_equipe  (ordre);
create index if not exists idx_nx_valeurs_ordre    on nx_valeurs (ordre);

-- ═══ Migrations colonnes (si tables existantes) ══════════════════
alter table nx_videos add column if not exists lead_text text;
alter table nx_equipe add column if not exists dept_type text;

-- ═══ Suppression ancienne politique trop permissive ══════════════
-- À exécuter si vous migrez depuis le schéma v2 :
-- drop policy if exists "ecriture anon" on nx_galerie;
-- drop policy if exists "ecriture anon" on nx_videos;
-- drop policy if exists "ecriture anon" on nx_equipe;
-- drop policy if exists "ecriture anon" on nx_valeurs;

-- ═══════════════════════════════════════════════════════════════════
-- TABLES OPÉRATIONNELLES (back-office dashboard admin)
-- ═══════════════════════════════════════════════════════════════════

create table if not exists demandes_devis (
  id          text primary key default 'dv_' || extract(epoch from now())::text,
  type_engin  text,
  capacite    text,
  chantier    text,
  date_debut  date,
  duree       text,
  societe     text,
  nom         text not null,
  telephone   text not null,
  email       text,
  description text,
  statut      text default 'En attente',
  source      text default 'site_web',
  created_at  timestamptz default now()
);

create table if not exists engins      (id text primary key, nom text, type text, proprio text, ville text, cap text, prix numeric, statut text, gps boolean, emoji text, validated boolean, created_at timestamptz default now());
create table if not exists clients     (id text primary key, societe text, contact text, tel text, email text, secteur text, ville text, locations int default 0, total numeric default 0, statut text, created_at timestamptz default now());
create table if not exists contrats    (id text primary key, client text, "enginId" text, engin text, chantier text, debut text, fin text, montant numeric, statut text, created_at timestamptz default now());
create table if not exists demandes    (id text primary key, client text, engin text, chantier text, debut text, fin text, statut text, created_at timestamptz default now());
create table if not exists paiements   (id text primary key, "contratId" text, client text, montant numeric, date text, mode text, statut text, created_at timestamptz default now());
create table if not exists maintenance (id text primary key, "enginId" text, engin text, type text, description text, date text, cout numeric, statut text, created_at timestamptz default now());
create table if not exists partenaires (id text primary key, nom text, contact text, tel text, email text, ville text, engins int default 0, validated boolean default false, statut text default 'En attente', created_at timestamptz default now());
create table if not exists platform_params (id text primary key default 'main', nom text, email text, tel text, adresse text, commission numeric, "commPart" numeric, tva numeric, devise text, om text, mtn text, rib text, rccm text, nif text, site text);

-- ── RLS tables opérationnelles ────────────────────────────────────
alter table demandes_devis enable row level security;
alter table engins         enable row level security;
alter table clients        enable row level security;
alter table contrats       enable row level security;
alter table demandes       enable row level security;
alter table paiements      enable row level security;
alter table maintenance    enable row level security;
alter table partenaires    enable row level security;
alter table platform_params enable row level security;

-- Lecture publique pour demandes_devis (soumission depuis le site)
create policy "insert public" on demandes_devis
  for insert with check (true);

-- Lecture admin uniquement
create policy "lecture admin" on demandes_devis
  for select using ( auth.role() = 'authenticated' AND (auth.jwt()->'user_metadata'->>'role') = 'admin' );

-- Tables back-office : accès admin seulement
create policy "admin seulement" on engins      for all using ( (auth.jwt()->'user_metadata'->>'role') = 'admin' ) with check ( (auth.jwt()->'user_metadata'->>'role') = 'admin' );
create policy "admin seulement" on clients     for all using ( (auth.jwt()->'user_metadata'->>'role') = 'admin' ) with check ( (auth.jwt()->'user_metadata'->>'role') = 'admin' );
create policy "admin seulement" on contrats    for all using ( (auth.jwt()->'user_metadata'->>'role') = 'admin' ) with check ( (auth.jwt()->'user_metadata'->>'role') = 'admin' );
create policy "admin seulement" on demandes    for all using ( (auth.jwt()->'user_metadata'->>'role') = 'admin' ) with check ( (auth.jwt()->'user_metadata'->>'role') = 'admin' );
create policy "admin seulement" on paiements   for all using ( (auth.jwt()->'user_metadata'->>'role') = 'admin' ) with check ( (auth.jwt()->'user_metadata'->>'role') = 'admin' );
create policy "admin seulement" on maintenance for all using ( (auth.jwt()->'user_metadata'->>'role') = 'admin' ) with check ( (auth.jwt()->'user_metadata'->>'role') = 'admin' );
create policy "admin seulement" on partenaires for all using ( (auth.jwt()->'user_metadata'->>'role') = 'admin' ) with check ( (auth.jwt()->'user_metadata'->>'role') = 'admin' );
create policy "admin seulement" on platform_params for all using ( (auth.jwt()->'user_metadata'->>'role') = 'admin' ) with check ( (auth.jwt()->'user_metadata'->>'role') = 'admin' );

-- ── Index utiles ──────────────────────────────────────────────────
create index if not exists idx_demandes_devis_statut   on demandes_devis (statut);
create index if not exists idx_demandes_devis_created  on demandes_devis (created_at);
create index if not exists idx_contrats_enginId        on contrats ("enginId");
create index if not exists idx_paiements_contratId     on paiements ("contratId");
