// Notification service placeholder.
// Audio notifications are handled by audio_service package via AppAudioHandler.
// Extend this class if custom local notifications are needed in the future.

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  // Future<void> initialize() async {
  //   // Initialize local notifications here if needed
  // }
}
