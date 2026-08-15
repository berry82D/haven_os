class LoggerService {
  Future<void> initialize() async {
    // Initialization performed (no internal state required currently)
    print('📝 Logger initialized');
  }

  void log(String level, String service, String message) {
    print('[$level] [$service] $message');
  }

  void debug(String service, String message) {
    log('DEBUG', service, message);
  }

  void info(String service, String message) {
    log('INFO', service, message);
  }

  void warning(String service, String message) {
    log('WARNING', service, message);
  }

  void error(String service, String message) {
    log('ERROR', service, message);
  }
}
