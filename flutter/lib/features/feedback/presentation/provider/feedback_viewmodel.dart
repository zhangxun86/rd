import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_network_kit/flutter_network_kit.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/services/loading_service.dart';
import '../../domain/repositories/feedback_repository.dart';

/// Defines the possible states for the feedback submission process.
enum FeedbackState {
  idle,       // The initial state, no operation in progress.
  uploading,  // Uploading images.
  submitting, // Submitting the final feedback form.
  success,    // The operation completed successfully.
  error,      // The operation failed.
}

/// Defines one-time events for the UI to react to.
enum FeedbackEvent {
  none,
  submissionSuccess,
  submissionError,
}

/// Manages the state and business logic for the feedback feature.
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

  /// Resets the current event to `none` after the UI has handled it.
  void consumeEvent() {
    _event = FeedbackEvent.none;
  }

  /// Opens the image gallery to pick an image.
  Future<void> pickImage() async {
    if (_pickedImages.length >= maxImages) {
      // TODO: Show a user-friendly message that the max number of images has been reached.
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        _pickedImages.add(image);
        notifyListeners();
      }
    } catch (e) {
      // Handle potential platform exceptions from image_picker
      debugPrint("Error picking image: $e");
    }
  }

  /// Removes a previously picked image from the list.
  void removeImage(XFile image) {
    _pickedImages.remove(image);
    notifyListeners();
  }

  /// Handles the entire feedback submission process, including image uploads.
  Future<void> submitFeedback(BuildContext context, String content, {int type = 1}) async {
    if (content.isEmpty && _pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("反馈内容和图片不能同时为空"),
        backgroundColor: Colors.orange,
      ));
      return;
    }

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
            throw error; // Propagate the error to the outer catch block.
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
          _pickedImages.clear(); // Clear images on successful submission.
          break;
        case Failure(exception: final error):
          throw error;
      }

    } catch (e) {
      _state = FeedbackState.error;
      _event = FeedbackEvent.submissionError;
      _errorMessage = e is ApiException ? e.message : "An unexpected error occurred: ${e.toString()}";
    } finally {
      // After any error, reset state to idle so the user can try again.
      // On success, the state will be 'success', and the page will pop.
      if (_state == FeedbackState.error) {
        _state = FeedbackState.idle;
      }
      LoadingService.hide();
      notifyListeners();
    }
  }
}