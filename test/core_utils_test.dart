import 'package:baytoti_vendor/core/mock/mock_session_token.dart';
import 'package:baytoti_vendor/core/utils/json_read.dart';
import 'package:baytoti_vendor/core/utils/money.dart';
import 'package:baytoti_vendor/core/widgets/caps_label.dart';
import 'package:baytoti_vendor/features/auth/domain/entities/auth_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('prints fils as three-decimal dinars with Western digits', () {
      expect(Money.amount(38750), '38.750');
      expect(Money.amount(4250), '4.250');
      expect(Money.amount(0), '0.000');
    });

    test('reads a typed amount back into fils', () {
      expect(Money.parseFils('4.5'), 4500);
      expect(Money.parseFils('12'), 12000);
      expect(Money.parseFils('0,750'), 750);
      expect(Money.parseFils('-1'), isNull);
      expect(Money.parseFils('abc'), isNull);
    });
  });

  group('json readers', () {
    test('take a value in whichever type the server sent it', () {
      expect(asInt('42'), 42);
      expect(asInt(4.6), 5);
      expect(asString(12), '12');
      expect(asString('  '), isNull);
      expect(asBool(1), isTrue);
      expect(asBool('false'), isFalse);
      expect(asDouble('4.9'), 4.9);
    });

    test('skip what is not an object in a list', () {
      expect(asMapList([{'a': 1}, 'x', null, {'b': 2}]), hasLength(2));
      expect(asMapList(null), isEmpty);
    });

    test('require names the missing field', () {
      expect(
        () => requireString(null, 'id'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('a fixture token names its account and reads back', () {
    const token = MockSessionToken(
      isNewFamily: true,
      phoneDigits: '96551502244',
      familyName: 'أسرة أم عبدالله',
    );

    final read = MockSessionToken.decode(token.encode())!;
    expect(read.isNewFamily, isTrue);
    expect(read.phoneDigits, '96551502244');
    expect(read.familyName, 'أسرة أم عبدالله');
    expect(MockSessionToken.decode('eyJ.real.jwt'), isNull);
  });

  test('a Kuwaiti number prints grouped, any other as it went out', () {
    expect(KuwaitPhone.display('+96551502244'), '+965 5150 2244');
    expect(KuwaitPhone.display('+201064780620'), '+201064780620');
  });

  test('only Latin labels are tracked and uppercased', () {
    expect(CapsLabel.isLatin('Customer'), isTrue);
    expect(CapsLabel.isLatin('العميل'), isFalse);
  });
}
