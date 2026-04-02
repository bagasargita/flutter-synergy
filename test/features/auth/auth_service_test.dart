import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

Response<Map<String, dynamic>> _response(
  Map<String, dynamic> data, {
  int statusCode = 200,
  String path = '/',
}) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: path),
    data: data,
    statusCode: statusCode,
  );
}

void main() {
  late MockApiClient api;
  late AuthService service;

  setUp(() {
    api = MockApiClient();
    service = AuthService(api);
  });

  group('AuthService.login', () {
    test('throws when username/password is empty', () async {
      expect(
        () => service.login(username: '', password: ''),
        throwsA(isA<ApiException>()),
      );
    });

    test('returns AuthUser when response is successful', () async {
      when(
        () => api.post<Map<String, dynamic>>(
          '/sign_in',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _response(
          <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'id': 42,
              'name': 'Jane Doe',
              'access': <String, dynamic>{
                'token': 'access_123',
                'expires_at': '2026-04-03T12:00:00+07:00',
              },
              'refresh': <String, dynamic>{
                'token': 'refresh_123',
                'expires_at': '2026-05-03T12:00:00+07:00',
              },
            },
          },
          path: '/sign_in',
        ),
      );

      final user = await service.login(username: 'jane', password: 'secret');

      expect(user.id, '42');
      expect(user.name, 'Jane Doe');
      expect(user.username, 'jane');
      expect(user.accessToken, 'access_123');
      expect(user.refreshToken, 'refresh_123');
    });

    test('throws when token payload is missing', () async {
      when(
        () => api.post<Map<String, dynamic>>(
          '/sign_in',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _response(
          <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'id': 'u1',
              'name': 'Jane',
              'access': <String, dynamic>{},
              'refresh': <String, dynamic>{},
            },
          },
          path: '/sign_in',
        ),
      );

      expect(
        () => service.login(username: 'jane', password: 'secret'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Token data missing in response.',
          ),
        ),
      );
    });
  });

  group('AuthService.fetchCurrentUser', () {
    test('parses nested me payload', () async {
      when(() => api.get<Map<String, dynamic>>('/users/me')).thenAnswer(
        (_) async => _response(
          <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'me': <String, dynamic>{
                'full_name': 'John',
                'company_name': 'SE',
                'discipline_name': 'IT',
                'title_name': 'Engineer',
                'check_in_anywhere': true,
                'selfie_required': false,
                'work_places': <dynamic>[
                  <String, dynamic>{'label': 'HQ', 'coordinates': '1;2;3;4;5;6'},
                ],
              },
            },
          },
          path: '/users/me',
        ),
      );

      final profile = await service.fetchCurrentUser();

      expect(profile.fullName, 'John');
      expect(profile.checkInAnywhere, isTrue);
      expect(profile.selfieRequired, isFalse);
      expect(profile.workPlaces.length, 1);
      expect(profile.workPlaces.first.label, 'HQ');
    });

    test('throws when API says success=false', () async {
      when(() => api.get<Map<String, dynamic>>('/users/me')).thenAnswer(
        (_) async => _response(
          <String, dynamic>{
            'success': false,
            'message': 'Unauthorized',
          },
          statusCode: 401,
          path: '/users/me',
        ),
      );

      expect(
        () => service.fetchCurrentUser(),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'Unauthorized'),
        ),
      );
    });
  });

  group('CurrentUserProfile storage parser', () {
    test('supports storage envelope and legacy flat payload', () {
      final nested = CurrentUserProfile.tryParseStorageJson(
        '{"me":{"full_name":"N","company_name":"C","discipline_name":"D","title_name":"T","check_in_anywhere":true,"selfie_required":true,"work_places":[]}}',
      );
      final flat = CurrentUserProfile.tryParseStorageJson(
        '{"full_name":"F","company_name":"C2","discipline_name":"D2","title_name":"T2","check_in_anywhere":false,"selfie_required":false,"work_places":[]}',
      );

      expect(nested?.fullName, 'N');
      expect(flat?.fullName, 'F');
      expect(CurrentUserProfile.tryParseStorageJson(''), isNull);
    });
  });
}
