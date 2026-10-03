# Campus Eco-Tracker (MVP v1)

Flutter + Supabase app for campus recycling, challenges, leaderboards and collection-point map.

## Setup

1. Apply SQL in Supabase SQL Editor:
   - `../supabase_schema.sql`
   - `../supabase_mvp_fixes.sql` (profile trigger + storage bucket)

2. Confirm `.env` in this folder:

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=your_publishable_or_anon_key
```

3. Run:

```bash
flutter pub get
flutter run -d chrome
```

## Features

- Email auth (login / register)
- Dashboard (points, CO2, weekly activity)
- Recycle Hub (QR Eco-ID, fraction stats, photo claims)
- Challenges + badges
- Leaderboard (students / groups / faculties)
- Campus map with collection points

## Test accounts

If seed data from SQL was applied:

- `ivanov@student.university.ru` / `EcoTest123!`
- Or register a new account from the login screen
