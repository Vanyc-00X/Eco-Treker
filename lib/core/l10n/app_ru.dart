/// Централизованные строки UI (русский).
abstract final class AppRu {
  static const appTitle = 'Campus Eco-Tracker';

  static const navDashboard = 'Главная';
  static const navRecycle = 'Сдача';
  static const navChallenges = 'Челленджи';
  static const navLeaderboard = 'Рейтинг';
  static const navMap = 'Карта';
  static const navWork = 'Работа';
  static const staffWorkSubtitle =
      'Подтверждайте сдачи, начисляйте баллы и ведите очередь';
  static const staffAccessDenied =
      'Эта вкладка доступна только волонтёрам и администраторам.';
  static const scanQrShort = 'Скан';
  static const moderateClaimsShort = 'Заявки';
  static const moderateProofs = 'Пруфы';
  static const adminHubShort = 'Админ';

  static const retry = 'Повторить';
  static const profileNotFound = 'Профиль не найден';
  static const loading = 'Загрузка…';

  // Auth
  static const authSubtitleLogin = 'Войдите, чтобы отслеживать переработку';
  static const authSubtitleRegister = 'Создайте эко-аккаунт';
  static const fullName = 'ФИО';
  static const email = 'Email';
  static const password = 'Пароль';
  static const requiredField = 'Обязательное поле';
  static const invalidEmail = 'Некорректный email';
  static const minPassword = 'Минимум 8 символов';
  static const signIn = 'Войти';
  static const createAccount = 'Создать аккаунт';
  static const alreadyHaveAccount = 'Уже есть аккаунт? Войти';
  static const newHere = 'Нет аккаунта? Зарегистрироваться';
  static const confirmEmailThenSignIn =
      'Аккаунт создан. Письмо отправлено — можно войти. Подтвердите почту, когда будет удобно.';
  static const confirmEmailBanner = 'Подтвердите почту!';
  static const resendConfirmEmail = 'Отправить письмо ещё раз';
  static const confirmEmailResent = 'Письмо отправлено повторно. Проверьте «Спам».';
  static const confirmEmailResendFailed = 'Не удалось отправить письмо';
  static const emailNotConfirmedHint =
      'Email ещё не подтверждён. Можно пользоваться приложением — периодически напомним.';
  static const invalidCredentialsHint =
      'Неверный email или пароль. Если только зарегистрировались — сначала «Создать аккаунт».';
  static const emailRateLimit =
      'Лимит отправки email. Подождите ~1 час или войдите, если аккаунт уже есть.';
  static const profileRlsBlocked =
      'RLS блокирует профиль. Попросите админа применить SQL-миграции.';
  static const groupName = 'Учебная группа';
  static const facultyName = 'Факультет / институт';
  static const consentPrivacy = 'Согласие на обработку персональных данных';
  static const consentTos = 'Согласие с пользовательским соглашением';
  static const acceptConsents = 'Примите согласия для регистрации';
  static const phoneTab = 'Телефон';
  static const emailTab = 'Email';
  static const sendOtp = 'Отправить код';
  static const verifyOtp = 'Подтвердить код';
  static const otpCode = 'Код из SMS';
  static const otpResendIn = 'Повтор через';
  static const otpLocked = 'Слишком много попыток. Подождите 15 минут.';
  static const ssoButton = 'Войти через вуз (SSO)';
  static const ssoStubBody =
      'Интеграция с IdP вуза готовится. Используйте email или телефон.';
  static const mockPhoneHint =
      'Код придёт на экран (SMS-провайдер не настроен). Введите его и нажмите «Подтвердить».';
  static const otpDevCodeShown = 'Ваш код для входа';
  static const otpSmsSent = 'SMS с кодом отправлено';
  static const databaseErrorSavingUser =
      'Ошибка БД при создании пользователя. Выполните SQL 20260403_fix_auth.sql в Supabase.';
  static const language = 'Язык';
  static const privacy = 'Приватность';
  static const notifications = 'Уведомления';
  static const deleteAccount = 'Удалить аккаунт';
  static const deleteAccountConfirm =
      'Аккаунт будет анонимизирован. Данные хранятся 30 дней для восстановления.';
  static const logoutEverywhere = 'Выйти со всех устройств';
  static const enable2fa = 'Двухфакторная защита';
  static const tos = 'Пользовательское соглашение';
  static const privacyPolicy = 'Политика конфиденциальности';
  static const support = 'Поддержка';
  static const rateApp = 'Оценить приложение';
  static const showInLeaderboard = 'Показывать в рейтинге';
  static const profilePublic = 'Публичный профиль';
  static const dateOfBirth = 'Дата рождения';
  static const accentColor = 'Акцентный цвет';
  static const volunteerHub = 'Панель волонтёра';
  static const adminHub = 'Панель администратора';
  static const scanQr = 'Сканировать QR';
  static const moderateClaims = 'Модерация заявок';
  static const confirmDropoff = 'Подтвердить сдачу';
  static const receipt = 'Квитанция';
  static const calculatePreview = 'Предварительный расчёт';
  static const disputePoints = 'Оспорить начисление';
  static const exportCsv = 'Экспорт CSV';
  static const abandonChallenge = 'Отказаться';
  static const share = 'Поделиться';
  static const uploadProof = 'Фото-подтверждение';
  static const favorites = 'Избранное';
  static const iotStub = 'Умные контейнеры — скоро';
  static const periodWeek = 'Неделя';
  static const periodMonth = 'Месяц';
  static const periodSemester = 'Семестр';
  static const periodYear = 'Год';
  static const periodAll = 'Всё время';
  static const metricPoints = 'Баллы';
  static const metricKg = 'Сырьё';
  static const metricCo2 = 'CO₂';
  static const metricChallenges = 'Челленджи';

