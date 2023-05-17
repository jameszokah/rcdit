import 'dart:typed_data';
import 'package:rcdit_user/pages/onTripPage/booking_confirmation.dart';
import 'package:rcdit_user/pages/onTripPage/drop_loc_select.dart';
import 'package:rcdit_user/pages/login/login.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/functions/geohash.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:rcdit_user/widgets/widgets.dart';
import 'dart:ui' as ui;
import '../navDrawer/nav_drawer.dart';
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:permission_handler/permission_handler.dart' as perm;

class Maps extends StatefulWidget {
  const Maps({Key? key}) : super(key: key);

  @override
  _MapsState createState() => _MapsState();
}

dynamic currentLocation;
LatLng center = const LatLng(41.4219057, -102.0840772);
String mapStyle = '';
List myMarkers = [];
Set<Marker> markers = {};
String dropAddressConfirmation = '';
List<AddressList> addressList = <AddressList>[];
dynamic favLat;
dynamic favLng;
String favSelectedAddress = '';
String favName = 'Home';
String favNameText = '';
bool requestCancelledByDriver = false;
bool cancelRequestByUser = false;
bool logout = false;

class _MapsState extends State<Maps> with WidgetsBindingObserver {
  LatLng _centerLocation = const LatLng(41.4219057, -102.0840772);
 

  dynamic _sessionToken;
  bool _loading = false;
  bool _pickaddress = false;
  bool _dropaddress = false;
  bool _dropLocationMap = false;
  bool _locationDenied = false;
  int gettingPerm = 0;
  late bool serviceEnabled;
  late PermissionStatus permission;
  Location location = Location();
  String state = '';
  GoogleMapController? _controller;

  late BitmapDescriptor pinLocationIcon;
  dynamic userLocationIcon;
  bool favAddressAdd = false;

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);

    getLocs();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
      }
      if (timerLocation == null) {
        getCurrentLocation();
      }
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

