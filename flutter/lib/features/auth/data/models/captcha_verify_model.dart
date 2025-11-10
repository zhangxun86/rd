/// Represents the response from the captcha pre-verification API.
/// (/aliVerifyIntelligentCaptcha/check)
class CaptchaCheckResponse {
  final bool captchaVerifyResult;
  final String captchaVerifyKey;

  CaptchaCheckResponse({
    required this.captchaVerifyResult,
    required this.captchaVerifyKey,
  });

  /// Manually creates an instance from a JSON map.
  factory CaptchaCheckResponse.fromJson(Map<String, dynamic> json) {
    return CaptchaCheckResponse(
      captchaVerifyResult: json['captchaVerifyResult'] as bool? ?? false,
      captchaVerifyKey: json['captchaVerifyKey'] as String? ?? '',
    );
  }
}