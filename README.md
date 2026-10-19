# Campus Eco-Tracker (v1.0.0 — TZ 1A)

Flutter + Supabase: сдача вторсырья, челленджи, рейтинг, карта, роли student / volunteer / admin.

## Setup

1. В Supabase SQL Editor выполните **один** файл (полный сброс + схема):
   - [`supabase/migrations/20260401_tz_full.sql`](supabase/migrations/20260401_tz_full.sql)
   - При предупреждении: **Run without RLS** (RLS уже внутри скрипта)
   - Старые таблицы приложения будут удалены и созданы заново (`auth.users` сохраняются)

2. Скопируйте `.env.example` → `.env`:

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=your_publishable_or_anon_key
```

3. (Опционально) Phone Auth: включите SMS-провайдер в Supabase Auth. Без него UI телефона покажет ошибку с подсказкой.

4. Задайте роли тестовым пользователям в `profiles.role`: `student` | `volunteer` | `admin`.

5. Запуск:

```bash
flutter pub get
flutter run
```

Регистрация с любого email (gmail, mail.ru и т.д.).

### Авторизация (почта + телефон)

1. Обязательно выполните SQL: [`supabase/migrations/20260403_fix_auth.sql`](supabase/migrations/20260403_fix_auth.sql)  
   (чинит `Database error saving new user` и включает OTP по телефону без Twilio)
2. **Email:** регистрация/вход любым адресом. Письма: SMTP в Supabase Auth. Баннер «Подтвердите почту!» каждые 10 мин.
3. **Телефон:** без SMS-провайдера код показывается в SnackBar → вводите → вход. С Twilio можно включить Phone в Auth — тогда уйдёт SMS.

## Роли

| Роль | UI |
|------|-----|
| student | 5 вкладок (главная, сдача, челленджи, рейтинг, карта) |
| volunteer | `/volunteer` — скан QR, модерация заявок и пруфов |
| admin | `/admin` — аналитика, юзеры, челленджи, пункты, обмены/жалобы |

Ссылки на панели также в **Настройки**.

## Features (покрытие ТЗ)

См. [`docs/tz-coverage.md`](docs/tz-coverage.md).

Кратко:
- Auth: домен вуза, phone OTP UI, SSO-заглушка, пароль по ТЗ, delete/logout everywhere, 2FA-флаг
- Сдача: QR каждые 30 с, калькулятор множителей, GPS-заявка, CSV, dispute
- Волонтёр: скан, подтверждение веса, квитанция, модерация
- Челленджи: seasonal/special, share, abandon, фото-пруф
- Рейтинг: метрики и периоды
- Карта OSM: цветные маркеры, фильтры, избранное
- IoT / SSO — явные заглушки (план 1A)

## Tests & CI

```bash
flutter analyze
flutter test
```

GitHub Actions: `.github/workflows/ci.yml`.
