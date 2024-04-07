import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'mqtt_constants.dart';

class MQTTManager {
  MqttServerClient? _client;
  Function(String)? responseCallBack;

  void initializeMQTTClient(String identifier) async {
    _client = MqttServerClient.withPort(MQTTConstants.host, identifier, MQTTConstants.port);
    _client?.keepAlivePeriod = MQTTConstants.keepAlivePeriod;
    _client?.secure = MQTTConstants.secure;
    _client?.logging(on: MQTTConstants.logging);
    _client?.autoReconnect = true;

    _client?.onConnected = _onConnected;
    _client?.onSubscribed = _onSubscribed;
    _client?.onUnsubscribed = _onUnSubscribed;
    _client?.onDisconnected = _onDisconnected;
    final connMessage = MqttConnectMessage().startClean();
    _client?.connectionMessage = connMessage;
    _client?.setProtocolV311();
  }

  Future<void> connect({required String identifier}) async {
    initializeMQTTClient(identifier);
    assert(_client != null, 'Client must be initialized before you access it.');
    try {
      await _client?.connect().then((value) => debugPrint("Value :: $value"));
    } on Exception catch (e) {
      debugPrint("Getting the exception while connecting to mqtt server :: $e");
      disconnect();
    }
  }

  Future<void> disconnect() async {
    _client?.disconnect();
  }

  Future<void> publish(String payload, String topic) async {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client?.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  Future<void> subscribe(String topic, Function(String data)? callBack) async {
    responseCallBack = callBack;
    _client?.subscribe(topic, MqttQos.exactlyOnce);
  }

  Future<void> unSubscribe(String topic) async {
    _client?.unsubscribe(topic, expectAcknowledge: true);
  }

  void _onSubscribed(topic) {
    /// Do something on subscribed
  }

  void _onUnSubscribed(topic) {
    /// Do something on unsubscribed
  }

  void _onDisconnected() {
    if (_client?.connectionStatus?.returnCode == MqttConnectReturnCode.noneSpecified) {}
  }

  void _onConnected() {
    debugPrint("MQTT Server is connected.");
    _client?.updates?.listen((event) {
      var rawPayloadData = event.first.payload as MqttPublishMessage;
      var responseMessageFromPayload = MqttPublishPayload.bytesToStringAsString(rawPayloadData.payload.message);
      responseCallBack?.call(responseMessageFromPayload);
    });
  }
}