//get location permission and location details
  getLocs() async {
    serviceEnabled = await location.serviceEnabled();
    polyline.clear();

    permission = await location.hasPermission();

    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever ||
        serviceEnabled == false) {
      gettingPerm++;
      if (gettingPerm >= 2) {
        setState(() {
          _locationDenied = true;
        });
      }
      setState(() {
        state = '2';
        _loading = false;
      });
    } else if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      var locs = await geolocs.Geolocator.getLastKnownPosition();
      if (locs != null) {
        setState(() {
          center = LatLng(double.parse(locs.latitude.toString()),
              double.parse(locs.longitude.toString()));
          _centerLocation = LatLng(double.parse(locs.latitude.toString()),
              double.parse(locs.longitude.toString()));
          currentLocation = LatLng(double.parse(locs.latitude.toString()),
              double.parse(locs.longitude.toString()));
        });
      } else {
        var loc = await geolocs.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocs.LocationAccuracy.low);
        setState(() {
          center = LatLng(double.parse(loc.latitude.toString()),
              double.parse(loc.longitude.toString()));
          _centerLocation = LatLng(double.parse(loc.latitude.toString()),
              double.parse(loc.longitude.toString()));
          currentLocation = LatLng(double.parse(loc.latitude.toString()),
              double.parse(loc.longitude.toString()));
        });
      }
      BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(devicePixelRatio: 5),
              'assets/images/userloc.png')
          .then((value) {
        setState(() {
          userLocationIcon = value;
        });
      });
      
      final Uint8List markerIcon =
          await getBytesFromAsset('assets/images/top-taxi.png', 40);
      pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);

      setState(() {
        state = '3';
        _loading = false;
      });
      if (timerLocation == null) {
        getCurrentLocation();
      }
    }
  }

  int _bottom = 0;

  GeoHasher geo = GeoHasher();

  @override
  Widget build(BuildContext context) {
    double lat = 0.0144927536231884;
    double lon = 0.0181818181818182;
    double lowerLat = center.latitude - (lat * 6.2);
    double lowerLon = center.longitude - (lon * 6.2);

    double greaterLat = center.latitude + (lat * 6.2);
    double greaterLon = center.longitude + (lon * 6.2);
    var lower = geo.encode(lowerLon, lowerLat);
    var higher = geo.encode(greaterLon, greaterLat);

    var fdb = FirebaseDatabase.instance
        .ref('drivers')
        .orderByChild('g')
        .startAt(lower)
        .endAt(higher);

    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        if (_bottom == 1) {
          setState(() {
            _bottom = 0;
          });
          return false;
        }
        return false;
      },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              if (userRequestData.isNotEmpty &&
                  userRequestData['is_later'] == 1 &&
                  userRequestData['is_completed'] != 1 &&
                  userRequestData['accepted_at'] != null) {
                mqttForUser();
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BookingConfirmation()),
                      (route) => false);
                });
              }
              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  drawer: const NavDrawer(),
                  body: Stack(
                    children: [
                      Container(
                        color: page,
                        height: media.height * 1,
                        width: media.width * 1,
                        child: Column(
                            mainAxisAlignment: (state == '1' || state == '2')
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              (state == '1')
                                  ? Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.05),
                                        width: media.width * 0.6,
                                        height: media.width * 0.3,
                                        decoration: BoxDecoration(
                                            color: page,
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 5,
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  spreadRadius: 2)
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              languages[choosenLanguage]
                                                  ['text_enable_location'],
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              alignment: Alignment.centerRight,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    state = '';
                                                  });
                                                  getLocs();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_ok'],
                                                  style: GoogleFonts.roboto(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          media.width * twenty,
                                                      color: buttonColor),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  : (state == '2')
                                      ? Container(
                                          padding: EdgeInsets.all(
                                              media.width * 0.025),
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                height: media.height * 0.31,
                                                child: Image.asset(
                                                  'assets/images/allow_location_permission.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_trustedtaxi'],
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * eighteen,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.025,
                                              ),
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_allowpermission1'],
                                                style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * fourteen,
                                                ),
                                              ),
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_allowpermission2'],
                                                style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * fourteen,
                                                ),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                        height:
                                                            media.width * 0.075,
                                                        width:
                                                            media.width * 0.075,
                                                        child: const Icon(Icons
                                                            .location_on_outlined)),
                                                    SizedBox(
                                                      width:
                                                          media.width * 0.025,
                                                    ),
                                                    SizedBox(
                                                      width: media.width * 0.7,
                                                      child: Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_loc_permission_user'],
                                                        style:
                                                            GoogleFonts.roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  child: Button(
                                                      onTap: () async {
                                                        if (serviceEnabled ==
                                                            false) {
                                                          await location
                                                              .requestService();
                                                        }
                                                        if (permission ==
                                                                PermissionStatus
                                                                    .denied ||
                                                            permission ==
                                                                PermissionStatus
                                                                    .deniedForever) {
                                                          await location
                                                              .requestPermission();
                                                        }
                                                        setState(() {
                                                          _loading = true;
                                                        });
                                                        getLocs();
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_allow']))
                                            ],
                                          ),
                                        )
                                      : (state == '3')
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                    height: media.height * 1,
                                                    width: media.width * 1,
                                                    child: StreamBuilder<
                                                            DatabaseEvent>(
                                                        stream: fdb.onValue,
                                                        builder: (context,
                                                            AsyncSnapshot<
                                                                    DatabaseEvent>
                                                                event) {
                                                          if (event.hasData) {
                                                            myMarkers.removeWhere(
                                                                (element) => element
                                                                    .markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car'));
                                                            List driverData =
                                                                [];
                                                            event.data!.snapshot
                                                                .children
                                                                // ignore: avoid_function_literals_in_foreach_calls
                                                                .forEach(
                                                                    (element) {
                                                              driverData.add(
                                                                  element
                                                                      .value);
                                                            });
                                                            // ignore: avoid_function_literals_in_foreach_calls
                                                            driverData.forEach(
                                                                (element) {
                                                              if (element['is_active'] ==
                                                                      1 &&
                                                                  element['is_available'] ==
                                                                      true) {
                                                                DateTime dt = DateTime
                                                                    .fromMillisecondsSinceEpoch(
                                                                        element[
                                                                            'updated_at']);

                                                                if (DateTime.now()
                                                                        .difference(
                                                                            dt)
                                                                        .inMinutes <=
                                                                    2) {
                                                                  myMarkers.add(
                                                                      Marker(
                                                                    markerId: MarkerId('car' +
                                                                        element['id']
                                                                            .toString()),
                                                                    rotation: double.parse(
                                                                        element['bearing']
                                                                            .toString()),
                                                                    position: LatLng(
                                                                        element['l']
                                                                            [0],
                                                                        element['l']
                                                                            [
                                                                            1]),
                                                                    icon:
                                                                        pinLocationIcon,
                                                                  ));
                                                                }
                                                              }
                                                            });
                                                          }
                                                          return GoogleMap(
                                                            onMapCreated:
                                                                _onMapCreated,
                                                            compassEnabled:
                                                                false,
                                                            initialCameraPosition:
                                                                CameraPosition(
                                                              target: center,
                                                              zoom: 14.0,
                                                            ),
                                                            onCameraMove:
                                                                (CameraPosition
                                                                    position) {
                                                              _centerLocation =
                                                                  position
                                                                      .target;
                                                            },
                                                            onCameraIdle:
                                                                () async {
                                                              if (_bottom ==
                                                                      0 &&
                                                                  _pickaddress ==
                                                                      false) {
                                                                var val = await geoCoding(
                                                                    _centerLocation
                                                                        .latitude,
                                                                    _centerLocation
                                                                        .longitude);
                                                                setState(() {
                                                                  if (addressList
                                                                      .where((element) =>
                                                                          element
                                                                              .id ==
                                                                          'pickup')
                                                                      .isNotEmpty) {
                                                                    var add = addressList.firstWhere((element) =>
                                                                        element
                                                                            .id ==
                                                                        'pickup');
                                                                    add.address =
                                                                        val;
                                                                    add.latlng = LatLng(
                                                                        _centerLocation
                                                                            .latitude,
                                                                        _centerLocation
                                                                            .longitude);
                                                                  } else {
                                                                    addressList.add(AddressList(
                                                                        id:
                                                                            'pickup',
                                                                        address:
                                                                            val,
                                                                        latlng: LatLng(
                                                                            _centerLocation.latitude,
                                                                            _centerLocation.longitude)));
                                                                  }
                                                                });
                                                              } else if (_pickaddress ==
                                                                  true) {
                                                                setState(() {
                                                                  _pickaddress =
                                                                      false;
                                                                });
                                                              }
                                                            },
                                                            minMaxZoomPreference:
                                                                const MinMaxZoomPreference(
                                                                    8.0, 20.0),
                                                            myLocationButtonEnabled:
                                                                false,
                                                            markers:
                                                                Set<Marker>.from(
                                                                    myMarkers),
                                                            buildingsEnabled:
                                                                false,
                                                            zoomControlsEnabled:
                                                                false,
                                                            myLocationEnabled:
                                                                true,
                                                          );
                                                        })),
                                                Positioned(
                                                    top: 0,
                                                    child: Container(
                                                        height:
                                                            media.height * 1,
                                                        width: media.width * 1,
                                                        alignment:
                                                            Alignment.center,
                                                        child: (_dropLocationMap ==
                                                                false)
                                                            ? Image.asset(
                                                                'assets/images/pickupmarker.png',
                                                                width: media
                                                                        .width *
                                                                    0.07,
                                                              )
                                                            : Image.asset(
                                                                'assets/images/dropmarker.png'))),
                                                Positioned(
                                                    top: 0,
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                          milliseconds: 400),
                                                      width: media.width * 1,
                                                      decoration: BoxDecoration(
                                                        color: (_bottom == 0)
                                                            ? null
                                                            : page,
                                                      ),
                                                      padding: EdgeInsets.only(
                                                          top: MediaQuery.of(
                                                                      context)
                                                                  .padding
                                                                  .top +
                                                              12.5),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                _bottom = 1;
                                                                _dropaddress =
                                                                    false;
                                                                addAutoFill
                                                                    .clear();
                                                                if (_pickaddress ==
                                                                    false) {
                                                                  _dropLocationMap =
                                                                      false;
                                                                  _sessionToken =
                                                                      const Uuid()
                                                                          .v4();
                                                                  _pickaddress =
                                                                      true;
                                                                }
                                                              });
                                                            },
                                                            child:
                                                                AnimatedContainer(
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          400),
                                                              margin: EdgeInsets.only(
                                                                  left: media
                                                                          .width *
                                                                      0.05,
                                                                  right: media
                                                                          .width *
                                                                      0.05,
                                                                  bottom: media
                                                                          .width *
                                                                      0.05),
                                                              padding: EdgeInsets.fromLTRB(
                                                                  media.width *
                                                                      0.03,
                                                                  media.width *
                                                                      0.01,
                                                                  media.width *
                                                                      0.03,
                                                                  media.width *
                                                                      0.01),
                                                              height:
                                                                  media.width *
                                                                      0.1,
                                                              width: (_bottom ==
                                                                      0)
                                                                  ? media.width *
                                                                      0.75
                                                                  : media.width *
                                                                      0.9,
                                                              decoration: BoxDecoration(
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                        blurRadius: (_bottom ==
                                                                                0)
                                                                            ? 2
                                                                            : 0,
                                                                        color: (_bottom ==
                                                                                0)
                                                                            ? Colors.black.withOpacity(
                                                                                0.2)
                                                                            : Colors
                                                                                .transparent,
                                                                        spreadRadius: (_bottom ==
                                                                                0)
                                                                            ? 2
                                                                            : 0)
                                                                  ],
                                                                  border: Border.all(
                                                                      color: (_bottom ==
                                                                              0)
                                                                          ? page
                                                                          : Colors
                                                                              .grey,
                                                                      width: (_bottom ==
                                                                              0)
                                                                          ? 0
                                                                          : 1.5),
                                                                  color: (_pickaddress ==
                                                                              true &&
                                                                          _bottom ==
                                                                              1)
                                                                      ? Colors.grey[
                                                                          300]
                                                                      : page,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          media.width * 0.02)),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Row(
                                                                children: [
                                                                  Container(
                                                                    height: media
                                                                            .width *
                                                                        0.04,
                                                                    width: media
                                                                            .width *
                                                                        0.04,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: const Color(0xff319900)
                                                                            .withOpacity(0.3)),
                                                                    child:
                                                                        Container(
                                                                      height: media
                                                                              .width *
                                                                          0.02,
                                                                      width: media
                                                                              .width *
                                                                          0.02,
                                                                      decoration: const BoxDecoration(
                                                                          shape: BoxShape
                                                                              .circle,
                                                                          color:
                                                                              Color(0xff319900)),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.02),
                                                                  (_pickaddress ==
                                                                              true &&
                                                                          _bottom ==
                                                                              1)
                                                                      ? Expanded(
                                                                          child: TextField(
                                                                              autofocus: true,
                                                                              decoration: InputDecoration(
                                                                                contentPadding: (languageDirection == 'rtl') ? EdgeInsets.only(bottom: media.width * 0.035) : EdgeInsets.only(bottom: media.width * 0.047),
                                                                                hintText: languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                hintStyle: GoogleFonts.roboto(fontSize: media.width * twelve, color: hintColor),
                                                                                border: InputBorder.none,
                                                                              ),
                                                                              maxLines: 1,
                                                                              onChanged: (val) {
                                                                                if (val.length >= 4) {
                                                                                  getAutoAddress(val, _sessionToken, center.latitude, center.longitude);
                                                                                } else {
                                                                                  setState(() {
                                                                                    addAutoFill.clear();
                                                                                  });
                                                                                }
                                                                              }),
                                                                        )
                                                                      : Expanded(
                                                                          child:
                                                                              Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              SizedBox(
                                                                                width: media.width * 0.55,
                                                                                child: Text(
                                                                                  addressList.firstWhere((element) => element.id == 'pickup', orElse: () => AddressList(id: '', address: '', latlng: const LatLng(0.0, 0.0))).address,
                                                                                  style: GoogleFonts.roboto(
                                                                                    fontSize: media.width * twelve,
                                                                                    color: textColor,
                                                                                  ),
                                                                                  maxLines: 1,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                ),
                                                                              ),
                                                                              (addressList.where((element) => element.id == 'pickup').isNotEmpty && favAddress.length < 4)
                                                                                  ? InkWell(
                                                                                      onTap: () {
                                                                                        if (favAddress.where((element) => element['pick_address'] == addressList.firstWhere((element) => element.id == 'pickup').address).isEmpty) {
                                                                                          setState(() {
                                                                                            favSelectedAddress = addressList.firstWhere((element) => element.id == 'pickup').address;
                                                                                            favLat = addressList.firstWhere((element) => element.id == 'pickup').latlng.latitude;
                                                                                            favLng = addressList.firstWhere((element) => element.id == 'pickup').latlng.longitude;
                                                                                            favAddressAdd = true;
                                                                                          });
                                                                                        }
                                                                                      },
                                                                                      child: Icon(
                                                                                        Icons.favorite_outline,
                                                                                        size: media.width * 0.05,
                                                                                        color: favAddress.where((element) => element['pick_address'] == addressList.firstWhere((element) => element.id == 'pickup').address).isEmpty ? Colors.black : buttonColor,
                                                                                      ),
                                                                                    )
                                                                                  : Container()
                                                                            ],
                                                                          ),
                                                                        )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                                (_bottom == 0)
                                                    ? Positioned(
                                                        top: MediaQuery.of(
                                                                    context)
                                                                .padding
                                                                .top +
                                                            12.5,
                                                        child: SizedBox(
                                                          width:
                                                              media.width * 0.9,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                height: media
                                                                        .width *
                                                                    0.1,
                                                                width: media
                                                                        .width *
                                                                    0.1,
                                                                decoration: BoxDecoration(
                                                                    boxShadow: [
                                                                      (_bottom ==
                                                                              0)
                                                                          ? BoxShadow(
                                                                              blurRadius: (_bottom == 0) ? 2 : 0,
                                                                              color: (_bottom == 0) ? Colors.black.withOpacity(0.2) : Colors.transparent,
                                                                              spreadRadius: (_bottom == 0) ? 2 : 0)
                                                                          : const BoxShadow(),
                                                                    ],
                                                                    color: page,
                                                                    borderRadius:
                                                                        BorderRadius.circular(media.width *
                                                                            0.02)),
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: StatefulBuilder(
                                                                    builder:
                                                                        (context,
                                                                            setState) {
                                                                  return InkWell(
                                                                      onTap:
                                                                          () {
                                                                        Scaffold.of(context)
                                                                            .openDrawer();
                                                                      },
                                                                      child: const Icon(
                                                                          Icons
                                                                              .menu));
                                                                }),
                                                              ),
                                                            ],
                                                          ),
                                                        ))
                                                    : Container(),
                                                Positioned(
                                                    bottom:
                                                        20 + media.width * 0.5,
                                                    child: SizedBox(
                                                      width: media.width * 0.9,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          InkWell(
                                                            onTap: () async {
                                                           
                                                              setState(() {
                                                                
                                                                _controller?.animateCamera(
                                                                    CameraUpdate
                                                                        .newLatLngZoom(
                                                                            currentLocation,
                                                                            14.0));
                                                              });
                                                            },
                                                            child: Container(
                                                              height:
                                                                  media.width *
                                                                      0.1,
                                                              width:
                                                                  media.width *
                                                                      0.1,
                                                              decoration: BoxDecoration(
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                        blurRadius:
                                                                            2,
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(
                                                                                0.2),
                                                                        spreadRadius:
                                                                            2)
                                                                  ],
                                                                  color: page,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          media.width *
                                                                              0.02)),
                                                              child: const Icon(
                                                                  Icons
                                                                      .my_location_sharp),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                                Positioned(
                                                    bottom: 0,
                                                    child: GestureDetector(
                                                      onPanUpdate: (val) {
                                                        if (val.delta.dy > 0) {
                                                          setState(() {
                                                            _bottom = 0;
                                                            addAutoFill.clear();
                                                            _pickaddress =
                                                                false;
                                                            _dropaddress =
                                                                false;
                                                          });
                                                        }
                                                        if (val.delta.dy < 0) {
                                                          setState(() {
                                                            _bottom = 1;
                                                          });
                                                        }
                                                      },
                                                      child: AnimatedContainer(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                media.width *
                                                                    0.05,
                                                                media.width *
                                                                    0.03,
                                                                media.width *
                                                                    0.05,
                                                                0),
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        height: (_bottom == 0)
                                                            ? media.width * 0.5
                                                            : media.height * 1 -
                                                                (MediaQuery.of(
                                                                            context)
                                                                        .padding
                                                                        .top +
                                                                    12.5 +
                                                                    media.width *
                                                                        0.12),
                                                        width: media.width * 1,
                                                        color: page,
                                                        child: Column(
                                                          children: [
                                                            (_bottom == 0)
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.02,
                                                                    width: media
                                                                            .width *
                                                                        0.2,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(media.width *
                                                                              0.01),
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.03,
                                                            ),
                                                            InkWell(
                                                              onTap: () {
                                                                if (addressList
                                                                    .where((element) =>
                                                                        element
                                                                            .id ==
                                                                        'pickup')
                                                                    .isNotEmpty) {
                                                                  setState(() {
                                                                    _pickaddress =
                                                                        false;
                                                                    _dropaddress =
                                                                        true;
                                                                    addAutoFill
                                                                        .clear();
                                                                    _bottom = 1;
                                                                  });
                                                                }
                                                              },
                                                              child: Container(
                                                                  padding: EdgeInsets.fromLTRB(
                                                                      media.width *
                                                                          0.03,
                                                                      media.width *
                                                                          0.01,
                                                                      media.width *
                                                                          0.03,
                                                                      media.width *
                                                                          0.01),
                                                                  height: media
                                                                          .width *
                                                                      0.1,
                                                                  width:
                                                                      media.width *
                                                                          0.9,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                          border: Border
                                                                              .all(
                                                                            color:
                                                                                Colors.grey,
                                                                            width:
                                                                                1.5,
                                                                          ),
                                                                          borderRadius: BorderRadius.circular(media.width *
                                                                              0.02),
                                                                          color: Colors.grey.withOpacity(
                                                                              0.3)),
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: Row(
                                                                    children: [
                                                                      Container(
                                                                        height: media.width *
                                                                            0.04,
                                                                        width: media.width *
                                                                            0.04,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color: const Color(0xffFF0000).withOpacity(0.3)),
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              media.width * 0.02,
                                                                          width:
                                                                              media.width * 0.02,
                                                                          decoration: const BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              color: Color(0xffFF0000)),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          width:
                                                                              media.width * 0.02),
                                                                      (_dropaddress == true &&
                                                                              _bottom == 1)
                                                                          ? Expanded(
                                                                              child: TextField(
                                                                                  autofocus: true,
                                                                                  decoration: InputDecoration(contentPadding: (languageDirection == 'rtl') ? EdgeInsets.only(bottom: media.width * 0.035) : EdgeInsets.only(bottom: media.width * 0.047), border: InputBorder.none, hintText: languages[choosenLanguage]['text_4lettersforautofill'], hintStyle: GoogleFonts.roboto(fontSize: media.width * twelve, color: hintColor)),
                                                                                  maxLines: 1,
                                                                                  onChanged: (val) {
                                                                                    if (val.length >= 4) {
                                                                                      getAutoAddress(val, _sessionToken, center.latitude, center.longitude);
                                                                                    } else {
                                                                                      setState(() {
                                                                                        addAutoFill.clear();
                                                                                      });
                                                                                    }
                                                                                  }),
                                                                            )
                                                                          : Expanded(
                                                                              child: Text(
                                                                              languages[choosenLanguage]['text_4lettersforautofill'],
                                                                              style: GoogleFonts.roboto(fontSize: media.width * twelve, color: hintColor),
                                                                            )),
                                                                    ],
                                                                  )),
                                                            ),
                                                            Expanded(
                                                                child:
                                                                    SingleChildScrollView(
                                                                        physics:
                                                                            const BouncingScrollPhysics(),
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            
                                                                            (addAutoFill.isNotEmpty)
                                                                                ? Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: addAutoFill
                                                                                        .asMap()
                                                                                        .map((i, value) {
                                                                                          return MapEntry(
                                                                                              i,
                                                                                              (i < 5)
                                                                                                  ? Container(
                                                                                                      padding: EdgeInsets.fromLTRB(0, media.width * 0.04, 0, media.width * 0.04),
                                                                                                      child: Row(
                                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                        children: [
                                                                                                          Container(
                                                                                                            height: media.width * 0.1,
                                                                                                            width: media.width * 0.1,
                                                                                                            decoration: BoxDecoration(
                                                                                                              shape: BoxShape.circle,
                                                                                                              color: Colors.grey[200],
                                                                                                            ),
                                                                                                            child: const Icon(Icons.access_time),
                                                                                                          ),
                                                                                                          InkWell(
                                                                                                            onTap: () async {
                                                                                                              var val = await geoCodingForLatLng(addAutoFill[i]['place_id']);

                                                                                                              if (_pickaddress == true) {
                                                                                                                setState(() {
                                                                                                                  if (addressList.where((element) => element.id == 'pickup').isEmpty) {
                                                                                                                    addressList.add(AddressList(id: 'pickup', address: addAutoFill[i]['description'], latlng: val));
                                                                                                                  } else {
                                                                                                                    addressList.firstWhere((element) => element.id == 'pickup').address = addAutoFill[i]['description'];
                                                                                                                    addressList.firstWhere((element) => element.id == 'pickup').latlng = val;
                                                                                                                  }
                                                                                                                });
                                                                                                              } else {
                                                                                                                setState(() {
                                                                                                                  if (addressList.where((element) => element.id == 'drop').isEmpty) {
                                                                                                                    addressList.add(AddressList(id: 'drop', address: addAutoFill[i]['description'], latlng: val));
                                                                                                                  } else {
                                                                                                                    addressList.firstWhere((element) => element.id == 'drop').address = addAutoFill[i]['description'];
                                                                                                                    addressList.firstWhere((element) => element.id == 'drop').latlng = val;
                                                                                                                  }
                                                                                                                });
                                                                                                                if (addressList.length == 2) {
                                                                                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingConfirmation()));
                                                                                                                }
                                                                                                              }
                                                                                                              setState(() {
                                                                                                                addAutoFill.clear();
                                                                                                                _dropaddress = false;

                                                                                                                if (_pickaddress == true) {
                                                                                                                  center = val;
                                                                                                                  _controller?.moveCamera(CameraUpdate.newLatLngZoom(val, 14.0));
                                                                                                                  

                                                                                                                }
                                                                                                                _bottom = 0;
                                                                                                              });
                                                                                                            },
                                                                                                            child: SizedBox(
                                                                                                              width: media.width * 0.7,
                                                                                                              child: Text(addAutoFill[i]['description'],
                                                                                                                  style: GoogleFonts.roboto(
                                                                                                                    fontSize: media.width * twelve,
                                                                                                                    color: textColor,
                                                                                                                  ),
                                                                                                                  maxLines: 2),
                                                                                                            ),
                                                                                                          ),
                                                                                                          (favAddress.length < 4)
                                                                                                              ? InkWell(
                                                                                                                  onTap: () async {
                                                                                                                    if (favAddress.where((e) => e['pick_address'] == addAutoFill[i]['description']).isEmpty) {
                                                                                                                      var val = await geoCodingForLatLng(addAutoFill[i]['place_id']);
                                                                                                                      setState(() {
                                                                                                                        favSelectedAddress = addAutoFill[i]['description'];
                                                                                                                        favLat = val.latitude;
                                                                                                                        favLng = val.longitude;
                                                                                                                        favAddressAdd = true;
                                                                                                                      });
                                                                                                                    }
                                                                                                                  },
                                                                                                                  child: Icon(
                                                                                                                    Icons.favorite_outline,
                                                                                                                    size: media.width * 0.05,
                                                                                                                    color: favAddress.where((element) => element['pick_address'] == addAutoFill[i]['description']).isNotEmpty ? buttonColor : Colors.black,
                                                                                                                  ),
                                                                                                                )
                                                                                                              : Container()
                                                                                                        ],
                                                                                                      ),
                                                                                                    )
                                                                                                  : Container());
                                                                                        })
                                                                                        .values
                                                                                        .toList(),
                                                                                  )
                                                                                : Container(),
                                                                            SizedBox(
                                                                              height: media.width * 0.05,
                                                                            ),
                                                                            (favAddress.isNotEmpty)
                                                                                ? Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      SizedBox(
                                                                                        width: media.width * 0.9,
                                                                                        child: Text(
                                                                                          languages[choosenLanguage][(_pickaddress == true) ? 'text_pick_suggestion' : 'text_drop_suggestion'],
                                                                                          style: GoogleFonts.roboto(
                                                                                            fontSize: media.width * sixteen,
                                                                                            color: textColor,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                          textDirection: (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
                                                                                        ),
                                                                                      ),
                                                                                      Column(
                                                                                        children: favAddress
                                                                                            .asMap()
                                                                                            .map((i, value) {
                                                                                              return MapEntry(
                                                                                                  i,
                                                                                                  InkWell(
                                                                                                    onTap: () async {
                                                                                                      if (_pickaddress == true) {
                                                                                                        setState(() {
                                                                                                          addAutoFill.clear();
                                                                                                          if (addressList.where((element) => element.id == 'pickup').isEmpty) {
                                                                                                            addressList.add(AddressList(id: 'pickup', address: favAddress[i]['pick_address'], latlng: LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng'])));
                                                                                                          } else {
                                                                                                            addressList.firstWhere((element) => element.id == 'pickup').address = favAddress[i]['pick_address'];
                                                                                                            addressList.firstWhere((element) => element.id == 'pickup').latlng = LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']);
                                                                                                          }
                                                                                                          _controller?.moveCamera(CameraUpdate.newLatLngZoom(LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']), 14.0));
                                                                                                        
                                                                                                          _bottom = 0;
                                                                                                        });
                                                                                                      } else {
                                                                                                        setState(() {
                                                                                                          if (addressList.where((element) => element.id == 'drop').isEmpty) {
                                                                                                            addressList.add(AddressList(id: 'drop', address: favAddress[i]['pick_address'], latlng: LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng'])));
                                                                                                          } else {
                                                                                                            addressList.firstWhere((element) => element.id == 'drop').address = favAddress[i]['pick_address'];
                                                                                                            addressList.firstWhere((element) => element.id == 'drop').latlng = LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']);
                                                                                                          }
                                                                                                          addAutoFill.clear();
                                                                                                          _bottom = 0;
                                                                                                        });
                                                                                                        if (addressList.length == 2) {
                                                                                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingConfirmation()));

                                                                                                          dropAddress = favAddress[i]['pick_address'];
                                                                                                        }
                                                                                                      }
                                                                                                    },
                                                                                                    child: Container(
                                                                                                      width: media.width * 0.9,
                                                                                                      padding: EdgeInsets.only(top: media.width * 0.03, bottom: media.width * 0.03),
                                                                                                      child: Column(
                                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                        children: [
                                                                                                          Text(
                                                                                                            favAddress[i]['address_name'],
                                                                                                            style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor),
                                                                                                          ),
                                                                                                          SizedBox(
                                                                                                            height: media.width * 0.03,
                                                                                                          ),
                                                                                                          Row(
                                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                            children: [
                                                                                                              (favAddress[i]['address_name'] == 'Home')
                                                                                                                  ? Image.asset(
                                                                                                                      'assets/images/home.png',
                                                                                                                      color: Colors.black,
                                                                                                                      width: media.width * 0.075,
                                                                                                                    )
                                                                                                                  : (favAddress[i]['address_name'] == 'Work')
                                                                                                                      ? Image.asset(
                                                                                                                          'assets/images/briefcase.png',
                                                                                                                          color: Colors.black,
                                                                                                                          width: media.width * 0.075,
                                                                                                                        )
                                                                                                                      : Image.asset(
                                                                                                                          'assets/images/navigation.png',
                                                                                                                          color: Colors.black,
                                                                                                                          width: media.width * 0.075,
                                                                                                                        ),
                                                                                                              SizedBox(
                                                                                                                width: media.width * 0.8,
                                                                                                                child: Text(
                                                                                                                  favAddress[i]['pick_address'],
                                                                                                                  style: GoogleFonts.roboto(
                                                                                                                    fontSize: media.width * twelve,
                                                                                                                    color: textColor,
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ),
                                                                                                            ],
                                                                                                          ),
                                                                                                        ],
                                                                                                      ),
                                                                                                    ),
                                                                                                  ));
                                                                                            })
                                                                                            .values
                                                                                            .toList(),
                                                                                      ),
                                                                                    ],
                                                                                  )
                                                                                : Container(),
                                                                            SizedBox(
                                                                              height: media.width * 0.05,
                                                                            ),
                                                                            (_bottom == 1)
                                                                                ? InkWell(
                                                                                    onTap: () async {
                                                                                      setState(() {
                                                                                        addAutoFill.clear();

                                                                                        _bottom = 0;
                                                                                      });
                                                                                      if (_dropaddress == true && addressList.where((element) => element.id == 'pickup').isNotEmpty) {
                                                                                        var navigate = await Navigator.push(context, MaterialPageRoute(builder: (context) => const DropLocation()));
                                                                                        if (navigate) {
                                                                                          setState(() {
                                                                                            addressList.removeWhere((element) => element.id == 'drop');
                                                                                          });
                                                                                        }
                                                                                      }
                                                                                    },
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                      children: [
                                                                                        SizedBox(
                                                                                          width: media.width * 0.05,
                                                                                          child: Image.asset(
                                                                                            (_dropaddress == true) ? 'assets/images/dropmarker.png' : 'assets/images/pickupmarker.png',
                                                                                            fit: BoxFit.contain,
                                                                                          ),
                                                                                        ),
                                                                                        SizedBox(
                                                                                          width: media.width * 0.025,
                                                                                        ),
                                                                                        Text(
                                                                                          languages[choosenLanguage]['text_chooseonmap'],
                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: buttonColor),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  )
                                                                                : Container()
                                                                          ],
                                                                        ))),
                                                          ],
                                                        ),
                                                      ),
                                                    )),
                                              ],
                                            )
                                          : Container(),
                            ]),
                      ),

                      //add fav address
                      (favAddressAdd == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height: media.width * 0.1,
                                            width: media.width * 0.1,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: page),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  favName = '';
                                                  favAddressAdd = false;
                                                });
                                              },
                                              child: const Icon(
                                                  Icons.cancel_outlined),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_saveaddressas'],
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.025,
                                          ),
                                          Text(
                                            favSelectedAddress,
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * twelve,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.025,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                  setState(() {
                                                    favName = 'Home';
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.01),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                            media.height * 0.05,
                                                        width:
                                                            media.width * 0.05,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .black,
                                                                width: 1.2)),
                                                        alignment:
                                                            Alignment.center,
                                                        child:
                                                            (favName == 'Home')
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.03,
                                                                    width: media
                                                                            .width *
                                                                        0.03,
                                                                    decoration:
                                                                        const BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.01,
                                                      ),
                                                      Text(languages[
                                                              choosenLanguage]
                                                          ['text_home'])
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                  setState(() {
                                                    favName = 'Work';
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.01),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                            media.height * 0.05,
                                                        width:
                                                            media.width * 0.05,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .black,
                                                                width: 1.2)),
                                                        alignment:
                                                            Alignment.center,
                                                        child:
                                                            (favName == 'Work')
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.03,
                                                                    width: media
                                                                            .width *
                                                                        0.03,
                                                                    decoration:
                                                                        const BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.01,
                                                      ),
                                                      Text(languages[
                                                              choosenLanguage]
                                                          ['text_work'])
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                  setState(() {
                                                    favName = 'Others';
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.01),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                            media.height * 0.05,
                                                        width:
                                                            media.width * 0.05,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .black,
                                                                width: 1.2)),
                                                        alignment:
                                                            Alignment.center,
                                                        child: (favName ==
                                                                'Others')
                                                            ? Container(
                                                                height: media
                                                                        .width *
                                                                    0.03,
                                                                width: media
                                                                        .width *
                                                                    0.03,
                                                                decoration:
                                                                    const BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              )
                                                            : Container(),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.01,
                                                      ),
                                                      Text(languages[
                                                              choosenLanguage]
                                                          ['text_others'])
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          (favName == 'Others')
                                              ? Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.025),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color: borderLines,
                                                          width: 1.2)),
                                                  child: TextField(
                                                    decoration: InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        hintText: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_enterfavname'],
                                                        hintStyle: GoogleFonts
                                                            .roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    twelve,
                                                                color:
                                                                    hintColor)),
                                                    maxLines: 1,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        favNameText = val;
                                                      });
                                                    },
                                                  ),
                                                )
                                              : Container(),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () async {
                                                if (favName == 'Others' &&
                                                    favNameText != '') {
                                                  setState(() {
                                                    _loading = true;
                                                  });
                                                  var val =
                                                      await addFavLocation(
                                                          favLat,
                                                          favLng,
                                                          favSelectedAddress,
                                                          favNameText);
                                                  setState(() {
                                                    _loading = false;
                                                    if (val == true) {
                                                      favLat = '';
                                                      favLng = '';
                                                      favSelectedAddress = '';
                                                      favName = 'Home';
                                                      favNameText = '';
                                                      favAddressAdd = false;
                                                    }
                                                  });
                                                } else if (favName == 'Home' ||
                                                    favName == 'Work') {
                                                  setState(() {
                                                    _loading = true;
                                                  });
                                                  var val =
                                                      await addFavLocation(
                                                          favLat,
                                                          favLng,
                                                          favSelectedAddress,
                                                          favName);
                                                  setState(() {
                                                    _loading = false;
                                                    if (val == true) {
                                                      favLat = '';
                                                      favLng = '';
                                                      favName = 'Home';
                                                      favSelectedAddress = '';
                                                      favNameText = '';
                                                      favAddressAdd = false;
                                                    }
                                                  });
                                                }
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_confirm'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      //driver cancelled request
                      (requestCancelledByDriver == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: media.width * 0.9,
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_drivercancelled'],
                                            style: GoogleFonts.roboto(
                                                fontSize:
                                                    media.width * fourteen,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () {
                                                setState(() {
                                                  requestCancelledByDriver =
                                                      false;
                                                  userRequestData = {};
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_ok'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      //user cancelled request
                      (cancelRequestByUser == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: media.width * 0.9,
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_cancelsuccess'],
                                            style: GoogleFonts.roboto(
                                                fontSize:
                                                    media.width * fourteen,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () {
                                                setState(() {
                                                  cancelRequestByUser = false;
                                                  userRequestData = {};
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_ok'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      //logout
                      (logout == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                              height: media.height * 0.1,
                                              width: media.width * 0.1,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: page),
                                              child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      logout = false;
                                                    });
                                                  },
                                                  child: const Icon(
                                                      Icons.cancel_outlined))),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_confirmlogout'],
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () async {
                                                setState(() {
                                                  logout = false;
                                                  _loading = true;
                                                });
                                                var result = await userLogout();
                                                if (result == 'success') {
                                                  setState(() {
                                                    Navigator.pushAndRemoveUntil(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const Login()),
                                                        (route) => false);
                                                    userDetails.clear();
                                                  });
                                                } else {
                                                  setState(() {
                                                    _loading = false;
                                                    logout = true;
                                                  });
                                                }
                                                setState(() {
                                                  _loading = false;
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_confirm'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),
                      (_locationDenied == true)
                          ? Positioned(
                              child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: page,
                                        boxShadow: [
                                          BoxShadow(
                                              blurRadius: 2.0,
                                              spreadRadius: 2.0,
                                              color:
                                                  Colors.black.withOpacity(0.2))
                                        ]),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                            width: media.width * 0.8,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_open_loc_settings'],
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600),
                                            )),
                                        SizedBox(height: media.width * 0.05),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                                onTap: () async {
                                                  await perm.openAppSettings();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_open_settings'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: buttonColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                )),
                                            InkWell(
                                                onTap: () async {
                                                  setState(() {
                                                    _locationDenied = false;
                                                    _loading = true;
                                                  });

                                                  getLocs();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_done'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: buttonColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ))
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ))
                          : Container(),
                      //loader
                      (_loading == true || state == '')
                          ? const Positioned(top: 0, child: Loading())
                          : Container(),
                      (internet == false)
                          ? Positioned(
                              top: 0,
                              child: NoInternet(
                                onTap: () {
                                  setState(() {
                                    internetTrue();
                                    getUserDetails();
                                  });
                                },
                              ))
                          : Container()
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}
