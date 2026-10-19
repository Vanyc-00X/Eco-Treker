-- Позволяет входить без ручного подтверждения email,
-- при этом письмо подтверждения всё ещё уходит (если Confirm email включён + SMTP).
-- Триггер сразу помечает email подтверждённым в auth.users.

create or replace function public.auto_confirm_auth_user()
returns trigger
language plpgsql
security definer
set search_path = auth, public
as $$
begin
  -- Только email_confirmed_at (confirmed_at часто generated / read-only).
  update auth.users
  set email_confirmed_at = coalesce(email_confirmed_at, now())
  where id = new.id
    and email_confirmed_at is null;
  return new;
end;
$$;

drop trigger if exists on_auth_user_auto_confirm on auth.users;
create trigger on_auth_user_auto_confirm
  after insert on auth.users
  for each row
  execute function public.auto_confirm_auth_user();

-- Подтвердить уже существующих пользователей (чтобы могли войти сейчас)
update auth.users
set email_confirmed_at = coalesce(email_confirmed_at, now())
where email_confirmed_at is null;

select 'email auto-confirm ready' as status;
