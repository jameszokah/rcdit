import 'dart:convert';

import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rcdit_user/pages/NavigatorPages/editprofile.dart';
import 'package:rcdit_user/pages/NavigatorPages/history.dart';
import 'package:rcdit_user/pages/NavigatorPages/makecomplaint.dart';
import 'package:rcdit_user/pages/onTripPage/booking_confirmation.dart';
import 'package:rcdit_user/pages/login/get_started.dart';
import 'package:rcdit_user/pages/login/login.dart';
import 'package:rcdit_user/pages/onTripPage/map_page.dart';
import 'package:rcdit_user/pages/onTripPage/review_page.dart';
import 'package:rcdit_user/pages/referralcode/referral_code.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

//languages code
dynamic phcode;
dynamic platform;
dynamic fcm;
dynamic pref;
String isActive = '';
double duration = 30.0;
var audio = 'audio/notification_sound.mp3';
bool internet = true;

//base url
String url = 'base url ';
String mqttUrl = 'mqtt url';
int mqttPort = 1883;
String mapkey = 'map key';

//check internet connection

checkInternetConnection() {
  Connectivity().onConnectivityChanged.listen((connectionState) {
    if (connectionState == ConnectivityResult.none) {
      internet = false;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    } else {
      internet = true;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    }
  });
}

getDetailsOfDevice() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    rootBundle.loadString('assets/map_style_black.json').then((value) {
      mapStyle = value;
    });
    var token = await FirebaseMessaging.instance.getToken();
    fcm = token;
    pref = await SharedPreferences.getInstance();
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

dynamic timerLocation;
//get current location
getCurrentLocation() {
  timerLocation = Timer.periodic(const Duration(seconds: 5), (timer) async {
    var loc = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium);

    currentLocation = LatLng(loc.latitude, loc.longitude);
  });
}

//validate email already exist

