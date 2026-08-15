import 'theme_service.dart';
import 'logger_service.dart';

class AppInitializer {
  bool _isInitialized = false;
  String _status = 'Starting...';
  double _progress = 0.0;

  late final ThemeService theme;
  late final LoggerService logger;

  bool get isInitialized => _isInitialized;
  String get status => _status;
  double get progress => _progress;

  Future<void> initialize() async {
    try {
      _updateStatus('📝 Initializing logging...', 0.1);
      logger = LoggerService();
      await logger.initialize();

      _updateStatus('⚙️ Loading preferences...', 0.3);
      theme = ThemeService();
      await theme.loadPreferences();

      _updateStatus('✅ System ready!', 1.0);
      _isInitialized = true;
    } catch (e) {
      _status = '⚠️ Error: ${e.toString()}';
      rethrow;
    }
  }

  void _updateStatus(String status, double progress) {
    _status = status;
    _progress = progress;
  }
}
