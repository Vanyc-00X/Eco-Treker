# Покрытие ТЗ (вариант 1A + 2A)

Миграции: `supabase/migrations/20260324_mvp_features.sql`, `supabase/migrations/20260401_tz_full.sql`.

| Раздел ТЗ | Статус | Реализация |
|-----------|--------|------------|
| 2.1 Email (любой адрес) | DONE | `email_domain.dart`, `login_screen.dart` |
| 2.1 Phone OTP + лимиты | DONE | UI + `OtpLimiter`; SMS через Supabase Phone Auth |
| 2.1 SSO вуза | STUB | Кнопка + диалог «готовится» |
| 2.1 Пароль / reset / 2FA-флаг / delete | DONE | `PasswordValidator`, settings, `soft_delete_account` |
| 2.1 Профиль / настройки / RU-EN / About | DONE | edit profile, settings, legal screens |
| 2.2 Категории + коэффициенты | DONE | SQL seeds + `waste_subcategories` |
| 2.2 QR 30с + скан оператора | DONE | Timer в recycle + volunteer scan |
| 2.2 Фото-заявка + GPS + модерация | DONE | upload + volunteer moderate |
| 2.2 Калькулятор / dispute / CSV | DONE | `PointsCalculator`, disputes, export |
| 2.2 IoT | STUB | Карточка «скоро» |
| 2.3 Челленджи + пруфы + ачивки | DONE | types, share, abandon, proofs, seeds |
| 2.4 Рейтинг метрики/периоды | DONE | RPC + UI chips |
| 2.5 Карта OSM + цвета + избранное | DONE | flutter_map, filters, favorites |
| 2.5 Офлайн MBTiles | PARTIAL | OSM online; кэш ОС/браузера |
| Роли volunteer / admin | DONE | `/volunteer`, `/admin` |
| Онбординг / streak / CI | DONE | как в v1.0 |

## Заглушки (явно по 1A)
- Реальный SSO IdP вуза
- Реальные IoT-датчики
- Яндекс/Google Maps SDK (остаётся OSM)
- SMS без настроенного провайдера в Supabase
