import 'package:dio/dio.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
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
  late DashboardService service;

  setUp(() {
    api = MockApiClient();
    service = DashboardService(api);
  });

  group('normalizeArticleFileUrl', () {
    test('normalizes duplicated host prefix', () {
      final out = normalizeArticleFileUrl(
        'https://sbs.synergyengineering.comhttps://storage.googleapis.com/a.webp',
      );
      expect(out, 'https://storage.googleapis.com/a.webp');
    });

    test('returns null on empty input', () {
      expect(normalizeArticleFileUrl(''), isNull);
      expect(normalizeArticleFileUrl(null), isNull);
    });
  });

  group('DashboardService.fetchArticlesPage', () {
    test('throws for invalid page number', () async {
      expect(() => service.fetchArticlesPage(0), throwsArgumentError);
    });

    test('maps items and detects hasMore from next_page_url', () async {
      when(
        () => api.get<Map<String, dynamic>>(
          '/articles',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _response(<String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'articles': <dynamic>[
              <String, dynamic>{
                'id': 1,
                'title': 'Policy Update',
                'file_url':
                    'https://sbs.synergyengineering.comhttps://storage.googleapis.com/img.webp',
              },
            ],
            'next_page_url': 'https://api.example.com/articles?page=2',
          },
        }, path: '/articles'),
      );

      final result = await service.fetchArticlesPage(1);

      expect(result.items, hasLength(1));
      expect(result.items.first.id, '1');
      expect(
        result.items.first.fileUrl,
        'https://storage.googleapis.com/img.webp',
      );
      expect(result.hasMore, isTrue);
    });
  });

  group('DashboardService.fetchDashboardData', () {
    test('maps monthly summary + daily not found into check-in card', () async {
      when(
        () => api.get<Map<String, dynamic>>('/attendances/monthly_summary'),
      ).thenAnswer(
        (_) async => _response(<String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'lateness': 1,
            'short_of_workhours': 0,
            'absences': 2,
            'works': 10,
            'timesheets': '80:00',
          },
        }, path: '/attendances/monthly_summary'),
      );

      when(
        () => api.get<Map<String, dynamic>>(
          '/articles',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _response(<String, dynamic>{
          'success': true,
          'data': <String, dynamic>{'articles': <dynamic>[]},
        }, path: '/articles'),
      );

      when(
        () => api.get<Map<String, dynamic>>(
          '/attendances/daily',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _response(
          <String, dynamic>{
            'success': false,
            'message': 'Attendance not found',
          },
          statusCode: 404,
          path: '/attendances/daily',
        ),
      );

      final data = await service.fetchDashboardData();

      expect(data.monthStats.works, 10);
      expect(data.totalTimesheet.totalHours, '80:00');
      expect(data.dailyAttendance.primaryAction, 'Check In');
      expect(data.announcements, isEmpty);
    });
  });
}