  // Dashboard
  static const greenPointsBalance = 'БАЛАНС GREEN POINTS';
  static const redeem = 'Обменять';
  static const co2Saved = 'CO₂ сохранено';
  static const recycled = 'Сдано';
  static const activeStreak = 'Серия дней';
  static const daysUnit = 'дн.';
  static const weeklyActivity = 'Активность за неделю';
  static const kgRecycled = 'кг сдано';
  static const tipRinse =
      'Совет: споласкивайте бутылки перед сдачей — волонтёрам проще проверить заявку.';
  static const noData = 'Нет данных';
  static const redeemTitle = 'Обмен баллов';
  static const redeemSubtitle = 'Выберите награду — заявка уйдёт операторам кампуса';
  static const redeemSuccess = 'Заявка на обмен отправлена';
  static const redeemNotEnough = 'Недостаточно баллов';
  static const redeemFailed = 'Не удалось обменять баллы';
  static const cancel = 'Отмена';
  static const confirm = 'Подтвердить';

  // Recycle
  static const recycleHub = 'Центр сдачи';
  static const recycleHubSubtitle =
      'Покажите QR-код на пункте сбора кампуса';
  static const personalEcoId = 'Личный Eco-ID';
  static const myEcoId = 'МОЙ ECO-ID';
  static const scanForProfile = 'СКАНИРОВАТЬ ПРОФИЛЬ';
  static const holdQr = 'Поднесите QR-код к сканеру.';
  static const rotateQr = 'Обновить QR';
  static const qrRotated = 'QR-код обновлён';
  static const qrMissing = 'Не удалось получить Eco-ID. Нажмите «Обновить QR».';
  static const yourRecycled = 'Ваша переработка';
  static const plastic = 'Пластик';
  static const paper = 'Бумага';
  static const metal = 'Металл';
  static const glass = 'Стекло';
  static const batteries = 'Батарейки';
  static const uploadPhoto = 'Загрузить фото на проверку';
  static const recentDeposits = 'Недавние сдачи';
  static const noDeposits =
      'Пока нет сдач. Загрузите фото, чтобы начать.';
  static const failedStats = 'Не удалось загрузить статистику';
  static const verified = 'Проверено';
  static const pending = 'На проверке';
  static const pointsShort = 'б.';

  // Upload
  static const photoClaim = 'Фото-заявка';
  static const tapChoosePhoto = 'Выберите фото';
  static const takePhoto = 'Сделать фото';
  static const chooseGallery = 'Выбрать из галереи';
  static const category = 'Категория';
  static const weightKg = 'Вес (кг)';
  static const weightHint = 'например 2.5';
  static const collectionPoint = 'Пункт сбора';
  static const notSpecified = 'Не указан';
  static const pointsUnavailable = 'Пункты недоступны';
  static const note = 'Комментарий';
  static const noteHint = 'Необязательно — для волонтёра';
  static const submitClaim = 'Отправить заявку';
  static const selectCategoryWeight =
      'Выберите категорию и укажите корректный вес';
  static const attachPhoto = 'Прикрепите фото';
  static const claimSubmitted = 'Заявка отправлена на проверку';
  static const submitFailed = 'Ошибка отправки';
  static const maxWeight = 'Максимальный вес за одну заявку — 50 кг';

  // Challenges
  static const activeChallenges = 'Активные челленджи';
  static const challengesSubtitle =
      'Соревнуйтесь с друзьями и получайте бейджи';
  static const earnedBadges = 'Полученные бейджи';
  static const noBadges = 'Бейджей пока нет — завершите челлендж!';
  static const earnedOn = 'Получен';
  static const percentComplete = 'выполнено';
  static const joined = 'Участвуете';
  static const notJoined = 'Не участвуете';
  static const takeChallenge = 'Принять челлендж';
  static const daysLeft = 'дн. осталось';
  static const hoursLeft = 'ч осталось';
  static const minutesLeft = 'мин осталось';
  static const typeTeam = 'Команда факультета';
  static const typeDaily = 'Ежедневный';
  static const typeWeekly = 'Еженедельный';
  static const typeIndividual = 'Индивидуальный';

