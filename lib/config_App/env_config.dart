import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment variables loaded from .env
class EnvConfig {
  EnvConfig._();

  /// Call once in main() before using any EnvConfig values.
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // ---------------------------------------------------------------------------
  // Cloudinary (Set 1 – upload_compress_image, sendimage, environnement)
  // ---------------------------------------------------------------------------
  static String get cloudinaryCloudName  => _get('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryApiKey1    => _get('CLOUDINARY_API_KEY_1');
  static String get cloudinaryApiSecret1 => _get('CLOUDINARY_API_SECRET_1');

  // ---------------------------------------------------------------------------
  // Cloudinary (Set 2 – upload_cloud.dart)
  // ---------------------------------------------------------------------------
  static String get cloudinaryApiKey2    => _get('CLOUDINARY_API_KEY_2');
  static String get cloudinaryApiSecret2 => _get('CLOUDINARY_API_SECRET_2');

  // ---------------------------------------------------------------------------
  // Cloudinary full URL (upload_compress_image)
  // ---------------------------------------------------------------------------
  static String get cloudinaryUrl => _get('CLOUDINARY_URL');

  // ---------------------------------------------------------------------------
  // OneSignal
  // ---------------------------------------------------------------------------
  static String get onesignalAppId => _get('ONESIGNAL_APP_ID');
  static String get onesignalApiKey => _get('ONESIGNAL_API_KEY');

  // ---------------------------------------------------------------------------
  // Firebase FCM (server-side keys)
  // ---------------------------------------------------------------------------
  static String get fcmServerKey    => _get('FCM_SERVER_KEY');
  static String get fcmServerKeyAlt => _get('FCM_SERVER_KEY_ALT');

  // ---------------------------------------------------------------------------
  // Firebase (public but centralised)
  // ---------------------------------------------------------------------------
  static String get firebaseApiKeyAndroid   => _get('FIREBASE_API_KEY_ANDROID');
  static String get firebaseApiKeyIos       => _get('FIREBASE_API_KEY_IOS');
  static String get firebaseAppId           => _get('FIREBASE_APP_ID');
  static String get firebaseMessagingSenderId => _get('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseProjectId       => _get('FIREBASE_PROJECT_ID');
  static String get firebaseStorageBucket   => _get('FIREBASE_STORAGE_BUCKET');
  static String get firebaseIosBundleId     => _get('FIREBASE_IOS_BUNDLE_ID');

  // ---------------------------------------------------------------------------
  // VideoSDK – Live video/audio conferencing
  // ---------------------------------------------------------------------------
  /// Verification token (pre-generated JWT from VideoSDK dashboard).
  static String get videosdkToken => _get('VIDEOSDK_TOKEN');

  // ---------------------------------------------------------------------------
  // Base URLs (Cloudinary)
  // ---------------------------------------------------------------------------
  static String get baseUrlVideo =>
      'https://res.cloudinary.com/$cloudinaryCloudName';
  static String get baseUrlImg =>
      'https://res.cloudinary.com/$cloudinaryCloudName';

  // ---------------------------------------------------------------------------
  // Internal helper
  // ---------------------------------------------------------------------------
  static String _get(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('❌ EnvConfig: "$key" is missing or empty in .env');
    }
    return value;
  }
}
