import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/failure.dart';

// rest api client for remote visitor backend using dio
class VisitorApiService {
  final Dio _dio;
  final String baseUrl;

  VisitorApiService({
    Dio? dio,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConstants.defaultBaseUrl,
                connectTimeout: ApiConstants.timeout,
                receiveTimeout: ApiConstants.timeout,
                sendTimeout: ApiConstants.timeout,
                headers: {'Content-Type': 'application/json'},
              ),
            );

  // fetch all visitor records from cloud
  Future<List<Map<String, dynamic>>> getVisitors() async {
    try {
      final response = await _dio.get(ApiConstants.visitorsEndpoint);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }
      throw Failure('Failed to fetch visitors: ${response.statusCode}',
          statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e, 'fetching visitors');
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while fetching visitors: $e');
    }
  }

  Future<Map<String, dynamic>> getVisitor(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.visitorsEndpoint}/$id');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      if (response.statusCode == 404) {
        throw const Failure('Visitor not found', statusCode: 404);
      }
      throw Failure('Failed to fetch visitor: ${response.statusCode}',
          statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const Failure('Visitor not found', statusCode: 404);
      }
      throw _handleDioError(e, 'fetching visitor');
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while fetching visitor: $e');
    }
  }

  // register new visitor record on mockapi
  Future<Map<String, dynamic>> createVisitor(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post(ApiConstants.visitorsEndpoint, data: data);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Failure('Failed to create visitor: ${response.statusCode}',
          statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e, 'creating visitor');
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while creating visitor: $e');
    }
  }

  Future<Map<String, dynamic>> updateVisitor(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('${ApiConstants.visitorsEndpoint}/$id', data: data);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Failure('Failed to update visitor: ${response.statusCode}',
          statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e, 'updating visitor');
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while updating visitor: $e');
    }
  }

  // patch gate status and timestamps
  Future<Map<String, dynamic>> patchVisitor(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.patch('${ApiConstants.visitorsEndpoint}/$id', data: data);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Failure('Failed to update visitor status: ${response.statusCode}',
          statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e, 'updating status');
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while updating status: $e');
    }
  }

  Future<void> deleteVisitor(String id) async {
    try {
      final response = await _dio.delete('${ApiConstants.visitorsEndpoint}/$id');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return;
      }
      throw Failure('Failed to delete visitor: ${response.statusCode}',
          statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e, 'deleting visitor');
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while deleting visitor: $e');
    }
  }

  // map dio network errors into strongly-typed domain failures
  Failure _handleDioError(DioException e, String operation) {
    final status = e.response?.statusCode;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Failure('Connection timeout while $operation', statusCode: 408);
    }
    if (e.type == DioExceptionType.connectionError) {
      return Failure('Network connection error while $operation');
    }
    return Failure(
      e.response?.statusMessage ?? 'API error while $operation: ${e.message}',
      statusCode: status,
    );
  }
}
