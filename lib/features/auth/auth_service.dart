import 'dart:convert';

import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/utils/logger.dart';
import 'package:dio/dio.dart';

/// Workplace polygon / point string from `/users/me`.
class WorkPlace {
  final String label;
  final String coordinates;

  const WorkPlace({required this.label, required this.coordinates});

  factory WorkPlace.fromJson(Map<String, dynamic> json) {
    return WorkPlace(
      label: (json['label'] ?? '').toString(),
      coordinates: (json['coordinates'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'coordinates': coordinates};
}

/// Current user profile from `GET /users/me`.
class CurrentUserProfile {
  final String fullName;
  final String companyName;
  final String disciplineName;
  final String titleName;
  final bool checkInAnywhere;
  final List<WorkPlace> workPlaces;
  final bool selfieRequired;

  /// Profile image URL from API (`avatar`, `avatar_url`, etc.).
  final String? avatar;

  /// Display initials (e.g. `JD`). From API `initial` / `initials`, or derived from [fullName].
  final String initial;

  const CurrentUserProfile({
    required this.fullName,
    required this.companyName,
    required this.disciplineName,
    required this.titleName,
    required this.checkInAnywhere,
    required this.workPlaces,
    required this.selfieRequired,
    this.avatar,
    this.initial = '',
  });

  /// Builds initials for avatar fallback when API does not send [initial].
  static String deriveInitialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts[0];
      if (s.length >= 2) return s.substring(0, 2).toUpperCase();
      return s.toUpperCase();
    }
    final a = parts.first[0];
    final b = parts.last[0];
    return ('$a$b').toUpperCase();
  }

  static String? _readAvatar(Map<String, dynamic> json) {
    const keys = <String>[
      'avatar',
      'avatar_url',
      'photo',
      'profile_photo',
      'photo_url',
      'photoUrl',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }

  factory CurrentUserProfile.fromJson(Map<String, dynamic> json) {
    final rawPlaces = json['work_places'] as List<dynamic>? ?? [];
    final places = <WorkPlace>[];
    for (final e in rawPlaces) {
      if (e is Map<String, dynamic>) {
        places.add(WorkPlace.fromJson(e));
      } else if (e is Map) {
        places.add(WorkPlace.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    final fullName = (json['full_name'] ?? '').toString();
    var initial =
        (json['initial'] ?? json['initials'] ?? '').toString().trim();
    if (initial.isEmpty) {
      initial = deriveInitialsFromName(fullName);
    }
    return CurrentUserProfile(
      fullName: fullName,
      companyName: (json['company_name'] ?? '').toString(),
      disciplineName: (json['discipline_name'] ?? '').toString(),
      titleName: (json['title_name'] ?? '').toString(),
      checkInAnywhere: json['check_in_anywhere'] == true,
      workPlaces: places,
      selfieRequired: json['selfie_required'] == true,
      avatar: _readAvatar(json),
      initial: initial,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'company_name': companyName,
    'discipline_name': disciplineName,
    'title_name': titleName,
    'check_in_anywhere': checkInAnywhere,
    'work_places': workPlaces.map((e) => e.toJson()).toList(),
    'selfie_required': selfieRequired,
    'avatar': avatar,
    'initial': initial,
  };

  /// Persisted shape: `{ "me": { ...profile fields } }`.
  Map<String, dynamic> toMeEnvelope() => {'me': toJson()};

  String toStorageJsonString() => jsonEncode(toMeEnvelope());

  /// Parses API `data` whether it is flat or `{ "me": { ... } }`.
  static CurrentUserProfile fromApiData(Map<String, dynamic> data) {
    final nested = data['me'];
    if (nested is Map<String, dynamic>) {
      return CurrentUserProfile.fromJson(nested);
    }
    if (nested is Map) {
      return CurrentUserProfile.fromJson(Map<String, dynamic>.from(nested));
    }
    return CurrentUserProfile.fromJson(data);
  }

  /// Reads stored JSON: prefers `{ "me": ... }`, falls back to legacy flat profile.
  static CurrentUserProfile? tryParseStorageJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    final me = map['me'];
    if (me is Map<String, dynamic>) {
      return CurrentUserProfile.fromJson(me);
    }
    if (me is Map) {
      return CurrentUserProfile.fromJson(Map<String, dynamic>.from(me));
    }
    return CurrentUserProfile.fromJson(map);
  }
}

/// Data model returned by the login endpoint.
class AuthUser {
  final String id;
  final String name;
  final String username;
  final String accessToken;
  final String accessExpiresAt;
  final String refreshToken;
  final String refreshExpiresAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      accessToken: (json['accessToken'] ?? '').toString(),
      accessExpiresAt: (json['accessExpiresAt'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      refreshExpiresAt: (json['refreshExpiresAt'] ?? '').toString(),
    );
  }

  AuthUser copyWith({
    String? id,
    String? name,
    String? username,
    String? accessToken,
    String? accessExpiresAt,
    String? refreshToken,
    String? refreshExpiresAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      accessToken: accessToken ?? this.accessToken,
      accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
    );
  }
}

/// Handles authentication-related API calls.
class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  /// Performs login against the backend `sign_in` endpoint.
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        throw const ApiException(message: 'Email and password are required.');
      }

      final response = await _api.post<Map<String, dynamic>>(
        '/sign_in',
        data: {'username': username, 'password': password},
      );

      final body = response.data ?? <String, dynamic>{};
      final success = body['success'] == true;

      if (!success) {
        throw ApiException(
          message: (body['message'] ?? 'Login failed').toString(),
          statusCode: response.statusCode,
        );
      }

      final data = body['data'] as Map<String, dynamic>?;
      final access = data?['access'] as Map<String, dynamic>?;
      final refresh = data?['refresh'] as Map<String, dynamic>?;
      final accessToken = (access?['token'] ?? '').toString();
      final accessExpiresAt = (access?['expires_at'] ?? '').toString();
      final refreshToken = (refresh?['token'] ?? '').toString();
      final refreshExpiresAt = (refresh?['expires_at'] ?? '').toString();

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        throw const ApiException(message: 'Token data missing in response.');
      }

      return AuthUser(
        id: (data?['id'] ?? '').toString(),
        name: (data?['name'] ?? '').toString(),
        username: username,
        accessToken: accessToken,
        accessExpiresAt: accessExpiresAt,
        refreshToken: refreshToken,
        refreshExpiresAt: refreshExpiresAt,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Loads the signed-in user profile (`GET /users/me`).
  Future<CurrentUserProfile> fetchCurrentUser() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/users/me');
      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw ApiException(
          message: (body['message'] ?? 'Failed to load user profile')
              .toString(),
          statusCode: response.statusCode,
          data: body,
        );
      }
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ApiException(message: 'User profile data missing.');
      }
      return CurrentUserProfile.fromApiData(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    AppLogger.info('User logged out');
    // await _api.post('/auth/logout');
  }
}