validateEmail() async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse(url + 'api/v1/user/validate-mobile'),
        body: {'email': email});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        result = 'failed';
      }
    } else {
      result = jsonDecode(response.body)['message'];
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//language code
var choosenLanguage = '';
var languageDirection = '';

List languagesCode = [
  {'name': 'Amharic', 'code': 'am'},
  {'name': 'Arabic', 'code': 'ar'},
  {'name': 'Basque', 'code': 'eu'},
  {'name': 'Bengali', 'code': 'bn'},
  {'name': 'English (UK)', 'code': 'en-GB'},
  {'name': 'Portuguese (Brazil)', 'code': 'pt-BR'},
  {'name': 'Bulgarian', 'code': 'bg'},
  {'name': 'Catalan', 'code': 'ca'},
  {'name': 'Cherokee', 'code': 'chr'},
  {'name': 'Croatian', 'code': 'hr'},
  {'name': 'Czech', 'code': 'cs'},
  {'name': 'Danish', 'code': 'da'},
  {'name': 'Dutch', 'code': 'nl'},
  {'name': 'English (US)', 'code': 'en'},
  {'name': 'Estonian', 'code': 'et'},
  {'name': 'Filipino', 'code': 'fil'},
  {'name': 'Finnish', 'code': 'fi'},
  {'name': 'French', 'code': 'fr'},
  {'name': 'German', 'code': 'de'},
  {'name': 'Greek', 'code': 'el'},
  {'name': 'Gujarati', 'code': 'gu'},
  {'name': 'Hebrew', 'code': 'iw'},
  {'name': 'Hindi', 'code': 'hi'},
  {'name': 'Hungarian', 'code': 'hu'},
  {'name': 'Icelandic', 'code': 'is'},
  {'name': 'Indonesian', 'code': 'id'},
  {'name': 'Italian', 'code': 'it'},
  {'name': 'Japanese', 'code': 'ja'},
  {'name': 'Kannada', 'code': 'kn'},
  {'name': 'Korean', 'code': 'ko'},
  {'name': 'Latvian', 'code': 'lv'},
  {'name': 'Lithuanian', 'code': 'lt'},
  {'name': 'Malay', 'code': 'ms'},
  {'name': 'Malayalam', 'code': 'ml'},
  {'name': 'Marathi', 'code': 'mr'},
  {'name': 'Norwegian', 'code': 'no'},
  {'name': 'Polish', 'code': 'pl'},
  {
    'name': 'Portuguese (Portugal)',
    'code': 'pt' //pt-PT
  },
  {'name': 'Romanian', 'code': 'ro'},
  {'name': 'Russian', 'code': 'ru'},
  {'name': 'Serbian', 'code': 'sr'},
  {
    'name': 'Chinese (PRC)',
    'code': 'zh' //zh-CN
  },
  {'name': 'Slovak', 'code': 'sk'},
  {'name': 'Slovenian', 'code': 'sl'},
  {'name': 'Spanish', 'code': 'es'},
  {'name': 'Swahili', 'code': 'sw'},
  {'name': 'Swedish', 'code': 'sv'},
  {'name': 'Tamil', 'code': 'ta'},
  {'name': 'Telugu', 'code': 'te'},
  {'name': 'Thai', 'code': 'th'},
  {'name': 'Chinese (Taiwan)', 'code': 'zh-TW'},
  {'name': 'Turkish', 'code': 'tr'},
  {'name': 'Urdu', 'code': 'ur'},
  {'name': 'Ukrainian', 'code': 'uk'},
  {'name': 'Vietnamese', 'code': 'vi'},
  {'name': 'Welsh', 'code': 'cy'},
];

//getting country code

List countries = [];
getCountryCode() async {
  dynamic result;
  try {
    final response = await http.get(Uri.parse(url + 'api/v1/countries'));

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data'];
      phcode = (countries
              .where((element) =>
                  element['code'] ==
                  WidgetsBinding.instance!.window.locale.countryCode)
              .isNotEmpty)
          ? countries.indexWhere((element) =>
              element['code'] ==
              WidgetsBinding.instance!.window.locale.countryCode)
          : 0;
      result = 'success';
    } else {
      result = 'error';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//login firebase

String userUid = '';
var verId = '';
int? resendTokenId;
bool phoneAuthCheck = false;
dynamic credentials;

phoneAuth(String phone) async {
  try {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        credentials = credential;
        valueNotifierHome.incrementNotifier();
      },
      forceResendingToken: resendTokenId,
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          debugPrint('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        verId = verificationId;
        resendTokenId = resendToken;
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//get local bearer token

getLocalData() async {
  dynamic result;
  bearerToken.clear;
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    if (pref.containsKey('choosenLanguage')) {
      choosenLanguage = pref.getString('choosenLanguage');
      languageDirection = pref.getString('languageDirection');
      if (choosenLanguage.isNotEmpty) {
        if (pref.containsKey('Bearer')) {
          var tokens = pref.getString('Bearer');
          if (tokens != null) {
            bearerToken.add(BearerClass(type: 'Bearer', token: tokens));

            var responce = await getUserDetails();
            if (responce == true) {
              result = '3';
            } else if (responce == false) {
              result = '2';
            }
          } else {
            result = '2';
          }
        } else {
          result = '2';
        }
      } else {
        result = '1';
      }
    } else {
      result = '1';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//register user

List<BearerClass> bearerToken = <BearerClass>[];

registerUser() async {
  bearerToken.clear();
  dynamic result;
  try {
    final response = await http.post(Uri.parse(url + 'api/v1/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "mobile": phnumber,
          "email": email,
          "device_token": fcm,
          "terms_condition": true,
          "country": countries[phcode]['dial_code'],
          "login_by": (platform == TargetPlatform.android) ? 'android' : 'ios',
        }));

    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);

      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      // SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('Bearer', bearerToken[0].token);
      await getUserDetails();
      result = 'true';
    } else {
      result = 'false';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//update referral code

updateReferral() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse(url + 'api/v1/update/user/referral'),
            headers: {
              'Authorization': 'Bearer ' + bearerToken[0].token,
              'Content-Type': 'application/json'
            },
            body: jsonEncode({"refferal_code": referralCode}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'true';
      } else {
        result = 'false';
      }
    } else {
      result = 'false';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//call firebase otp

otpCall() async {
  dynamic result;
  try {
    var otp = await FirebaseDatabase.instance.ref().child('call_FB_OTP').get();
    result = otp;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no Internet';
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

// verify user already exist

verifyUser(String number) async {
  dynamic val;
  try {
    var response = await http.post(
        Uri.parse(url + 'api/v1/user/validate-mobile-for-login'),
        body: {"mobile": number});

    if (response.statusCode == 200) {
      val = jsonDecode(response.body)['success'];

      if (val == true) {
        var check = await userLogin();
        if (check == true) {
          var uCheck = await getUserDetails();
          val = uCheck;
        } else {
          val = false;
        }
      } else {
        val = false;
      }
    } else {
      val = false;
    }
    return val;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//user login
userLogin() async {
  bearerToken.clear();
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/user/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "mobile": phnumber,
          'device_token': fcm,
          "login_by": (platform == TargetPlatform.android) ? 'android' : 'ios',
        }));
    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);
      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      result = true;
      pref.setString('Bearer', bearerToken[0].token);
    } else {
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

Map<String, dynamic> userDetails = {};
List favAddress = [];

//user current state
getUserDetails() async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(url + 'api/v1/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + bearerToken[0].token
      },
    );
    if (response.statusCode == 200) {
      userDetails =
          Map<String, dynamic>.from(jsonDecode(response.body)['data']);
      favAddress = userDetails['favouriteLocations']['data'];
      sosData = userDetails['sos']['data'];
      if (userDetails['onTripRequest'] != null) {
        userRequestData = userDetails['onTripRequest']['data'];
        if (userRequestData['accepted_at'] != null) {
          getCurrentMessages();
        }
        if (client.connectionStatus == null) {
          mqttForUser();
        }
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      } else if (userDetails['metaRequest'] != null) {
        userRequestData = userDetails['metaRequest']['data'];
        addressList.add(
          AddressList(
              id: 'pickup',
              address: userRequestData['pick_address'],
              latlng: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng'])),
        );
        addressList.add(
          AddressList(
              id: 'drop',
              address: userRequestData['drop_address'],
              latlng: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng'])),
        );

        if (client.connectionStatus == null) {
          mqttForUser();
        }
        valueNotifierBook.incrementNotifier();
      } else {
        userRequestData = {};
      }
      if (userDetails['active'] == false) {
        isActive = 'false';
      } else {
        isActive = 'true';
      }
      result = true;
    } else {
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

class BearerClass {
  final String type;
  final String token;
  BearerClass({required this.type, required this.token});

  BearerClass.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        token = json['token'];

  Map<String, dynamic> toJson() => {'type': type, 'token': token};
}

Map<String, dynamic> driverReq = {};
var client = MqttServerClient.withPort(mqttUrl, '', mqttPort);

//mqtt for documents approvals
mqttForUser() async {
  client.setProtocolV311();
  client.logging(on: true);
  client.keepAlivePeriod = 60000;
  client.autoReconnect = true;

  try {
    await client.connect();
  } on NoConnectionException catch (e) {
    debugPrint(e.toString());
    client.connect();
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    debugPrint('connected');
  } else {
    client.connect();
  }

  void onconnected() {
    debugPrint('connected');
  }

  client.subscribe(
      'trip_status_' + userDetails['id'].toString(), MqttQos.atLeastOnce);
  client.subscribe(
      'new_message_' + userDetails['id'].toString(), MqttQos.atLeastOnce);

  client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
    final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;

    final pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    if (c[0].topic == 'trip_status_' + userDetails['id'].toString()) {
      if (jsonDecode(pt)["success_message"] == "no_driver_found") {
        noDriverFound = true;
        userRequestData = {};
        audioPlayer.play(DeviceFileSource(audio));
        valueNotifierBook.incrementNotifier();
        client.disconnect();
      } else if (jsonDecode(pt)['success_message'] ==
          'request_cancelled_by_driver') {
        requestCancelledByDriver = true;
        audioPlayer.play(DeviceFileSource(audio));
        userRequestData = {};
        valueNotifierBook.incrementNotifier();
        client.disconnect();
      } else {
        audioPlayer.play(DeviceFileSource(audio));
        getUserDetails();
      }
    } else if (c[0].topic == 'new_message_' + userDetails['id'].toString()) {
      if (jsonDecode(pt)["success_message"] == "new_message") {
        chatList = jsonDecode(pt)['data'];
        audioPlayer.play(DeviceFileSource(audio));
        valueNotifierBook.incrementNotifier();
      } else {
        audioPlayer.play(DeviceFileSource(audio));
      }
    }
  });

  client.onConnected = onconnected;
}

class ValueNotifying {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifying valueNotifier = ValueNotifying();

class ValueNotifyingHome {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingHome valueNotifierHome = ValueNotifyingHome();

class ValueNotifyingBook {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingBook valueNotifierBook = ValueNotifyingBook();

//user request handler mqtt

userRequest() async {}

//sound
AudioCache audioPlayers = AudioCache();
AudioPlayer audioPlayer = AudioPlayer();

//get reverse geo coding

var pickupAddress = '';
var dropAddress = '';

geoCoding(double lat, double lng) async {
  dynamic result;
  try {
    var response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey'));

    if (response.statusCode == 200) {
      var val = jsonDecode(response.body);
      result = val['results'][0]['formatted_address'];
    } else {
      result = '';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//get address auto fill data

List addAutoFill = [];

getAutoAddress(input, sessionToken, lat, lng) async {
  dynamic response;
  var countryCode = userDetails['country_code'];
  try {
    if (userDetails['country_code'] == null) {
      response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&library=places&key=$mapkey&sessiontoken=$sessionToken'));
    } else {
      response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&library=places&location=$lat%2C$lng&radius=2000&components=country:$countryCode&key=$mapkey&sessiontoken=$sessionToken'));
    }
    if (response.statusCode == 200) {
      addAutoFill = jsonDecode(response.body)['predictions'];
      valueNotifierHome.incrementNotifier();
    } else {
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//geocodeing location

geoCodingForLatLng(placeid) async {
  try {
    var response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeid&key=$mapkey'));

    if (response.statusCode == 200) {
      var val = jsonDecode(response.body)['result']['geometry']['location'];
      center = LatLng(val['lat'], val['lng']);
      // valueNotifierHome.incrementNotifier();
    }
    return center;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//pickup drop address list

class AddressList {
  String address;
  LatLng latlng;
  String id;

  AddressList({required this.id, required this.address, required this.latlng});
}

//get polylines

List<LatLng> polyList = [];

getPolylines() async {
  polyList.clear();
  String pickLat = '';
  String pickLng = '';
  String dropLat = '';
  String dropLng = '';
  if (userRequestData.isEmpty) {
    pickLat = addressList
        .firstWhere((element) => element.id == 'pickup')
        .latlng
        .latitude
        .toString();
    pickLng = addressList
        .firstWhere((element) => element.id == 'pickup')
        .latlng
        .longitude
        .toString();
    dropLat = addressList
        .firstWhere((element) => element.id == 'drop')
        .latlng
        .latitude
        .toString();
    dropLng = addressList
        .firstWhere((element) => element.id == 'drop')
        .latlng
        .longitude
        .toString();
  } else {
    pickLat = userRequestData['pick_lat'].toString();
    pickLng = userRequestData['pick_lng'].toString();
    dropLat = userRequestData['drop_lat'].toString();
    dropLng = userRequestData['drop_lng'].toString();
  }

  try {
    var response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?destination=$pickLat%2C$pickLng&origin=$dropLat%2C$dropLng&avoid=ferries|indoor&transit_mode=bus&mode=driving&key=$mapkey'));

    var steps =
        jsonDecode(response.body)['routes'][0]['overview_polyline']['points'];
    decodeEncodedPolyline(steps);

    return polyList;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//polyline decode

Set<Polyline> polyline = {};

List<PointLatLng> decodeEncodedPolyline(String encoded) {
  List<PointLatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  polyline.clear();

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
    polyList.add(p);
  }

  polyline.add(
    Polyline(
        polylineId: const PolylineId('1'),
        color: const Color(0xffFD9898),
        visible: true,
        width: 4,
        points: polyList),
  );
  valueNotifierBook.incrementNotifier();
  return poly;
}

class PointLatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude].
  ///
  const PointLatLng(double latitude, double longitude)
      // ignore: unnecessary_null_comparison
      : assert(latitude != null),
        // ignore: unnecessary_null_comparison
        assert(longitude != null),
        // ignore: unnecessary_this, prefer_initializing_formals
        this.latitude = latitude,
        // ignore: unnecessary_this, prefer_initializing_formals
        this.longitude = longitude;

  /// The latitude in degrees.
  final double latitude;

  /// The longitude in degrees
  final double longitude;

  @override
  String toString() {
    return "lat: $latitude / longitude: $longitude";
  }
}

List etaDetails = [];

//eta request

etaRequest() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/eta'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat': (userRequestData.isNotEmpty)
              ? userRequestData['pick_lat']
              : addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng': (userRequestData.isNotEmpty)
              ? userRequestData['pick_lng']
              : addressList
                  .firstWhere((e) => e.id == 'pickup')
                  .latlng
                  .longitude,
          'drop_lat': (userRequestData.isNotEmpty)
              ? userRequestData['drop_lat']
              : addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
          'drop_lng': (userRequestData.isNotEmpty)
              ? userRequestData['drop_lng']
              : addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
          'ride_type': 1
        }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      result = true;
      valueNotifierBook.incrementNotifier();
    } else {
      if (jsonDecode(response.body)['message'] ==
          "service not available with this location") {
        serviceNotAvailable = true;
      }
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

etaRequestWithPromo() async {
  dynamic result;
  // etaDetails.clear();
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/eta'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
          'ride_type': 1,
          'promo_code': promoCode
        }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else {
      promoStatus = 2;
      promoCode = '';
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//calculate distance

calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  var val = (12742 * asin(sqrt(a))) * 1000;
  return val;
}

Map<String, dynamic> userRequestData = {};

//create request

createRequest() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
          'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'drop_address': addressList.firstWhere((e) => e.id == 'drop').address,
          'request_eta_amount': etaDetails[choosenVehicle]['total']
        }));
    if (response.statusCode == 200) {
      mqttForUser();
      userRequestData = jsonDecode(response.body)['data'];
      result = 'success';

      valueNotifierBook.incrementNotifier();
    } else {
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//create request with promo code

createRequestWithPromo() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
          'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'drop_address': addressList.firstWhere((e) => e.id == 'drop').address,
          'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
          'request_eta_amount': etaDetails[choosenVehicle]['total']
        }));
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      mqttForUser();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else {
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//create request

createRequestLater() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
          'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'drop_address': addressList.firstWhere((e) => e.id == 'drop').address,
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true
        }));
    if (response.statusCode == 200) {
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else {
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//create request with promo code

createRequestLaterPromo() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
          'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'drop_address': addressList.firstWhere((e) => e.id == 'drop').address,
          'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true
        }));
    if (response.statusCode == 200) {
      myMarkers.clear();
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else {
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }

  return result;
}

List<RequestCreate> createRequestList = <RequestCreate>[];

class RequestCreate {
  dynamic pickLat;
  dynamic pickLng;
  dynamic dropLat;
  dynamic dropLng;
  dynamic vehicleType;
  dynamic rideType;
  dynamic paymentOpt;
  dynamic pickAddress;
  dynamic dropAddress;
  dynamic promoCodeId;

  RequestCreate(
      {this.pickLat,
      this.pickLng,
      this.dropLat,
      this.dropLng,
      this.vehicleType,
      this.rideType,
      this.paymentOpt,
      this.pickAddress,
      this.dropAddress,
      this.promoCodeId});

  Map<String, dynamic> toJson() => {
        'pick_lat': pickLat,
        'pick_lng': pickLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'vehicle_type': vehicleType,
        'ride_type': rideType,
        'payment_opt': paymentOpt,
        'pick_address': pickAddress,
        'drop_address': dropAddress,
        'promocode_id': promoCodeId
      };
}

//user cancel request

cancelRequest() async {
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'request_id': userRequestData['id']}));
    if (response.statusCode == 200) {
      userRequestData = {};
      client.disconnect();
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

cancelLaterRequest(val) async {
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'request_id': val}));
    if (response.statusCode == 200) {
      userRequestData = {};
      client.disconnect();
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//user cancel request with reason

cancelRequestWithReason(reason) async {
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'request_id': userRequestData['id'], 'reason': reason}));
    if (response.statusCode == 200) {
      cancelRequestByUser = true;
      userRequestData = {};
      client.disconnect();
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//making call to user

makingPhoneCall(phnumber) async {
  var mobileCall = 'tel:' + phnumber;
  if (await canLaunch(mobileCall)) {
    await launch(mobileCall);
  } else {
    throw 'Could not launch $mobileCall';
  }
}

//cancellation reason
List cancelReasonsList = [];
cancelReason(reason) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(url + 'api/v1/common/cancallation/reasons?arrived=$reason'),
      headers: {
        'Authorization': 'Bearer ' + bearerToken[0].token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      cancelReasonsList = jsonDecode(response.body)['data'];
      result = true;
    } else {
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

List<CancelReasonJson> cancelJson = <CancelReasonJson>[];

class CancelReasonJson {
  dynamic requestId;
  dynamic reason;

  CancelReasonJson({this.requestId, this.reason});

  Map<String, dynamic> toJson() {
    return {'request_id': requestId, 'reason': reason};
  }
}

//add user rating

userRating() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/rating'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'request_id': userRequestData['id'],
          'rating': review,
          'comment': feedback
        }));
    if (response.statusCode == 200) {
      client.disconnect();
      await getUserDetails();
      result = true;
    } else {
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//class for realtime database driver data

class NearByDriver {
  double bearing;
  String g;
  String id;
  List l;
  String updatedAt;

  NearByDriver(
      {required this.bearing,
      required this.g,
      required this.id,
      required this.l,
      required this.updatedAt});

  factory NearByDriver.fromJson(Map<String, dynamic> json) {
    return NearByDriver(
        id: json['id'],
        bearing: json['bearing'],
        g: json['g'],
        l: json['l'],
        updatedAt: json['updated_at']);
  }
}

//add favourites location

addFavLocation(lat, lng, add, name) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse(url + 'api/v1/user/add-favourite-location'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'pick_lat': lat,
          'pick_lng': lng,
          'pick_address': add,
          'address_name': name
        }));
    if (response.statusCode == 200) {
      result = true;
      await getUserDetails();
      valueNotifierHome.incrementNotifier();
    } else {
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//sos data
List sosData = [];

getSosData(lat, lng) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(url + 'api/v1/common/sos/list/$lat/$lng'),
      headers: {
        'Authorization': 'Bearer ' + bearerToken[0].token,
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      sosData = jsonDecode(response.body)['data'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//sos admin notification

notifyAdmin() async {
  var db = FirebaseDatabase.instance.ref();
  // var result;

  try {
    await db.child('SOS/' + userRequestData['id']).update({
      "is_driver": "0",
      "is_user": "1",
      "req_id": userRequestData['id'],
      "serv_loc_id": userRequestData['service_location_id'],
      "updated_at": ServerValue.timestamp
    });
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return true;
}

//get current ride messages

List chatList = [];

getCurrentMessages() async {
  try {
    var response = await http.get(
      Uri.parse(url + 'api/v1/request/chat-history/' + userRequestData['id']),
      headers: {
        'Authorization': 'Bearer ' + bearerToken[0].token,
        'Content-Type': 'application/json'
      },
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        chatList = jsonDecode(response.body)['data'];
        valueNotifierBook.incrementNotifier();
      }
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//send chat

sendMessage(chat) async {
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/request/send'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        },
        body:
            jsonEncode({'request_id': userRequestData['id'], 'message': chat}));
    if (response.statusCode == 200) {
      getCurrentMessages();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//message seen

messageSeen() async {
  var response = await http.post(Uri.parse(url + 'api/v1/request/seen'),
      headers: {
        'Authorization': 'Bearer ' + bearerToken[0].token,
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'request_id': userRequestData['id']}));
  if (response.statusCode == 200) {
    getCurrentMessages();
  }
}

//add sos

addSos(name, number) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/common/sos/store'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'name': name, 'number': number}));

    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//remove sos

deleteSos(id) async {
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse(url + 'api/v1/common/sos/delete/' + id), headers: {
      'Authorization': 'Bearer ' + bearerToken[0].token,
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//open url in browser

openBrowser(browseUrl) async {
  if (await canLaunch(browseUrl)) {
    await launch(browseUrl);
  } else {
    throw 'Could not launch $browseUrl';
  }
}

//get faq
List faqData = [];

getFaqData(lat, lng) async {
  dynamic result;
  try {
    var response = await http
        .get(Uri.parse(url + 'api/v1/common/faq/list/$lat/$lng'), headers: {
      'Authorization': 'Bearer ' + bearerToken[0].token,
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      faqData = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
    return result;
  }
}

//remove fav address

removeFavAddress(id) async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse(url + 'api/v1/user/delete-favourite-location/$id'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        });
    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//get user referral

Map<String, dynamic> myReferralCode = {};
getReferral() async {
  dynamic result;
  try {
    var response =
        await http.get(Uri.parse(url + 'api/v1/get/referral'), headers: {
      'Authorization': 'Bearer ' + bearerToken[0].token,
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      result = 'success';
      myReferralCode = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//user logout

userLogout() async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse(url + 'api/v1/logout'), headers: {
      'Authorization': 'Bearer ' + bearerToken[0].token,
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      pref.remove('Bearer');

      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//request history
List myHistory = [];
Map<String, dynamic> myHistoryPage = {};

getHistory(id) async {
  dynamic result;

  try {
    var response = await http.get(Uri.parse(url + 'api/v1/request/history?$id'),
        headers: {'Authorization': 'Bearer ' + bearerToken[0].token});
    if (response.statusCode == 200) {
      myHistory = jsonDecode(response.body)['data'];
      myHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else {
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getHistoryPages(id) async {
  dynamic result;

  try {
    var response = await http.get(Uri.parse(url + 'api/v1/request/history?$id'),
        headers: {'Authorization': 'Bearer ' + bearerToken[0].token});
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body)['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        myHistory.add(element);
      });
      myHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else {
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//get wallet history

Map<String, dynamic> walletBalance = {};
List walletHistory = [];
Map<String, dynamic> walletPages = {};

getWalletHistory() async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse(url + 'api/v1/payment/wallet/history'),
        headers: {'Authorization': 'Bearer ' + bearerToken[0].token});
    if (response.statusCode == 200) {
      walletBalance = jsonDecode(response.body);
      walletHistory = walletBalance['wallet_history']['data'];
      walletPages = walletBalance['wallet_history']['meta']['pagination'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else {
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getWalletHistoryPage(page) async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse(url + 'api/v1/payment/wallet/history?page=$page'),
        headers: {'Authorization': 'Bearer ' + bearerToken[0].token});
    if (response.statusCode == 200) {
      walletBalance = jsonDecode(response.body);
      List list = walletBalance['wallet_history']['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        walletHistory.add(element);
      });
      walletPages = walletBalance['wallet_history']['meta']['pagination'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else {
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//get client token for braintree

getClientToken() async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse(url + 'api/v1/payment/client/token'),
        headers: {'Authorization': 'Bearer ' + bearerToken[0].token});
    if (response.statusCode == 200) {
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//stripe payment

Map<String, dynamic> stripeToken = {};

getStripePayment(money) async {
  dynamic results;
  try {
    var response =
        await http.post(Uri.parse(url + 'api/v1/payment/stripe/intent'),
            headers: {
              'Authorization': 'Bearer ' + bearerToken[0].token,
              'Content-Type': 'application/json'
            },
            body: jsonEncode({'amount': money}));
    if (response.statusCode == 200) {
      results = 'success';
      stripeToken = jsonDecode(response.body)['data'];
    } else {
      results = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      results = 'no internet';
      internet = false;
    }
  }
  return results;
}

//stripe add money

addMoneyStripe(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse(url + 'api/v1/payment/stripe/add/money'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//paystack payment
Map<String,dynamic> paystackCode = {};


getPaystackPayment(money)async{
  dynamic results;
  paystackCode.clear();
  try {
    var response =
        await http.post(Uri.parse(url + 'api/v1/payment/paystack/initialize'),
            headers: {
              'Authorization': 'Bearer ' + bearerToken[0].token,
              'Content-Type': 'application/json'
            },
            body: jsonEncode({'amount': money}));
    if (response.statusCode == 200) {
      results = 'success';
      paystackCode = jsonDecode(response.body)['data'];
    } else {
      results = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      results = 'no internet';
      internet = false;
    }
  }
  return results;
}

addMoneyPaystack(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse(url + 'api/v1/payment/paystack/add-money'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      paystackCode.clear();
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//flutterwave

addMoneyFlutterwave(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse(url + 'api/v1/payment/flutter-wave/add-money'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      paystackCode.clear();
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//razorpay

addMoneyRazorpay(amount, nonce) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse(url + 'api/v1/payment/razerpay/add-money'),
        headers: {
          'Authorization': 'Bearer ' + bearerToken[0].token,
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      paystackCode.clear();
      result = 'success';
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//cashfree

Map<String,dynamic> cftToken = {};

getCfToken(money, currency)async{
  cftToken.clear();
  cfSuccessList.clear();
  dynamic result;
  try{
    var response =await http.post(Uri.parse(url + 'api/v1/payment/cashfree/generate-cftoken'),
   headers: {
              'Authorization': 'Bearer ' + bearerToken[0].token,
              'Content-Type': 'application/json'
            },
  body: jsonEncode({
    'order_amount' : money,
    'order_currency': currency
  })
            );
  if(response.statusCode == 200){
    if(jsonDecode(response.body)['status'] == 'OK'){
      cftToken = jsonDecode(response.body);
      result = 'success';
    }else{
      result = 'failure';
    }
    
  }else{
    result = 'failure';
  }
  }catch(e){
    if(e is SocketException){
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

Map<String,dynamic> cfSuccessList = {};

cashFreePaymentSuccess()async{
  dynamic result;
  try{
    var response = await http.post(Uri.parse(url + 'api/v1/payment/cashfree/add-money-to-wallet-webhooks'),
    headers: {
              'Authorization': 'Bearer ' + bearerToken[0].token,
              'Content-Type': 'application/json'
            },
    body: jsonEncode({
      'orderId' : cfSuccessList['orderId'],
      'orderAmount':cfSuccessList['orderAmount'],
      'referenceId':cfSuccessList['referenceId'],
      'txStatus':cfSuccessList['txStatus'],
      'paymentMode':cfSuccessList['paymentMode'],
      'txMsg':cfSuccessList['txMsg'],
      'txTime':cfSuccessList['txTime'],
      'signature':cfSuccessList['signature']
    })
    );
    if(response.statusCode == 200){
      if(jsonDecode(response.body)['success'] == true){
        result = 'success';
        await getWalletHistory();
        await getUserDetails();
      }else{
        result = 'failure';
      }
    }else{
      result = 'failure';
    }
  }catch(e){
    if(e is SocketException){
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//edit user profile

updateProfile(name, email) async {
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse(url + 'api/v1/user/profile'),
    );
    response.headers
        .addAll({'Authorization': 'Bearer ' + bearerToken[0].token});
    response.files
        .add(await http.MultipartFile.fromPath('profile_picture', imageFile));
    response.fields['email'] = email;
    response.fields['name'] = name;
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      result = 'success';
      if (val['success'] == true) {
        await getUserDetails();
      }
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
    }
  }
  return result;
}

updateProfileWithoutImage(name, email) async {
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse(url + 'api/v1/user/driver-profile'),
    );
    response.headers
        .addAll({'Authorization': 'Bearer ' + bearerToken[0].token});
    response.fields['email'] = email;
    response.fields['name'] = name;
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      result = 'success';
      if (val['success'] == true) {
        await getUserDetails();
      }
    } else {
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
    }
  }
  return result;
}

//internet true
internetTrue() {
  internet = true;
  valueNotifierHome.incrementNotifier();
}

//make complaint

List generalComplaintList = [];
getGeneralComplaint(type) async {
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(url + 'api/v1/common/complaint-titles?complaint_type=$type'),
      headers: {'Authorization': 'Bearer ' + bearerToken[0].token},
    );
    if (response.statusCode == 200) {
      generalComplaintList = jsonDecode(response.body)['data'];
      result = 'success';
    } else {
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

makeGeneralComplaint() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse(url + 'api/v1/common/make-complaint'),
            headers: {
              'Authorization': 'Bearer ' + bearerToken[0].token,
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'complaint_title_id': generalComplaintList[complaintType]['id'],
              'description': complaintDesc,
            }));
    if (response.statusCode == 200) {
      result = 'success';
    } else {
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

makeRequestComplaint() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse(url + 'api/v1/common/make-complaint'),
            headers: {
              'Authorization': 'Bearer ' + bearerToken[0].token,
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'complaint_title_id': generalComplaintList[complaintType]['id'],
              'description': complaintDesc,
              'request_id': myHistory[selectedHistory]['id']
            }));
    if (response.statusCode == 200) {
      result = 'success';
    } else {
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}
