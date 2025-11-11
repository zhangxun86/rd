import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../models/attachment_response_model.dart';

class FeedbackRemoteDataSource {
  final Dio _dio;
  FeedbackRemoteDataSource(this._dio);

  /// Uploads a single image file.
  Future<AttachmentResponseModel> uploadAttachment(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        // The API expects the file stream under the key 'filedata'
        "filedata": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      // The common params interceptor will add the token automatically.
      final response = await _dio.post(
        '/attachment/upload',
        data: formData,
      );

      return AttachmentResponseModel.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  /// Submits the feedback.
  Future<void> submitFeedback({
    required int type,
    required String content,
    String? imgsJsonString, // Accepts a JSON string of image URLs
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'type': type,
        'content': content,
      };
      if (imgsJsonString != null) {
        queryParameters['imgs'] = imgsJsonString;
      }

      await _dio.post(
        '/guest_book_add',
        queryParameters: queryParameters,
      );
    } on DioException {
      rethrow;
    }
  }
}