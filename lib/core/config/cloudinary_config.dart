class CloudinaryConfig {
  // TODO: Replace with your actual Cloudinary credentials
  // Get these from: https://cloudinary.com/console
  
  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String apiKey = 'YOUR_API_KEY';
  static const String apiSecret = 'YOUR_API_SECRET';
  
  // Base URL for image/video delivery
  static String get baseUrl => 'https://res.cloudinary.com/$cloudName';
  
  // Video transformation presets
  static const String videoQualityAuto = 'q_auto';
  static const String videoFormatAuto = 'f_auto';
  
  // Image transformation presets
  static const String thumbnailTransform = 'w_300,h_200,c_fill';
  static const String avatarTransform = 'w_150,h_150,c_fill,g_face';
  
  // Get optimized video URL
  static String getVideoUrl(String publicId, {String quality = 'auto'}) {
    return '$baseUrl/video/upload/q_$quality,f_auto/$publicId';
  }
  
  // Get optimized image URL
  static String getImageUrl(String publicId, {String? transformation}) {
    final transform = transformation ?? thumbnailTransform;
    return '$baseUrl/image/upload/$transform/$publicId';
  }
  
  // Get thumbnail from video
  static String getVideoThumbnail(String videoPublicId) {
    return '$baseUrl/video/upload/so_0,w_300,h_200,c_fill/$videoPublicId.jpg';
  }
}

// Instructions:
// 1. Sign up at https://cloudinary.com
// 2. Go to Dashboard to find your credentials
// 3. Replace the values above with your actual credentials
// 4. For video uploads, you can use Cloudinary Upload API or upload manually
//    through their console and use the public_id in your Firestore documents