  // Leaderboard
  static const ecoLeaderboard = 'Эко-рейтинг';
  static const leaderboardSubtitle = 'Сравните себя с кампусом';
  static const students = 'Студенты';
  static const groups = 'Группы';
  static const faculties = 'Факультеты';
  static const leaderboardEmpty = 'Рейтинг пока пуст.';
  static const you = 'Вы';

  // Map
  static const searchStations = 'Поиск пунктов переработки…';
  static const allBins = 'Все';
  static const specialty = 'Особые';
  static const recycles = 'Принимает';
  static const fillCapacity = 'Заполненность';
  static const percentFull = '% заполнено';
  static const getDirections = 'Маршрут';
  static const reportFullBin = 'Сообщить: контейнер полон';
  static const reportSent = 'Жалоба отправлена эко-операторам';
  static const reportFailed = 'Не удалось отправить жалобу';
  static const reportNoteHint = 'Комментарий (необязательно)';

  // Levels
  static const levelNovice = 'Эко-новичок';
  static const levelKeeper = 'Хранитель леса';
  static const levelMaster = 'Эко-мастер';

  // Auth extras
  static const forgotPassword = 'Забыли пароль?';
  static const resetSent = 'Письмо для сброса пароля отправлено';
  static const resetFailed = 'Не удалось отправить письмо';
  static const versionLabel = 'Версия 1.0.0';
  static const welcomeBack = 'С возвращением';

  // Onboarding
  static const onboardingSkip = 'Пропустить';
  static const onboardingNext = 'Далее';
  static const onboardingStart = 'Начать';
  static const onboarding1Title = 'Сдавайте отходы на кампусе';
  static const onboarding1Body =
      'Фото-заявка или QR Eco-ID — баллы и CO₂ учитываются автоматически.';
  static const onboarding2Title = 'Соревнуйтесь и растите серию';
  static const onboarding2Body =
      'Челленджи, бейджи и рейтинг факультетов — эко-привычка становится игрой.';
  static const onboarding3Title = 'Меняйте баллы на награды';
  static const onboarding3Body =
      'Кофе, эко-сумки и мерч кампуса — за реальную переработку.';

  // Profile / settings
  static const settings = 'Настройки';
  static const editProfile = 'Редактировать профиль';
  static const profileSaved = 'Профиль сохранён';
  static const profileSaveFailed = 'Не удалось сохранить профиль';
  static const phone = 'Телефон';
  static const course = 'Курс';
  static const save = 'Сохранить';
  static const about = 'О приложении';
  static const aboutBody =
      'Campus Eco-Tracker 1.0.0 — экосистема кампусной переработки: сдача, челленджи, рейтинг и карта пунктов.';
  static const theme = 'Тема';
  static const themeSystem = 'Системная';
  static const themeLight = 'Светлая';
  static const themeDark = 'Тёмная';
  static const showOnboarding = 'Показать обучение';
  static const logout = 'Выйти';
  static const logoutConfirm = 'Выйти из аккаунта?';
  static const activity = 'Лента';
  static const activitySubtitle = 'Сдачи, обмены и жалобы';
  static const activityEmpty = 'Пока нет событий';
  static const activityEmptyHint = 'Сдайте отходы или обменяйте баллы';
  static const redeemHistory = 'История обменов';
  static const redeemHistoryEmpty = 'Обменов пока не было';
  static const tipOfDay = 'Совет дня';
  static const copyEcoId = 'Скопировать Eco-ID';
  static const copied = 'Скопировано';
  static const impactTitle = 'Ваш вклад';
  static const treesEquiv = '≈ деревьев';
  static const filterAll = 'Все';
  static const noChallenges = 'Челленджей пока нет';
  static const noChallengesHint = 'Загляните позже — новые появятся скоро';
  static const noMapResults = 'Ничего не найдено';
  static const noMapResultsHint = 'Сбросьте фильтр или измените поиск';
  static const claimSuccessTitle = 'Заявка принята!';
  static const claimSuccessBody =
      'Волонтёры проверят фото. Баллы начислятся после подтверждения.';
  static const toRecycle = 'К сдаче';
  static const pageNotFound = 'Страница не найдена';
  static const goHome = 'На главную';
  static const streakGoal = 'Цель серии: 7 дней';
  static const filterTeam = 'Команда';
  static const rewardsTab = 'Награды';
  static const refresh = 'Обновить';
  static const editProfileHint = 'Открыть редактирование профиля';
  static const impactBody = 'Эквивалент поглощения CO₂ деревьями за год';
  static const navSelected = 'выбрано';
}