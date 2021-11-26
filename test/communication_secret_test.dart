import 'dart:math';

import 'package:collection/collection.dart';
import 'package:geiger_api/src/communication/communication_secret.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';

void main() {
  test('testConstructorGetterSetter', () {
    // default constructor
    for (int i = 0; i < 20; ++i) {
      final CommunicationSecret secret = CommunicationSecret.empty();
      expect(secret.getSecret(), isNotNull, reason: 'checking existence');
      expect(32, secret.getSecret().length, reason: 'checking size');
    }

    // constructor with size
    final List<int> sizes = [1, 5, 50, 250, 2600, 10000];
    for (final int size in sizes) {
      final CommunicationSecret secret2 = CommunicationSecret.empty(size);
      expect(secret2.getSecret(), isNotNull, reason: 'checking existence');
      expect(size, secret2.getSecret().length, reason: 'checking size');
    }

    // constructor with secret
    for (int i = 0; i < 20; ++i) {
      final List<int> sec = SerializerHelper.intToByteArray(
          Random.secure().nextInt(pow(2, 32).toInt()));
      final CommunicationSecret secret3 = CommunicationSecret(sec);
      expect(secret3.getSecret(), isNotNull, reason: 'checking existence');
      expect(sec.length, secret3.getSecret().length, reason: 'checking size');
      expect(const ListEquality<int>().equals(sec, secret3.getSecret()), true,
          reason: 'checking content');
    }
    // should be caught and generate a Randomsecret
    final List<int> value = [];
    final CommunicationSecret secret3b = CommunicationSecret(value);
    expect(secret3b.getSecret(), isNotNull, reason: 'checking existence');
    expect(32, secret3b.getSecret().length, reason: 'checking size');

    const List<int>? value2 = null;
    final CommunicationSecret secret3c = CommunicationSecret(value2);
    expect(secret3c.getSecret(), isNotNull, reason: 'checking existence');
    expect(32, secret3c.getSecret().length, reason: 'checking size');

    // setter
    for (int i = 0; i < 20; ++i) {
      final CommunicationSecret secret4 = CommunicationSecret.empty();
      final List<int> secretValue = secret4.getSecret();
      final List<int> newSecretValue = SerializerHelper.intToByteArray(
          Random.secure().nextInt(pow(2, 32).toInt()));
      secret4.setSecret(newSecretValue);
      expect(secret4.getSecret(), isNotNull, reason: 'checking existence');
      expect(const ListEquality<int>().equals(secretValue, secret4.getSecret()),
          false,
          reason: 'checking if secret changed');
      expect(
          const ListEquality<int>().equals(newSecretValue, secret4.getSecret()),
          true,
          reason: 'checking if secret is set correctly');
    }
    final List<int> value3 = [];
    final CommunicationSecret secret4b = CommunicationSecret.empty();
    final List<int> prevSecret = secret4b.getSecret();
    secret4b.setSecret(value3);
    expect(secret4b.getSecret(), isNotNull, reason: 'checking existence');
    expect(32, secret4b.getSecret().length, reason: 'checking size');
    expect(const ListEquality<int>().equals(prevSecret, secret4b.getSecret()),
        false,
        reason: 'checking if secret changed');

    const List<int>? value4 = null;
    final List<int> prevSecret2 = secret4b.getSecret();
    secret4b.setSecret(value4);
    expect(secret4b.getSecret(), isNotNull, reason: 'checking existence');
    expect(32, secret4b.getSecret().length, reason: 'checking size');
    expect(const ListEquality<int>().equals(prevSecret2, secret4b.getSecret()),
        false,
        reason: 'checking if secret changed');

    // negative tests
    // constructor with size
    final List<int> incorrectSizes = <int>[-1, -5, 0];
    for (final int size in incorrectSizes) {
      expect(
          () => CommunicationSecret.empty(size), throwsA(isA<ArgumentError>()));
    }
  });
}
