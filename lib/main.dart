import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

import 'mqtt_helper/mqtt_constants.dart';
import 'mqtt_helper/mqtt_manager.dart';

void main() {
  runApp(const MqttClient());
}

class MqttClient extends StatelessWidget {
  const MqttClient({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter MQTT demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MQTTManager _mqttManager = MQTTManager();
  String? _deviceIdForIos;
  String? _deviceIdForAndroid;
  String? _deviceId;
  int? _timeStamp;
  late String _uniqueIdentifier;
  final List<String> _listOfChats = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMqtt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorConstants.primaryDarkPurple,
              ColorConstants.primaryLightPurple,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery
                  .of(context)
                  .size
                  .height - 20.0,
              child: Column(
                children: [
                  Expanded(
                    flex: 7,
                    child: Container(
                      margin: const EdgeInsets.only(
                        right: 20.0,
                        left: 20.0,
                        top: 20.0,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 20.0,
                          left: 20.0,
                          top: 20.0,
                        ),
                        child: ListView.builder(
                          itemCount: _listOfChats.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                              padding: const EdgeInsets.symmetric(
                                vertical: 7.0,
                                horizontal: 15.0,
                              ),
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(15.0)),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    ColorConstants.primaryDarkPurple,
                                    ColorConstants.primaryLightPurple,
                                  ],
                                ),
                              ),
                              child: Text(
                                _listOfChats[index],
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Container(
                            height: double.infinity,
                            margin: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 20.0, right: 7.0),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(15.0)),
                            ),
                            child: TextField(
                              controller: _chatController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Type a message',
                                contentPadding: EdgeInsets.only(
                                  left: 10.0,
                                  top: 5.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await _mqttManager.publish(_chatController.text, MQTTConstants.publishTopic());
                              _chatController.clear();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(top: 20.0, bottom: 20.0, right: 20.0),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(15.0)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Image.asset('assets/send_message.png'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeMqtt() async {
    if (Platform.isIOS) {
      _deviceIdForIos = await _getIdForIOS();
    } else if (Platform.isAndroid) {
      _deviceIdForAndroid = await _getIdForAndroid();
    }

    _deviceId = Platform.isIOS ? _deviceIdForIos : _deviceIdForAndroid;
    _timeStamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    _uniqueIdentifier = 'some_unique_identifier_$_deviceId#$_timeStamp';

    await _mqttManager.disconnect();
    await _mqttManager.connect(identifier:_uniqueIdentifier);
    await _mqttManager.subscribe(MQTTConstants.subscribeTopic(), (data) {
      debugPrint('Data we received is : $data');
      _listOfChats.add(data);
      setState(() {});
    });
  }

  Future<String?> _getIdForIOS() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    var iosDeviceInfo = await deviceInfo.iosInfo;
    return iosDeviceInfo.identifierForVendor;
  }

  Future<String?> _getIdForAndroid() async {
    const androidIdPlugin = AndroidId();
    String androidId;
    try {
      androidId = await androidIdPlugin.getId() ?? 'Unknown ID';
      return androidId;
    } on PlatformException {
      androidId = 'Failed to get Android ID.';
    }
    return null;
  }
}
