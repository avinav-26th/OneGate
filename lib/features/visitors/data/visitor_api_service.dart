import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/failure.dart';

class VisitorApiService {
  final http.Client client;
  final String baseUrl;

  VisitorApiService({
    http.Client? client,
    String? baseUrl,
  })  : client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl;

  Future<List<Map<String, dynamic>>> getVisitors() async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.visitorsEndpoint}');
      final response = await client.get(uri).timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        return [];
      }
      throw Failure('Failed to fetch visitors: ${response.statusCode}', statusCode: response.statusCode);
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while fetching visitors: $e');
    }
  }

  Future<Map<String, dynamic>> getVisitor(String id) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.visitorsEndpoint}/$id');
      final response = await client.get(uri).timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 404) {
        throw const Failure('Visitor not found', statusCode: 404);
      }
      throw Failure('Failed to fetch visitor: ${response.statusCode}', statusCode: response.statusCode);
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while fetching visitor: $e');
    }
  }

  Future<Map<String, dynamic>> createVisitor(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.visitorsEndpoint}');
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Failure('Failed to create visitor: ${response.statusCode}', statusCode: response.statusCode);
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while creating visitor: $e');
    }
  }

  Future<Map<String, dynamic>> updateVisitor(String id, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.visitorsEndpoint}/$id');
      final response = await client
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Failure('Failed to update visitor: ${response.statusCode}', statusCode: response.statusCode);
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while updating visitor: $e');
    }
  }

  Future<Map<String, dynamic>> patchVisitor(String id, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.visitorsEndpoint}/$id');
      final response = await client
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Failure('Failed to update visitor status: ${response.statusCode}', statusCode: response.statusCode);
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while updating status: $e');
    }
  }

  Future<void> deleteVisitor(String id) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.visitorsEndpoint}/$id');
      final response = await client.delete(uri).timeout(ApiConstants.timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      throw Failure('Failed to delete visitor: ${response.statusCode}', statusCode: response.statusCode);
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure('Network error while deleting visitor: $e');
    }
  }
}
