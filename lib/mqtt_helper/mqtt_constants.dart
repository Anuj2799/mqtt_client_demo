class MQTTConstants {
  static const String host = 'test.mosquitto.org';
  static const int port = 1883; // 1883 for staging or local && 1884 for production
  static const int keepAlivePeriod = 2; // value here will be in the seconds
  static const bool secure = false;
  static const bool logging = false;

  /// All the topics to subscribe or publish
  static const String commonTopic = 'mqtt_chat/demo';

  static String subscribeTopic() {
    return '$commonTopic/demoChats';
  }

  static String publishTopic() {
    return '$commonTopic/demoChats';
  }
}
