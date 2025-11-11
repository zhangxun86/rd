class AttachmentResponseModel {
  final int id;
  final String fileUrl;

  AttachmentResponseModel({required this.id, required this.fileUrl});

  factory AttachmentResponseModel.fromJson(Map<String, dynamic> json) {
    return AttachmentResponseModel(
      id: json['id'] as int,
      fileUrl: json['fileUrl'] as String,
    );
  }
}