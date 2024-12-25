import 'package:hive/hive.dart';

final class RequestReviewHelper {
  /// The number of times the app has been launched
  int _launchCount = 0;
  get launchCount => _launchCount;

  /// The last time a review request was made
  DateTime? _lastReviewRequest;
  get _isReviewReminderDue =>
      _lastReviewRequest == null ||
      DateTime.now().difference(_lastReviewRequest!) >= Duration(days: 3);

  /// Private constructor
  RequestReviewHelper._internal();

  // Singleton instance
  static final RequestReviewHelper _instance = RequestReviewHelper._internal();

  // Factory constructor to return the singleton instance
  static RequestReviewHelper get instance => _instance;

  // Hive box
  late final Box _box;

  // Initialize the singleton instance from Hive
  static Future<RequestReviewHelper> initialize() async {
    final box = await Hive.openBox('reviewBox');

    _instance._launchCount = box.get('launchCount', defaultValue: 0);
    _instance._lastReviewRequest = box.get('lastReviewRequest');

    _instance._box = box;

    return _instance;
  }

  Future<void> incrementCount({bool isLaunch = false}) async {
    if (isLaunch) {
      _launchCount++;
    }

    await save();
  }

  bool shouldRequestReview() {
    final shouldRequestReview = _launchCount >= 10 && _isReviewReminderDue;

    if (shouldRequestReview) {
      _lastReviewRequest = DateTime.now();
      save();
    }

    return shouldRequestReview;
  }

  Future<void> save() async {
    await _box.put('launchCount', _launchCount);
    await _box.put('lastReviewRequest', _lastReviewRequest);
  }
}
