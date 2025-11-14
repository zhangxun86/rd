import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../provider/feedback_viewmodel.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _contentController = TextEditingController();
  late final FeedbackViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<FeedbackViewModel>();
    _viewModel.addListener(_onFeedbackStateChanged);
  }

  void _onFeedbackStateChanged() {
    if (!mounted) return;
    if (_viewModel.event == FeedbackEvent.submissionSuccess) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('反馈提交成功！感谢您的支持。'), backgroundColor: Colors.green),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else if (_viewModel.event == FeedbackEvent.submissionError) {
      _viewModel.consumeEvent();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage ?? '操作失败，请重试'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _viewModel.removeListener(_onFeedbackStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('问题反馈'),
        actions: [
          // Add a button to the AppBar
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'Verify Tokens',
            onPressed: () => _verifyToken(context),
          ),
          // ... (your existing logout button)
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 40),
              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: 8,
        maxLength: 300,
        decoration: InputDecoration(
          hintText: '请详细描述您的问题或建议...',
          border: InputBorder.none,
          counterStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Consumer<FeedbackViewModel>(
      builder: (context, viewModel, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: viewModel.pickedImages.length + (viewModel.pickedImages.length < viewModel.maxImages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == viewModel.pickedImages.length && viewModel.pickedImages.length < viewModel.maxImages) {
              return _buildAddImageButton(viewModel);
            }
            if (index >= viewModel.pickedImages.length) return const SizedBox.shrink();
            final image = viewModel.pickedImages[index];
            return _buildImageThumbnail(image, viewModel);
          },
        );
      },
    );
  }

  Widget _buildAddImageButton(FeedbackViewModel viewModel) {
    return GestureDetector(
      onTap: () => viewModel.pickImage(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 32),
      ),
    );
  }

  Widget _buildImageThumbnail(XFile image, FeedbackViewModel viewModel) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(image.path), // Image.file requires 'dart:io'
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: () => viewModel.removeImage(image),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext buildContext) {
    return Consumer<FeedbackViewModel>(
      builder: (context, viewModel, child) {
        // This check is now valid because the enum in the ViewModel is corrected.
        final isDisabled = viewModel.state == FeedbackState.uploading || viewModel.state == FeedbackState.submitting;

        return ElevatedButton(
          onPressed: isDisabled ? null : () {
            viewModel.submitFeedback(buildContext, _contentController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('提交', style: TextStyle(fontSize: 16)),
        );
      },
    );
  }

  void _verifyToken(BuildContext context) async {
    // Get the repository instance from the provider/DI.
    final authRepository = context.read<AuthRepository>();

    // 1. Read from SharedPreferences via the repository's existing method.
    final sharedPrefsToken = await authRepository.getToken();

    // 2. Read from FFI storage via our new repository method.
    final ffiToken = await authRepository.getTokenFromFFI();
    final userinfo = await authRepository.getUserInfoFromFFI();

    print("--- Token Verification ---");
    print("Token from SharedPreferences: $sharedPrefsToken");
    print("Token from RustDesk FFI Storage: $ffiToken");
    print("Token from RustDesk user info : $userinfo");
    print("--------------------------");

    // Show a SnackBar with the result.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'SharedPreferences: ${sharedPrefsToken ?? "Not Found"}\n'
                'FFI Storage: ${ffiToken ?? "Not Found"}'
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
  // ---
}