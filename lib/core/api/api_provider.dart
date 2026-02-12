import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/api/api_client.dart';
import 'package:flutter_synergy/core/utils/environment.dart';

/// Provides the current [Environment] to the dependency graph.
///
/// Override this in `main()` when switching between dev / prod.
final environmentProvider = Provider<Environment>((ref) {
  return Environment.dev();
});

/// Singleton [ApiClient] available everywhere via Riverpod.
final apiClientProvider = Provider<ApiClient>((ref) {
  final environment = ref.watch(environmentProvider);
  return ApiClient(environment: environment);
});
