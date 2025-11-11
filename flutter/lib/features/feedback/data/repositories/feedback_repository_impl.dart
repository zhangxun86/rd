import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_datasource.dart';
import '../models/attachment_response_model.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource _remoteDataSource;
  FeedbackRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<AttachmentResponseModel, ApiException>> uploadAttachment(File file) async {
    try {
      final response = await _remoteDataSource.uploadAttachment(file);
      return Success(response);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Upload failed', requestOptions: e.requestOptions));
    }
  }

  @override
  Future<Result<void, ApiException>> submitFeedback({
    required int type,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      String? imgsJson;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        imgsJson = jsonEncode(imageUrls);
      }
      await _remoteDataSource.submitFeedback(
        type: type,
        content: content,
        imgsJsonString: imgsJson,
      );
      return const Success(null);
    } on DioException catch (e) {
      if (e.error is ApiException) return Failure(e.error as ApiException);
      return Failure(ApiException(message: 'Submit failed', requestOptions: e.requestOptions));
    }
  }
}