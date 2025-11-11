import 'dart:io';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import '../../data/models/attachment_response_model.dart';

abstract class FeedbackRepository {
  Future<Result<AttachmentResponseModel, ApiException>> uploadAttachment(File file);

  Future<Result<void, ApiException>> submitFeedback({
    required int type,
    required String content,
    List<String>? imageUrls,
  });
}