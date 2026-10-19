import 'package:campus_eco_tracker/core/utils/otp_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('locks after 5 failed attempts', () {
    final limiter = OtpLimiter(
      maxAttempts: 5,
      lockDuration: const Duration(minutes: 15),
    );
    for (var i = 0; i < 4; i++) {
      expect(limiter.registerAttempt(success: false), isTrue);
    }
    expect(limiter.registerAttempt(success: false), isFalse);
    expect(limiter.isLocked, isTrue);
  });

  test('resend cooldown', () {
    final limiter = OtpLimiter(resendCooldown: const Duration(seconds: 60));
    expect(limiter.canResend, isTrue);
    limiter.markSent();
    expect(limiter.canResend, isFalse);
  });
}
