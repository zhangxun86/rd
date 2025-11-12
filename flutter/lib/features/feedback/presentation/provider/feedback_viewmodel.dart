import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/services/loading_service.dart';
import '../../domain/repositories/feedback_repository.dart';

enum FeedbackState { idle, uploading, submitting, success, error }
enum FeedbackEvent { none, submissionSuccess, submissionError }

class FeedbackViewModel extends ChangeNotifier {
  final FeedbackRepository _feedbackRepository;
  FeedbackViewModel(this._feedbackRepository);

  FeedbackState _state = FeedbackState.idle;
  FeedbackState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  FeedbackEvent _event = FeedbackEvent.none;
  FeedbackEvent get event => _event;

  final List<XFile> _pickedImages = [];
  List<XFile> get pickedImages => List.unmodifiable(_pickedImages);

  final ImagePicker _picker = ImagePicker();
  final int maxImages = 6;

  void consumeEvent() {
    _event = FeedbackEvent.none;
  }

  Future<void> pickImage() async {
    if (_pickedImages.length >= maxImages) {
      // TODO: Show a user-friendly message
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        _pickedImages.add(image);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void removeImage(XFile image) {
    _pickedImages.remove(image);
    notifyListeners();
  }

  Future<void> submitFeedback(BuildContext context, String content, {int type = 1}) async {
    // --- VALIDATION CHECK ---
    // Ensure that the feedback content is not empty.
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("反馈内容不能为空"),
        backgroundColor: Colors.orange,
      ));
      return; // Exit the function early if validation fails.
    }
    // --- END OF CHECK ---

    _state = FeedbackState.uploading;
    notifyListeners();

    try {
      LoadingService.show(context, text: '正在上传图片 (0/${_pickedImages.length})...');

      List<String> uploadedImageUrls = [];
      for (int i = 0; i < _pickedImages.length; i++) {
        final image = _pickedImages[i];
        LoadingService.show(context, text: '正在上传图片 (${i + 1}/${_pickedImages.length})...');

        final result = await _feedbackRepository.uploadAttachment(File(image.path));

        switch (result) {
          case Success(value: final attachment):
            uploadedImageUrls.add(attachment.fileUrl);
            break;
          case Failure(exception: final error):
            throw error;
        }
      }

      _state = FeedbackState.submitting;
      notifyListeners();
      LoadingService.show(context, text: '正在提交反馈...');

      final submitResult = await _feedbackRepository.submitFeedback(
        type: type,
        content: content,
        imageUrls: uploadedImageUrls,
      );

      switch (submitResult) {
        case Success():
          _state = FeedbackState.success;
          _event = FeedbackEvent.submissionSuccess;
          _pickedImages.clear();
          break;
        case Failure(exception: final error):
          throw error;
      }

    } catch (e) {
      _state = FeedbackState.error;
      _event = FeedbackEvent.submissionError;
      _errorMessage = e is ApiException ? e.message : "An unexpected error occurred: ${e.toString()}";
    } finally {
      if (_state == FeedbackState.error) {
        _state = FeedbackState.idle;
      }
      LoadingService.hide();
      notifyListeners();
    }
  }
}