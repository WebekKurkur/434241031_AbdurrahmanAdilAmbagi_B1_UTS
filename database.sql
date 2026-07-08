-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username text NOT NULL UNIQUE,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  role text NOT NULL CHECK (role = ANY (ARRAY['user'::text, 'helpdesk'::text, 'admin'::text])),
  department text NOT NULL DEFAULT ''::text,
  avatar_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.tickets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_code text NOT NULL UNIQUE,
  title text NOT NULL,
  description text NOT NULL,
  status text NOT NULL DEFAULT 'open'::text CHECK (status = ANY (ARRAY['open'::text, 'assigned'::text, 'inProgress'::text, 'closed'::text])),
  category text NOT NULL DEFAULT 'General'::text,
  image_url text,
  created_by uuid NOT NULL,
  assigned_to uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT tickets_pkey PRIMARY KEY (id),
  CONSTRAINT tickets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id),
  CONSTRAINT tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id)
);
CREATE TABLE public.comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL,
  author_id uuid NOT NULL,
  message text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT comments_pkey PRIMARY KEY (id),
  CONSTRAINT comments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id),
  CONSTRAINT comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.ticket_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL,
  actor_id uuid,
  action text NOT NULL CHECK (action = ANY (ARRAY['created'::text, 'assigned'::text, 'status_changed'::text, 'commented'::text, 'closed'::text])),
  from_value text,
  to_value text,
  note text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ticket_history_pkey PRIMARY KEY (id),
  CONSTRAINT ticket_history_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id),
  CONSTRAINT ticket_history_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  ticket_id uuid NOT NULL,
  actor_id uuid,
  type text NOT NULL CHECK (type = ANY (ARRAY['assigned'::text, 'status_changed'::text, 'commented'::text, 'closed'::text])),
  title text NOT NULL,
  body text NOT NULL,
  read_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT notifications_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id),
  CONSTRAINT notifications_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.profiles(id)
);

INSERT INTO public.profiles (id, username, name, email, role, department, avatar_url, created_at, is_active)
VALUES 
-- 1. Profile Admin
('0595797d-8f4b-4763-928a-a9cac7b1675c', 'admin', 'Citra Dewi', 'admin@example.com', 'admin', 'IT Management', NULL, '2026-06-04 09:34:17.732074+00', true),

-- 2. Profile User
('09bbfdb1-99d4-46f8-b22c-b81b8c362ea0', 'user', 'Ahmad Rizki', 'user@example.com', 'user', 'Finance', NULL, '2026-06-04 09:33:25.743475+00', true),

-- 3. Profile Helpdesk
('d3265401-4683-4d99-a6bd-0196cb1cd11a', 'helpdesk', 'Budi Santoso', 'helpdesk@example.com', 'helpdesk', 'IT Support', NULL, '2026-06-04 09:33:55.174922+00', true);