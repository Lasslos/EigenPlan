import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';

void main() {
  test('TimetableResourceRef.own resolves userData.type/.id/.displayName', () {
    final school = School.fromJson(loadFixtureMap('school.json'));
    final userData = UserData.fromJson(loadFixtureMap('user_data.json'));
    final session =
        UntisSession.active(
              school,
              LoginMode.anonymous,
              null,
              null,
              null,
              userData,
            )
            as ActiveUntisSession;

    final own = TimetableResourceRef.own(session);

    expect(own!.resourceType, userData.type);
    expect(own.resourceId, userData.id);
    expect(own.displayName, userData.displayName);
  });

  test('TimetableResourceRef.own returns null when userData.type is null', () {
    final school = School.fromJson(loadFixtureMap('school.json'));
    final userDataJson = loadFixtureMap('user_data.json');
    (userDataJson['userData'] as Map<String, dynamic>)['elemType'] = null;
    final userData = UserData.fromJson(userDataJson);
    final session =
        UntisSession.active(
              school,
              LoginMode.anonymous,
              null,
              null,
              null,
              userData,
            )
            as ActiveUntisSession;

    expect(TimetableResourceRef.own(session), isNull);
  });

  test('storageKey combines resourceType and resourceId', () {
    const resource = TimetableResourceRef(resourceType: 'CLASS', resourceId: 5);

    expect(resource.storageKey, 'CLASS:5');
  });

  test('storageKey ignores displayName', () {
    const a = TimetableResourceRef(
      resourceType: 'TEACHER',
      resourceId: 12,
      displayName: 'Frau Müller',
    );
    const b = TimetableResourceRef(resourceType: 'TEACHER', resourceId: 12);

    expect(a.storageKey, b.storageKey);
  });
}
