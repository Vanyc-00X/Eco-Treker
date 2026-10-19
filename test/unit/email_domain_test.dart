import 'package:campus_eco_tracker/core/utils/email_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows any valid email', () {
    expect(EmailDomain.isAllowed('a@student.university.ru'), isTrue);
    expect(EmailDomain.isAllowed('a@gmail.com'), isTrue);
    expect(EmailDomain.isAllowed('user@mail.ru'), isTrue);
    expect(EmailDomain.validate('not-an-email'), isNotNull);
    expect(EmailDomain.validate(''), isNotNull);
  });
}
