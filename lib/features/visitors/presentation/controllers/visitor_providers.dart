import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/visitor_api_service.dart';
import '../../data/visitor_repository_impl.dart';
import '../../domain/visitor_repository.dart';

// api service dependency injection provider
final visitorApiServiceProvider = Provider<VisitorApiService>((ref) {
  return VisitorApiService();
});

// repository instance provider backed by local storage and mockapi
final visitorRepositoryProvider = Provider<VisitorRepository>((ref) {
  final apiService = ref.watch(visitorApiServiceProvider);
  return VisitorRepositoryImpl(apiService: apiService);
});
