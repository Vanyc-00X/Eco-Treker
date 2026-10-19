/// Лимиты OTP по ТЗ: 5 попыток, блок 15 мин, ресенд 60 с.
class OtpLimiter {
  OtpLimiter({
    this.maxAttempts = 5,
    this.lockDuration = const Duration(minutes: 15),
    this.resendCooldown = const Duration(seconds: 60),
  });

  final int maxAttempts;
  final Duration lockDuration;
  final Duration resendCooldown;

  int attempts = 0;
  DateTime? lockedUntil;
  DateTime? lastSentAt;

  bool get isLocked {
    final until = lockedUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    lockedUntil = null;
    attempts = 0;
    return false;
  }

  Duration? get lockRemaining {
    final until = lockedUntil;
    if (until == null) return null;
    final d = until.difference(DateTime.now());
    return d.isNegative ? null : d;
  }

  bool get canResend {
    final last = lastSentAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= resendCooldown;
  }

  Duration get resendRemaining {
    final last = lastSentAt;
    if (last == null) return Duration.zero;
    final d = resendCooldown - DateTime.now().difference(last);
    return d.isNegative ? Duration.zero : d;
  }

  void markSent() {
    lastSentAt = DateTime.now();
  }

  /// true если попытка принята, false если заблокировано.
  bool registerAttempt({required bool success}) {
    if (isLocked) return false;
    if (success) {
      attempts = 0;
      lockedUntil = null;
      return true;
    }
    attempts++;
    if (attempts >= maxAttempts) {
      lockedUntil = DateTime.now().add(lockDuration);
    }
    return !isLocked;
  }
}
