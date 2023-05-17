import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/functions/geohash.dart';
import 'package:rcdit_user/pages/chatPage/chat_page.dart';
import 'package:rcdit_user/pages/onTripPage/invoice.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/onTripPage/map_page.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';
import 'dart:ui' as ui;
import '../../functions/functions.dart';
import 'package:intl/intl.dart';

class BookingConfirmation extends StatefulWidget {
  const BookingConfirmation({Key? key}) : super(key: key);

  @override
  _BookingConfirmationState createState() => _BookingConfirmationState();
}

bool serviceNotAvailable = false;
String promoCode = '';
dynamic promoStatus;
dynamic choosenVehicle;
int payingVia = 0;
dynamic timing;

bool noDriverFound = false;
var driverData = {};
dynamic choosenDateTime;
bool lowWalletBalance = false;
bool tripReqError = false;

class _BookingConfirmationState extends State<BookingConfirmation>
    with WidgetsBindingObserver {
  TextEditingController promoKey = TextEditingController();
  final Map minutes = {};
  List myMarker = [];
  String _cancelReason = '';
  GoogleMapController? _controller;
  late bool serviceEnabled;
  late PermissionStatus permission;
  Location location = Location();
  bool _isLoading = false;
  LatLng _center = const LatLng(41.4219057, -102.0840772);
  dynamic pinLocationIcon;

  bool _ontripBottom = false;
  bool _cancelling = false;
  bool _choosePayment = false;
  String _cancelCustomReason = '';
  dynamic timers;
  bool _bottomChooseMethod = false;
  bool _dateTimePicker = false;
  bool _rideLaterSuccess = false;
  bool _confirmRideLater = false;
  bool _etaDetailsgot = false;
  bool showSos = false;
  bool notifyCompleted = false;
  bool _showInfo = false;
  dynamic _showInfoInt;
  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    promoCode = '';
    serviceNotAvailable = false;
    noDriverFound = false;
    getLocs();

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
      }
      getUserDetails();
      if (timers == null &&
          userRequestData.isNotEmpty &&
          userRequestData['accepted_at'] == null) {
        timer();
      }
      if (timerLocation == null) {
        getCurrentLocation();
      }
    }
  }

  @override
  void dispose() {
    if (timers != null) {
      timers.cancel;
    }
    super.dispose();
  }

//running timer
  timer() {
    timing = 300;

    if (mounted) {
      timers = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (userRequestData.isNotEmpty &&
            userDetails['accepted_at'] == null &&
            timing > 0) {
          timing--;
          valueNotifierBook.incrementNotifier();
        } else if (userRequestData.isNotEmpty &&
            userRequestData['accepted_at'] == null &&
            timing == 0) {
          setState(() {
            noDriverFound = true;
          });
          cancelRequest();
          timers.cancel();
        } else {
          timers.cancel();
        }
      });
    }
  }

//create icon
  Future<BitmapDescriptor> getCustomIcon(GlobalKey iconKeys) async {
    Future<Uint8List> _capturePng(GlobalKey iconKeys) async {
      dynamic pngBytes;
      try {
        RenderRepaintBoundary boundary = iconKeys.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData!.buffer.asUint8List();

        return pngBytes;
      } catch (e) {
        debugPrint(e.toString());
      }
      return pngBytes;
    }

    Uint8List imageData = await _capturePng(iconKeys);

    return BitmapDescriptor.fromBytes(imageData);
  }

  GlobalKey iconKey = GlobalKey();
  GlobalKey iconDropKey = GlobalKey();

  addDropMarker() async {
    BitmapDescriptor testIcon = await getCustomIcon(iconDropKey);
    setState(() {
      myMarker.add(Marker(
          markerId: const MarkerId('pointdrop'),
          icon: testIcon,
          position: (userRequestData.isEmpty)
              ? addressList.firstWhere((element) => element.id == 'drop').latlng
              : LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng'])));
    });
  }

  addMarker() async {
    BitmapDescriptor testIcon = await getCustomIcon(iconKey);
    setState(() {
      myMarker.add(Marker(
          markerId: const MarkerId('pointpick'),
          icon: testIcon,
          position: (userRequestData.isEmpty)
              ? addressList
                  .firstWhere((element) => element.id == 'pickup')
                  .latlng
              : LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng'])));
    });
  }

//add drop marker
  addPickDropMarker() async {
    addMarker();
    addDropMarker();
    getPolylines();
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
    setState(() {
      _center = (userRequestData.isEmpty)
          ? addressList.firstWhere((element) => element.id == 'pickup').latlng
          : LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']);
    });
    choosenVehicle = 0;
    etaDetails.clear();
    etaRequest();

    permission = await location.hasPermission();

    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever) {
      setState(() {});
    } else if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      // var loc = await location.getLocation();

      final Uint8List markerIcon =
          await getBytesFromAsset('assets/images/top-taxi.png', 40);
      pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);

      Future.delayed(const Duration(milliseconds: 1000), () async {
        await addPickDropMarker();
        _etaDetailsgot = true;
      });
      if (timerLocation == null) {
        getCurrentLocation();
      }
      setState(() {});
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    _controller!.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      check(u, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    GeoHasher geo = GeoHasher();

    double lat = 0.0144927536231884;
    double lon = 0.0181818181818182;
    double lowerLat = (userRequestData.isEmpty)
        ? addressList
                .firstWhere((element) => element.id == 'pickup')
                .latlng
                .latitude -
            (lat * 6.2)
        : userRequestData['pick_lat'] - (lat * 6.2);
    double lowerLon = (userRequestData.isEmpty)
        ? addressList
                .firstWhere((element) => element.id == 'pickup')
                .latlng
                .longitude -
            (lon * 6.2)
        : userRequestData['pick_lng'] - (lon * 6.2);

    double greaterLat = (userRequestData.isEmpty)
        ? addressList
                .firstWhere((element) => element.id == 'pickup')
                .latlng
                .latitude +
            (lat * 6.2)
        : userRequestData['pick_lat'] - (lat * 6.2);
    double greaterLon = (userRequestData.isEmpty)
        ? addressList
                .firstWhere((element) => element.id == 'pickup')
                .latlng
                .longitude +
            (lon * 6.2)
        : userRequestData['pick_lng'] - (lat * 6.2);
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
        if (userRequestData.isEmpty) {
          setState(() {
            addressList.removeWhere((element) => element.id == 'drop');
            myMarker.removeWhere(
                (element) => element.markerId.toString().contains('point'));
          });
          etaDetails.clear();
          promoKey.clear();
          promoStatus = null;
          _rideLaterSuccess = false;
          addressList.clear();
          myMarker.clear();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Maps()),
              (route) => false);
          return true;
        } else {
          return false;
        }
      },
      child: Material(
        child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: Container(
            height: media.height * 1,
            width: media.width * 1,
            color: page,
            child: ValueListenableBuilder(
                valueListenable: valueNotifierBook.value,
                builder: (context, value, child) {
                  if (requestCancelledByDriver == true ||
                      cancelRequestByUser == true) {
                    myMarker.clear();
                    polyline.clear();
                    addressList.removeWhere((element) => element.id == 'drop');
                    WidgetsBinding.instance?.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Maps()),
                          (route) => false);
                    });
                  }
                  if (userRequestData['is_completed'] == 1) {
                    WidgetsBinding.instance?.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Invoice()),
                          (route) => false);
                    });
                  }
                  if (userRequestData.isNotEmpty &&
                      timers == null &&
                      userRequestData['accepted_at'] == null) {
                    timer();
                  }
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                          height: media.height * 1,
                          width: media.width * 1,
                          //get drivers location updates
                          child: StreamBuilder<DatabaseEvent>(
                              stream:
                                  (userRequestData['driverDetail'] == null &&
                                          pinLocationIcon != null)
                                      ? fdb.onValue
                                      : null,
                              builder: (context,
                                  AsyncSnapshot<DatabaseEvent> event) {
                                if (event.hasData) {
                                  if (event.data!.snapshot.value != null) {
                                    if (userRequestData['accepted_at'] ==
                                        null) {
                                      myMarker.removeWhere((element) => element
                                          .markerId
                                          .toString()
                                          .contains('car'));
                                      DataSnapshot snapshots =
                                          event.data!.snapshot;
                                      // ignore: unnecessary_null_comparison
                                      if (snapshots != null) {
                                        driverData = Map<String, dynamic>.from(
                                            jsonDecode(
                                                jsonEncode(snapshots.value)));
                                        if (driverData != {}) {
                                          driverData.forEach((i, value) {
                                            if (driverData[i]['is_active'] ==
                                                    1 &&
                                                driverData[i]['is_available'] ==
                                                    true) {
                                              DateTime dt = DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      driverData[i]
                                                          ['updated_at']);
                                              if (DateTime.now()
                                                      .difference(dt)
                                                      .inMinutes <=
                                                  2) {
                                                myMarker.add(Marker(
                                                  markerId: MarkerId('car' +
                                                      driverData[i]['id']
                                                          .toString()),
                                                  rotation: double.parse(
                                                      driverData[i]['bearing']
                                                          .toString()),
                                                  position: LatLng(
                                                      driverData[i]['l'][0],
                                                      driverData[i]['l'][1]),
                                                  icon: pinLocationIcon,
                                                ));
                                              }
                                            }
                                          });
                                        }
                                      }
                                    }
                                  }
                                }

                                return StreamBuilder<DatabaseEvent>(
                                    stream: (userRequestData['driverDetail'] !=
                                                null &&
                                            pinLocationIcon != null)
                                        ? FirebaseDatabase.instance
                                            .ref('drivers/' +
                                                userRequestData['driverDetail']
                                                        ['data']['id']
                                                    .toString())
                                            .onValue
                                        : null,
                                    builder: (context,
                                        AsyncSnapshot<DatabaseEvent> events) {
                                      if (events.hasData) {
                                        if (events.data!.snapshot.value !=
                                            null) {
                                          if (userRequestData['accepted_at'] !=
                                              null) {
                                            myMarker.removeWhere((element) =>
                                                element.markerId
                                                    .toString()
                                                    .contains('car'));
                                            DataSnapshot snapshots =
                                                events.data!.snapshot;

                                            // ignore: unnecessary_null_comparison
                                            if (snapshots != null) {
                                              driverData = jsonDecode(
                                                  jsonEncode(snapshots.value));
                                              if (driverData != {}) {
                                                myMarker.add(Marker(
                                                  markerId: MarkerId('car' +
                                                      driverData['id']
                                                          .toString()),

                                                  rotation: double.parse(
                                                      driverData['bearing']
                                                          .toString()),
                                               
                                                  position: LatLng(
                                                      driverData['l'][0],
                                                      driverData['l'][1]),
                                                  icon: pinLocationIcon,
                                                ));
                                              }
                                            }
                                          }
                                        }
                                      }
                                      return GoogleMap(
                                        onMapCreated: _onMapCreated,
                                        compassEnabled: false,
                                        initialCameraPosition: CameraPosition(
                                          target: _center,
                                          zoom: 11.0,
                                        ),
                                        markers: Set<Marker>.from(myMarker),
                                        polylines: polyline,
                                        minMaxZoomPreference:
                                            const MinMaxZoomPreference(
                                                8.0, 20.0),
                                        myLocationButtonEnabled: false,
                                        buildingsEnabled: false,
                                        zoomControlsEnabled: false,
                                        myLocationEnabled: true,
                                      );
                                    });
                              })),
                      (userRequestData['accepted_at'] == null)
                          ? Positioned(
                              top: MediaQuery.of(context).padding.top + 12.5,
                              child: SizedBox(
                                width: media.width * 0.9,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          addressList.removeWhere((element) =>
                                              element.id == 'drop');
                                          etaDetails.clear();
                                          promoKey.clear();
                                          promoStatus = null;
                                        });
                                        _rideLaterSuccess = false;
                                        myMarker.clear();
                                        Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const Maps()),
                                            (route) => false);
                                      },
                                      child: Container(
                                        height: media.width * 0.1,
                                        width: media.width * 0.1,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  spreadRadius: 2,
                                                  blurRadius: 2)
                                            ],
                                            color: page),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.arrow_back),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(),
                      Positioned(
                        
                        bottom: media.width * 1.1,
                        child: SizedBox(
                          width: media.width * 0.9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              (userRequestData.isNotEmpty &&
                                      userRequestData['is_trip_start'] == 1)
                                  ? InkWell(
                                      onTap: () async {
                                        setState(() {
                                          showSos = true;
                                        });
                                      },
                                      child: Container(
                                        height: media.width * 0.1,
                                        width: media.width * 0.1,
                                        decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 2,
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  spreadRadius: 2)
                                            ],
                                            color: buttonColor,
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.02)),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'SOS',
                                          style: GoogleFonts.roboto(
                                              fontSize: media.width * fourteen,
                                              color: page),
                                        ),
                                      ))
                                  : Container(),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              InkWell(
                                onTap: () async {
                                  setState(() {
                                    _controller?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                            currentLocation, 14.0));
                                  });
                                },
                                child: Container(
                                  height: media.width * 0.1,
                                  width: media.width * 0.1,
                                  decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            blurRadius: 2,
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            spreadRadius: 2)
                                      ],
                                      color: page,
                                      borderRadius: BorderRadius.circular(
                                          media.width * 0.02)),
                                  child: const Icon(Icons.my_location_sharp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      //show bottom nav bar for choosing ride type and vehicles
                      (_isLoading == false &&
                              addressList.isNotEmpty &&
                              etaDetails.isNotEmpty &&
                              userRequestData.isEmpty &&
                              noDriverFound == false &&
                              tripReqError == false &&
                              lowWalletBalance == false)
                          ? Positioned(
                              bottom: 0,
                              child: GestureDetector(
                                onPanUpdate: (val) {
                                  if (val.delta.dy > 0) {
                                    setState(() {
                                      _bottomChooseMethod = false;
                                    });
                                  }
                                  if (val.delta.dy < 0) {
                                    setState(() {
                                      _bottomChooseMethod = true;
                                    });
                                  }
                                },
                                child: AnimatedOpacity(
                                  opacity: (_etaDetailsgot == true) ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 1000),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    height: (_bottomChooseMethod == false)
                                        ? media.width * 1
                                        : media.height * 0.9,
                                    width: media.width * 1,
                                    decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(25),
                                            topRight: Radius.circular(25)),
                                        color: page),
                                    child: Column(
                                      children: [
                                        Container(
                                          height: media.width * 0.02,
                                          width: media.width * 0.2,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.01),
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(
                                          height: media.width * 0.05,
                                        ),
                                        SizedBox(
                                          width: media.width * 0.9,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_availablerides'],
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * fourteen,
                                                    color: textColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: SizedBox(
                                           
                                            width: media.width * 0.9,
                                            child: SingleChildScrollView(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                child: (etaDetails.isNotEmpty)
                                                    ? Column(
                                                        children: [
                                                          Column(
                                                            children: etaDetails
                                                                .asMap()
                                                                .map(
                                                                    (i, value) {
                                                                  return MapEntry(
                                                                      i,
                                                                      StreamBuilder<
                                                                              DatabaseEvent>(
                                                                          stream: fdb
                                                                              .onValue,
                                                                          builder:
                                                                              (context, AsyncSnapshot event) {
                                                                            if (event.data !=
                                                                                null) {
                                                                              minutes[etaDetails[i]['type_id']] = '';
                                                                              List vehicleList = [];
                                                                              List vehicles = [];
                                                                              List<double> minsList = [];
                                                                              event.data!.snapshot.children.forEach((e) {
                                                                                vehicleList.add(e.value);
                                                                              });
                                                                              if (vehicleList.isNotEmpty) {
                                                                                // ignore: avoid_function_literals_in_foreach_calls
                                                                                vehicleList.forEach(
                                                                                  (e) async {
                                                                                    if (e['is_active'] == 1 && e['is_available'] == true && e['vehicle_type'] == etaDetails[i]['type_id']) {
                                                                                      DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                      if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                        vehicles.add(e);
                                                                                        if (vehicles.isNotEmpty) {
                                                                                          var dist = calculateDistance(addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);
                                                                                          
                                                                                          minsList.add(double.parse((dist / 1000).toString()));
                                                                                          var minDist = minsList.reduce(min);
                                                                                          if (minDist > 0 && minDist <= 1) {
                                                                                            minutes[etaDetails[i]['type_id']] = '2 mins';
                                                                                          } else if (minDist > 1 && minDist <= 3) {
                                                                                            minutes[etaDetails[i]['type_id']] = '5 mins';
                                                                                          } else if (minDist > 3 && minDist <= 5) {
                                                                                            minutes[etaDetails[i]['type_id']] = '8 mins';
                                                                                          } else if (minDist > 5 && minDist <= 7) {
                                                                                            minutes[etaDetails[i]['type_id']] = '11 mins';
                                                                                          } else if (minDist > 7 && minDist <= 10) {
                                                                                            minutes[etaDetails[i]['type_id']] = '14 mins';
                                                                                          } else if (minDist > 10) {
                                                                                            minutes[etaDetails[i]['type_id']] = '15 mins';
                                                                                          }
                                                                                        } else {
                                                                                          minutes[etaDetails[i]['type_id']] = '';
                                                                                        }
                                                                                      }
                                                                                    }
                                                                                  },
                                                                                );
                                                                              } else {
                                                                                minutes[etaDetails[i]['type_id']] = '';
                                                                              }
                                                                            } else {
                                                                              minutes[etaDetails[i]['type_id']] = '';
                                                                            }

                                                                            return (minutes[etaDetails[i]['type_id']] != '')
                                                                                ? InkWell(
                                                                                    onTap: () {
                                                                                      setState(() {
                                                                                        choosenVehicle = i;
                                                                                      });
                                                                                    },
                                                                                    child: Container(
                                                                                      padding: EdgeInsets.all(media.width * 0.03),
                                                                                      decoration: BoxDecoration(
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                        color: (choosenVehicle != i) ? Colors.transparent : Colors.grey[200],
                                                                                      ),
                                                                                      child: Row(
                                                                                        children: [
                                                                                          Column(
                                                                                            children: [
                                                                                            (etaDetails[i]['icon'] != null) ?  SizedBox(
                                                                                                  width: media.width * 0.1,
                                                                                                  child: Image.network(
                                                                                                    etaDetails[i]['icon'],
                                                                                                    fit: BoxFit.contain,
                                                                                                  )) : Container(),
                                                                                              (minutes[etaDetails[i]['type_id']] != null)
                                                                                                  ? Text(
                                                                                                      minutes[etaDetails[i]['type_id']].toString(),
                                                                                                      style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor.withOpacity(0.3)),
                                                                                                    )
                                                                                                  : Text(
                                                                                                      '- -',
                                                                                                      style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor.withOpacity(0.3)),
                                                                                                    )
                                                                                            ],
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.05,
                                                                                          ),
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Text(etaDetails[i]['name'], style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600)),
                                                                                              Row(
                                                                                                children: [
                                                                                                  SizedBox(
                                                                                                    width: media.width * 0.3,
                                                                                                    child: Text(
                                                                                                      etaDetails[i]['short_description'],
                                                                                                      style: GoogleFonts.roboto(
                                                                                                        fontSize: media.width * twelve,
                                                                                                        color: textColor,
                                                                                                      ),
                                                                                                      maxLines: 1,
                                                                                                    ),
                                                                                                  ),
                                                                                                  SizedBox(width: media.width * 0.01),
                                                                                                  InkWell(
                                                                                                      onTap: () {
                                                                                                        setState(() {
                                                                                                          _showInfoInt = i;
                                                                                                          _showInfo = true;
                                                                                                        });
                                                                                                      },
                                                                                                      child: Icon(Icons.info_outline, size: media.width * twelve)),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          Expanded(
                                                                                              child: (etaDetails[i]['has_discount'] != true)
                                                                                                  ? Row(
                                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          etaDetails[i]['currency'] + ' ' + etaDetails[i]['total'].toStringAsFixed(2),
                                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                        ),
                                                                                                      ],
                                                                                                    )
                                                                                                  : Row(
                                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          etaDetails[i]['currency'] + ' ',
                                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                        ),
                                                                                                        Text(
                                                                                                          etaDetails[i]['total'].toStringAsFixed(2),
                                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                                                                                        ),
                                                                                                        Text(
                                                                                                          ' ' + etaDetails[i]['discounted_totel'].toStringAsFixed(2),
                                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                        )
                                                                                                      ],
                                                                                                    ))
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  )
                                                                                : Container();
                                                                          }));
                                                                })
                                                                .values
                                                                .toList(),
                                                          ),
                                                          Column(
                                                            children: etaDetails
                                                                .asMap()
                                                                .map(
                                                                    (i, value) {
                                                                  return MapEntry(
                                                                      i,
                                                                      StreamBuilder<
                                                                              DatabaseEvent>(
                                                                          stream: fdb
                                                                              .onValue,
                                                                          builder:
                                                                              (context, AsyncSnapshot event) {
                                                                            return (minutes[etaDetails[i]['type_id']] == '')
                                                                                ? InkWell(
                                                                                    onTap: () {
                                                                                      setState(() {
                                                                                        choosenVehicle = i;
                                                                                      });
                                                                                    },
                                                                                    child: Container(
                                                                                      padding: EdgeInsets.all(media.width * 0.03),
                                                                                      decoration: BoxDecoration(
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                        color: (choosenVehicle != i) ? Colors.transparent : Colors.grey[200],
                                                                                      ),
                                                                                      child: Row(
                                                                                        children: [
                                                                                          Column(
                                                                                            children: [
                                                                                             (etaDetails[i]['icon'] != null) ? SizedBox(
                                                                                                  width: media.width * 0.1,
                                                                                                  child: Image.network(
                                                                                                    etaDetails[i]['icon'],
                                                                                                    fit: BoxFit.contain,
                                                                                                  )) : Container(),
                                                                                              (minutes[etaDetails[i]['type_id']] != "")
                                                                                                  ? Text(
                                                                                                      minutes[etaDetails[i]['type_id']].toString(),
                                                                                                      style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor.withOpacity(0.3)),
                                                                                                    )
                                                                                                  : Text(
                                                                                                      '- -',
                                                                                                      style: GoogleFonts.roboto(fontSize: media.width * twelve, color: textColor.withOpacity(0.3)),
                                                                                                    )
                                                                                            ],
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.05,
                                                                                          ),
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Text(etaDetails[i]['name'], style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600)),
                                                                                              Row(
                                                                                                children: [
                                                                                                  SizedBox(
                                                                                                    width: media.width * 0.3,
                                                                                                    child: Text(
                                                                                                      etaDetails[i]['short_description'],
                                                                                                      style: GoogleFonts.roboto(
                                                                                                        fontSize: media.width * twelve,
                                                                                                        color: textColor,
                                                                                                      ),
                                                                                                      maxLines: 1,
                                                                                                    ),
                                                                                                  ),
                                                                                                  SizedBox(width: media.width * 0.01),
                                                                                                  InkWell(
                                                                                                      onTap: () {
                                                                                                        setState(() {
                                                                                                          _showInfoInt = i;
                                                                                                          _showInfo = true;
                                                                                                        });
                                                                                                      },
                                                                                                      child: Icon(Icons.info_outline, size: media.width * twelve)),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          Expanded(
                                                                                              child: (etaDetails[i]['has_discount'] != true)
                                                                                                  ? Row(
                                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          etaDetails[i]['currency'] + ' ' + etaDetails[i]['total'].toStringAsFixed(2),
                                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                        ),
                                                                                                      ],
                                                                                                    )
                                                                                                  : Row(
                                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          etaDetails[i]['currency'] + ' ',
                                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                        ),
                                                                                                        Text(
                                                                                                          etaDetails[i]['total'].toStringAsFixed(2),
                                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                                                                                        ),
                                                                                                        Text(
                                                                                                          ' ' + etaDetails[i]['discounted_totel'].toStringAsFixed(2),
                                                                                                          style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                        )
                                                                                                      ],
                                                                                                    ))
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  )
                                                                                : Container();
                                                                          }));
                                                                })
                                                                .values
                                                                .toList(),
                                                          )
                                                        ],
                                                      )
                                                    : Container()),
                                          ),
                                        ),
                                        SizedBox(
                                          height: media.width * 0.05,
                                        ),
                                        (_bottomChooseMethod == true)
                                            ? Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.034),
                                                margin: EdgeInsets.only(
                                                  bottom: media.height * 0.03,
                                                ),
                                                height: media.width * 0.21,
                                                width: media.width * 0.9,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: borderLines,
                                                    width: 1.2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Container(
                                                          height: media.width *
                                                              0.025,
                                                          width: media.width *
                                                              0.025,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: const Color(
                                                                      0xff319900)
                                                                  .withOpacity(
                                                                      0.3)),
                                                          child: Container(
                                                            height:
                                                                media.width *
                                                                    0.01,
                                                            width: media.width *
                                                                0.01,
                                                            decoration: const BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Color(
                                                                    0xff319900)),
                                                          ),
                                                        ),
                                                        Column(
                                                          children: [
                                                            Container(
                                                              height:
                                                                  media.width *
                                                                      0.01,
                                                              width:
                                                                  media.width *
                                                                      0.001,
                                                              color: const Color(
                                                                  0xff319900),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.002,
                                                            ),
                                                            Container(
                                                              height:
                                                                  media.width *
                                                                      0.01,
                                                              width:
                                                                  media.width *
                                                                      0.001,
                                                              color: const Color(
                                                                  0xff319900),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.002,
                                                            ),
                                                            Container(
                                                              height:
                                                                  media.width *
                                                                      0.01,
                                                              width:
                                                                  media.width *
                                                                      0.001,
                                                              color: const Color(
                                                                  0xff319900),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.002,
                                                            ),
                                                            Container(
                                                              height:
                                                                  media.width *
                                                                      0.01,
                                                              width:
                                                                  media.width *
                                                                      0.001,
                                                              color: const Color(
                                                                  0xff319900),
                                                            ),
                                                          ],
                                                        ),
                                                        Container(
                                                          height: media.width *
                                                              0.025,
                                                          width: media.width *
                                                              0.025,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: const Color(
                                                                      0xffFF0000)
                                                                  .withOpacity(
                                                                      0.3)),
                                                          child: Container(
                                                            height:
                                                                media.width *
                                                                    0.01,
                                                            width: media.width *
                                                                0.01,
                                                            decoration: const BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Color(
                                                                    0xffFF0000)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      width: media.width * 0.03,
                                                    ),
                                                    Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        (userRequestData
                                                                .isNotEmpty)
                                                            ? SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.75,
                                                                child: Text(
                                                                  userRequestData[
                                                                      'pick_address'],
                                                                  style: GoogleFonts.roboto(
                                                                      fontSize:
                                                                          media.width *
                                                                              twelve,
                                                                      color:
                                                                          textColor),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              )
                                                            : (addressList
                                                                    .where((e) =>
                                                                        e.id ==
                                                                        'drop')
                                                                    .isNotEmpty)
                                                                ? SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.75,
                                                                    child: Text(
                                                                      addressList
                                                                          .firstWhere((element) =>
                                                                              element.id ==
                                                                              'pickup')
                                                                          .address,
                                                                      style: GoogleFonts.roboto(
                                                                          fontSize: media.width *
                                                                              twelve,
                                                                          color:
                                                                              textColor),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                        Container(
                                                          height: 1,
                                                          width: media.width *
                                                              0.75,
                                                          color: borderLines,
                                                        ),
                                                        (userRequestData
                                                                .isNotEmpty)
                                                            ? SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.75,
                                                                child: Text(
                                                                  userRequestData[
                                                                      'drop_address'],
                                                                  style: GoogleFonts.roboto(
                                                                      fontSize:
                                                                          media.width *
                                                                              twelve,
                                                                      color:
                                                                          textColor),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              )
                                                            : (addressList
                                                                    .where((e) =>
                                                                        e.id ==
                                                                        'drop')
                                                                    .isNotEmpty)
                                                                ? SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.75,
                                                                    child: Text(
                                                                      addressList
                                                                          .firstWhere((element) =>
                                                                              element.id ==
                                                                              'drop')
                                                                          .address,
                                                                      style: GoogleFonts.roboto(
                                                                          fontSize: media.width *
                                                                              twelve,
                                                                          color:
                                                                              textColor),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              )
                                            : Container(),
                                        (choosenVehicle != null)
                                            ? InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _choosePayment = true;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.02),
                                                  height: media.width * 0.2,
                                                  width: media.width * 0.9,
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: borderLines,
                                                          width: 1.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            ['text_payingvia'],
                                                        style:
                                                            GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  twelve,
                                                          color: const Color(
                                                              0xff666666),
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          SizedBox(
                                                            width: media.width *
                                                                0.06,
                                                            child: (etaDetails[choosenVehicle]['payment_type']
                                                                            .toString()
                                                                            .split(
                                                                                ',')
                                                                            .toList()[
                                                                        payingVia] ==
                                                                    'cash')
                                                                ? Image.asset(
                                                                    'assets/images/cash.png',
                                                                    fit: BoxFit
                                                                        .contain,
                                                                  )
                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[
                                                                            payingVia] ==
                                                                        'wallet')
                                                                    ? Image
                                                                        .asset(
                                                                        'assets/images/wallet.png',
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      )
                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                            'card')
                                                                        ? Image
                                                                            .asset(
                                                                            'assets/images/card.png',
                                                                            fit:
                                                                                BoxFit.contain,
                                                                          )
                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                                'upi')
                                                                            ? Image.asset(
                                                                                'assets/images/upi.png',
                                                                                fit: BoxFit.contain,
                                                                              )
                                                                            : Container(),
                                                          ),
                                                          SizedBox(
                                                            width: media.width *
                                                                0.05,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                etaDetails[choosenVehicle]
                                                                        [
                                                                        'payment_type']
                                                                    .toString()
                                                                    .split(',')
                                                                    .toList()[
                                                                        payingVia]
                                                                    .toString(),
                                                                style: GoogleFonts.roboto(
                                                                    fontSize: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                              (etaDetails[choosenVehicle]
                                                                          [
                                                                          'has_discount'] ==
                                                                      false)
                                                                  ? Text(
                                                                      (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] ==
                                                                              'cash')
                                                                          ? languages[choosenLanguage]
                                                                              [
                                                                              'text_paycash']
                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                              ? languages[choosenLanguage]['text_paywallet']
                                                                              : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                  ? languages[choosenLanguage]['text_paycard']
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'upi')
                                                                                      ? languages[choosenLanguage]['text_payupi']
                                                                                      : '',
                                                                      style: GoogleFonts
                                                                          .roboto(
                                                                        fontSize:
                                                                            media.width *
                                                                                ten,
                                                                      ),
                                                                    )
                                                                  : Text(
                                                                      languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_promoaccepted'],
                                                                      style: GoogleFonts
                                                                          .roboto(
                                                                        color: const Color(
                                                                            0xff319900),
                                                                        fontSize:
                                                                            media.width *
                                                                                ten,
                                                                      ),
                                                                    )
                                                            ],
                                                          ),
                                                          Expanded(
                                                              child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: const [
                                                              Icon(
                                                                Icons
                                                                    .arrow_forward_ios,
                                                              ),
                                                            ],
                                                          ))
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : Container(),
                                        (choosenVehicle != null)
                                            ? SizedBox(
                                                height: media.width * 0.05,
                                              )
                                            : Container(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Button(
                                                color: page,
                                                textcolor: buttonColor,
                                                width: media.width * 0.42,
                                                onTap: () async {
                                                  if (choosenVehicle != null) {
                                                    setState(() {
                                                      choosenDateTime =
                                                          DateTime.now().add(
                                                              const Duration(
                                                                  minutes: 30));
                                                      _dateTimePicker = true;
                                                    });
                                                  }
                                                },
                                                text: languages[choosenLanguage]
                                                    ['text_ridelater']),
                                            Button(
                                                width: media.width * 0.42,
                                                color: buttonColor,
                                                onTap: () async {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  dynamic _result;
                                                  if (choosenVehicle != null) {
                                                    if (etaDetails[
                                                                choosenVehicle]
                                                            ['has_discount'] ==
                                                        false) {
                                                      _result =
                                                          await createRequest();
                                                    } else {
                                                      _result =
                                                          await createRequestWithPromo();
                                                    }
                                                  }
                                                  if (_result == 'success') {
                                                    timer();
                                                  }
                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                  
                                                },
                                                text: languages[choosenLanguage]
                                                    ['text_ridenow']),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ))
                          : Container(),

                      //show vehicle info
                      (_showInfo == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                padding:
                                    EdgeInsets.only(bottom: media.width * 0.05),
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _showInfo = false;
                                                _showInfoInt = null;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.1,
                                              width: media.width * 0.1,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: page),
                                              child: const Icon(
                                                  Icons.cancel_outlined),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: media.width * 0.05),
                                    Container(
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            etaDetails[_showInfoInt]['name'],
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.025,
                                          ),
                                          Text(
                                            etaDetails[_showInfoInt]
                                                ['description'],
                                            style: GoogleFonts.roboto(
                                              fontSize: media.width * fourteen,
                                              color: textColor,
                                            ),
                                          ),
                                          SizedBox(height: media.width * 0.05),
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_supported_vehicles'],
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.025,
                                          ),
                                          Text(
                                            etaDetails[_showInfoInt]
                                                ['supported_vehicles'],
                                            style: GoogleFonts.roboto(
                                              fontSize: media.width * fourteen,
                                              color: textColor,
                                            ),
                                          ),
                                          SizedBox(height: media.width * 0.05),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: media.width * 0.4,
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_estimated_amount'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                              (etaDetails[_showInfoInt]
                                                          ['has_discount'] !=
                                                      true)
                                                  ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          etaDetails[_showInfoInt]
                                                                  ['currency'] +
                                                              ' ' +
                                                              etaDetails[_showInfoInt]
                                                                      ['total']
                                                                  .toStringAsFixed(
                                                                      2),
                                                          style: GoogleFonts.roboto(
                                                              fontSize:
                                                                  media.width *
                                                                      fourteen,
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ],
                                                    )
                                                  : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          etaDetails[_showInfoInt]
                                                                  ['currency'] +
                                                              ' ',
                                                          style: GoogleFonts.roboto(
                                                              fontSize:
                                                                  media.width *
                                                                      fourteen,
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        Text(
                                                          etaDetails[_showInfoInt]
                                                                  ['total']
                                                              .toStringAsFixed(
                                                                  2),
                                                          style: GoogleFonts.roboto(
                                                              fontSize:
                                                                  media.width *
                                                                      fourteen,
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough),
                                                        ),
                                                        Text(
                                                          ' ' +
                                                              etaDetails[_showInfoInt]
                                                                      [
                                                                      'discounted_totel']
                                                                  .toStringAsFixed(
                                                                      2),
                                                          style: GoogleFonts.roboto(
                                                              fontSize:
                                                                  media.width *
                                                                      fourteen,
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        )
                                                      ],
                                                    )
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          : Container(),

                      //no driver found
                      (noDriverFound == true)
                          ? Positioned(
                              bottom: 0,
                              child: Container(
                                width: media.width * 1,
                                padding: EdgeInsets.all(media.width * 0.05),
                                decoration: BoxDecoration(
                                    color: page,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12))),
                                child: Column(
                                  children: [
                                    Container(
                                      height: media.width * 0.18,
                                      width: media.width * 0.18,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xffFEF2F2)),
                                      alignment: Alignment.center,
                                      child: Container(
                                        height: media.width * 0.14,
                                        width: media.width * 0.14,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xffFF0000)),
                                        child: const Center(
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_nodriver'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * eighteen,
                                          fontWeight: FontWeight.w600,
                                          color: textColor),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Button(
                                        onTap: () {
                                          setState(() {
                                            noDriverFound = false;
                                          });
                                        },
                                        text: languages[choosenLanguage]
                                            ['text_tryagain'])
                                  ],
                                ),
                              ))
                          : Container(),

                      //internal server error
                      (tripReqError == true)
                          ? Positioned(
                              bottom: 0,
                              child: Container(
                                width: media.width * 1,
                                padding: EdgeInsets.all(media.width * 0.05),
                                decoration: BoxDecoration(
                                    color: page,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12))),
                                child: Column(
                                  children: [
                                    Container(
                                      height: media.width * 0.18,
                                      width: media.width * 0.18,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xffFEF2F2)),
                                      alignment: Alignment.center,
                                      child: Container(
                                        height: media.width * 0.14,
                                        width: media.width * 0.14,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xffFF0000)),
                                        child: const Center(
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.8,
                                      child: Text(
                                          languages[choosenLanguage]
                                              ['text_internal_server_error'],
                                          style: GoogleFonts.roboto(
                                              fontSize: media.width * eighteen,
                                              fontWeight: FontWeight.w600,
                                              color: textColor),
                                          textAlign: TextAlign.center),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Button(
                                        onTap: () {
                                          setState(() {
                                            tripReqError = false;
                                          });
                                        },
                                        text: languages[choosenLanguage]
                                            ['text_tryagain'])
                                  ],
                                ),
                              ))
                          : Container(),

                      //service not available
                      (serviceNotAvailable == true)
                          ? Positioned(
                              bottom: 0,
                              child: Container(
                                width: media.width * 1,
                                padding: EdgeInsets.all(media.width * 0.05),
                                decoration: BoxDecoration(
                                    color: page,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12))),
                                child: Column(
                                  children: [
                                    Container(
                                      height: media.width * 0.18,
                                      width: media.width * 0.18,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xffFEF2F2)),
                                      alignment: Alignment.center,
                                      child: Container(
                                        height: media.width * 0.14,
                                        width: media.width * 0.14,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xffFF0000)),
                                        child: const Center(
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.8,
                                      child: Text(
                                          languages[choosenLanguage]
                                              ['text_no_service'],
                                          style: GoogleFonts.roboto(
                                              fontSize: media.width * eighteen,
                                              fontWeight: FontWeight.w600,
                                              color: textColor),
                                          textAlign: TextAlign.center),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Button(
                                        onTap: () async {
                                          setState(() {
                                            serviceNotAvailable = false;
                                          });
                                          await etaRequest();
                                          setState(() {});
                                        },
                                        text: languages[choosenLanguage]
                                            ['text_tryagain'])
                                  ],
                                ),
                              ))
                          : Container(),
                      //choose payment method
                      (_choosePayment == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Scaffold(
                                  backgroundColor: Colors.transparent,
                                  body: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: SizedBox(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _choosePayment = false;
                                                      promoKey.clear();
                                                    });
                                                  },
                                                  child: Container(
                                                    height: media.width * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: page),
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
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                              color: page,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_paymentmethod'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * twenty,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textColor),
                                                ),
                                                SizedBox(
                                                  height: media.height * 0.015,
                                                ),
                                                Text(
                                                  languages[choosenLanguage][
                                                      'text_choose_paynoworlater'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * twelve,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textColor),
                                                ),
                                                SizedBox(
                                                  height: media.height * 0.015,
                                                ),
                                                Column(
                                                  children:
                                                      etaDetails[choosenVehicle]
                                                              ['payment_type']
                                                          .toString()
                                                          .split(',')
                                                          .toList()
                                                          .asMap()
                                                          .map((i, value) {
                                                            return MapEntry(
                                                                i,
                                                                InkWell(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      payingVia =
                                                                          i;
                                                                    });
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    padding: EdgeInsets.all(
                                                                        media.width *
                                                                            0.02),
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            SizedBox(
                                                                              width: media.width * 0.06,
                                                                              child: (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                  ? Image.asset(
                                                                                      'assets/images/cash.png',
                                                                                      fit: BoxFit.contain,
                                                                                    )
                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                      ? Image.asset(
                                                                                          'assets/images/wallet.png',
                                                                                          fit: BoxFit.contain,
                                                                                        )
                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                          ? Image.asset(
                                                                                              'assets/images/card.png',
                                                                                              fit: BoxFit.contain,
                                                                                            )
                                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                              ? Image.asset(
                                                                                                  'assets/images/upi.png',
                                                                                                  fit: BoxFit.contain,
                                                                                                )
                                                                                              : Container(),
                                                                            ),
                                                                            SizedBox(
                                                                              width: media.width * 0.05,
                                                                            ),
                                                                            Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i].toString(),
                                                                                  style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                ),
                                                                                Text(
                                                                                  (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                      ? languages[choosenLanguage]['text_paycash']
                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                          ? languages[choosenLanguage]['text_paywallet']
                                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                              ? languages[choosenLanguage]['text_paycard']
                                                                                              : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                  ? languages[choosenLanguage]['text_payupi']
                                                                                                  : '',
                                                                                  style: GoogleFonts.roboto(
                                                                                    fontSize: media.width * ten,
                                                                                  ),
                                                                                )
                                                                              ],
                                                                            ),
                                                                            Expanded(
                                                                                child: Row(
                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                              children: [
                                                                                Container(
                                                                                  height: media.width * 0.05,
                                                                                  width: media.width * 0.05,
                                                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: page, border: Border.all(color: Colors.black, width: 1.2)),
                                                                                  alignment: Alignment.center,
                                                                                  child: (payingVia == i) ? Container(height: media.width * 0.03, width: media.width * 0.03, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)) : Container(),
                                                                                )
                                                                              ],
                                                                            ))
                                                                          ],
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ));
                                                          })
                                                          .values
                                                          .toList(),
                                                ),
                                                SizedBox(
                                                  height: media.height * 0.02,
                                                ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                        color: borderLines,
                                                        width: 1.2),
                                                  ),
                                                  padding: EdgeInsets.fromLTRB(
                                                      media.width * 0.025,
                                                      0,
                                                      media.width * 0.025,
                                                      0),
                                                  width: media.width * 0.9,
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.06,
                                                        child: Image.asset(
                                                            'assets/images/promocode.png',
                                                            fit:
                                                                BoxFit.contain),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.05,
                                                      ),
                                                      Expanded(
                                                        child: (promoStatus ==
                                                                null)
                                                            ? TextField(
                                                                controller:
                                                                    promoKey,
                                                                onChanged:
                                                                    (val) {
                                                                  setState(() {
                                                                    promoCode =
                                                                        val;
                                                                  });
                                                                },
                                                                decoration: InputDecoration(
                                                                    border: InputBorder
                                                                        .none,
                                                                    hintText: languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_enterpromo'],
                                                                    hintStyle: GoogleFonts.roboto(
                                                                        fontSize:
                                                                            media.width *
                                                                                twelve,
                                                                        color:
                                                                            hintColor)),
                                                              )
                                                            : (promoStatus == 1)
                                                                ? Container(
                                                                    padding: EdgeInsets.fromLTRB(
                                                                        0,
                                                                        media.width *
                                                                            0.045,
                                                                        0,
                                                                        media.width *
                                                                            0.045),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Column(
                                                                          children: [
                                                                            Text(promoKey.text,
                                                                                style: GoogleFonts.roboto(fontSize: media.width * ten, color: const Color(0xff319900))),
                                                                            Text(languages[choosenLanguage]['text_promoaccepted'],
                                                                                style: GoogleFonts.roboto(fontSize: media.width * ten, color: const Color(0xff319900))),
                                                                          ],
                                                                        ),
                                                                        InkWell(
                                                                          onTap:
                                                                              () async {
                                                                            setState(() {
                                                                              _isLoading = true;
                                                                            });
                                                                            var result =
                                                                                await etaRequest();
                                                                            setState(() {
                                                                              _isLoading = false;
                                                                              if (result == true) {
                                                                                promoStatus = null;
                                                                                promoCode = '';
                                                                              }
                                                                            });
                                                                          },
                                                                          child: Text(
                                                                              languages[choosenLanguage]['text_remove'],
                                                                              style: GoogleFonts.roboto(fontSize: media.width * twelve, color: const Color(0xff319900))),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  )
                                                                : (promoStatus ==
                                                                        2)
                                                                    ? Container(
                                                                        padding: EdgeInsets.fromLTRB(
                                                                            0,
                                                                            media.width *
                                                                                0.045,
                                                                            0,
                                                                            media.width *
                                                                                0.045),
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Text(promoKey.text,
                                                                                style: GoogleFonts.roboto(fontSize: media.width * twelve, color: const Color(0xffFF0000))),
                                                                            InkWell(
                                                                              onTap: () {
                                                                                setState(() {
                                                                                  promoStatus = null;
                                                                                  promoCode = '';
                                                                                  // promoKey.text = promoCode;
                                                                                  etaRequest();
                                                                                });
                                                                              },
                                                                              child: Text(languages[choosenLanguage]['text_remove'], style: GoogleFonts.roboto(fontSize: media.width * twelve, color: const Color(0xffFF0000))),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      )
                                                                    : Container(),
                                                      )
                                                    ],
                                                  ),
                                                ),

                                                //promo code status
                                                (promoStatus == 2)
                                                    ? Container(
                                                        width:
                                                            media.width * 0.9,
                                                        alignment:
                                                            Alignment.center,
                                                        padding: EdgeInsets.only(
                                                            top: media.height *
                                                                0.02),
                                                        child: Text(
                                                            languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_promorejected'],
                                                            style: GoogleFonts.roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    ten,
                                                                color: const Color(
                                                                    0xffFF0000))),
                                                      )
                                                    : Container(),
                                                SizedBox(
                                                  height: media.height * 0.02,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      if (promoCode == '') {
                                                        setState(() {
                                                          _choosePayment =
                                                              false;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          _isLoading = true;
                                                        });
                                                        await etaRequestWithPromo();
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      }
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'])
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          : Container(),

                      //bottom nav bar after request accepted
                      (userRequestData['accepted_at'] != null)
                          ? Positioned(
                              top: MediaQuery.of(context).padding.top + 25,
                              child: Container(
                                padding: EdgeInsets.fromLTRB(
                                    media.width * 0.05,
                                    media.width * 0.025,
                                    media.width * 0.05,
                                    media.width * 0.025),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                          blurRadius: 2,
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2)
                                    ],
                                    color: page),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 10,
                                      width: 10,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                blurRadius: 2,
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                spreadRadius: 2)
                                          ],
                                          color: (userRequestData[
                                                          'accepted_at'] !=
                                                      null &&
                                                  userRequestData[
                                                          'arrived_at'] ==
                                                      null)
                                              ? const Color(0xff2E67D5)
                                              : (userRequestData[
                                                              'accepted_at'] !=
                                                          null &&
                                                      userRequestData[
                                                              'arrived_at'] !=
                                                          null &&
                                                      userRequestData[
                                                              'is_trip_start'] ==
                                                          0)
                                                  ? const Color(0xff319900)
                                                  : (userRequestData[
                                                                  'accepted_at'] !=
                                                              null &&
                                                          userRequestData[
                                                                  'arrived_at'] !=
                                                              null &&
                                                          userRequestData[
                                                                  'is_trip_start'] !=
                                                              0)
                                                      ? const Color(0xffFF0000)
                                                      : Colors.transparent),
                                    ),
                                    SizedBox(
                                      width: media.width * 0.02,
                                    ),
                                    Text(
                                        (userRequestData['accepted_at'] !=
                                                    null &&
                                                userRequestData['arrived_at'] ==
                                                    null)
                                            ? languages[choosenLanguage]
                                                ['text_arriving']
                                            : (userRequestData[
                                                            'accepted_at'] !=
                                                        null &&
                                                    userRequestData[
                                                            'arrived_at'] !=
                                                        null &&
                                                    userRequestData[
                                                            'is_trip_start'] ==
                                                        0)
                                                ? languages[choosenLanguage]
                                                    ['text_arrived']
                                                : (userRequestData[
                                                                'accepted_at'] !=
                                                            null &&
                                                        userRequestData[
                                                                'arrived_at'] !=
                                                            null &&
                                                        userRequestData[
                                                                'is_trip_start'] !=
                                                            null)
                                                    ? languages[choosenLanguage]
                                                        ['text_onride']
                                                    : '',
                                        style: GoogleFonts.roboto(
                                          fontSize: media.width * twelve,
                                          color: (userRequestData[
                                                          'accepted_at'] !=
                                                      null &&
                                                  userRequestData[
                                                          'arrived_at'] ==
                                                      null)
                                              ? const Color(0xff2E67D5)
                                              : (userRequestData[
                                                              'accepted_at'] !=
                                                          null &&
                                                      userRequestData[
                                                              'arrived_at'] !=
                                                          null &&
                                                      userRequestData[
                                                              'is_trip_start'] ==
                                                          0)
                                                  ? const Color(0xff319900)
                                                  : (userRequestData[
                                                                  'accepted_at'] !=
                                                              null &&
                                                          userRequestData[
                                                                  'arrived_at'] !=
                                                              null &&
                                                          userRequestData[
                                                                  'is_trip_start'] ==
                                                              1)
                                                      ? const Color(0xffFF0000)
                                                      : Colors.transparent,
                                        ))
                                  ],
                                ),
                              ))
                          : Container(),
                      (userRequestData.isNotEmpty &&
                                  userRequestData['is_later'] == null &&
                                  userRequestData['accepted_at'] == null ||
                              userRequestData.isNotEmpty &&
                                  userRequestData['is_later'] == 0 &&
                                  userRequestData['accepted_at'] == null)
                          ? Positioned(
                              bottom: 0,
                              child: Container(
                                width: media.width * 1,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12)),
                                  color: page,
                                ),
                                padding: EdgeInsets.all(media.width * 0.05),
                                child: Column(
                                  children: [
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_findingdriver'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * fourteen,
                                          color: textColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: media.height * 0.02,
                                    ),
                                    SizedBox(
                                      height: media.width * 0.4,
                                      child: Image.asset(
                                        'assets/images/waiting_time.gif',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.height * 0.02,
                                    ),
                                    Container(
                                      height: media.width * 0.02,
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              media.width * 0.01),
                                          color: Colors.grey),
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        height: media.width * 0.02,
                                        width: (media.width *
                                            0.9 *
                                            (timing / 300)),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.01),
                                            color: buttonColor),
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.height * 0.02,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        (timing != null)
                                            ? Text(
                                                Duration(seconds: timing)
                                                        .toString()
                                                        .substring(3, 7) +
                                                    ' mins',
                                                style: GoogleFonts.roboto(
                                                    fontSize: media.width * ten,
                                                    color: textColor
                                                        .withOpacity(0.4)),
                                              )
                                            : Container()
                                      ],
                                    ),
                                    SizedBox(
                                      height: media.height * 0.02,
                                    ),
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_finddriverdesc'],
                                      style: GoogleFonts.roboto(
                                        fontSize: media.width * twelve,
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(
                                      height: media.height * 0.02,
                                    ),
                                    Button(
                                        width: media.width * 0.5,
                                        onTap: () {
                                          cancelRequest();
                                        },
                                        text: languages[choosenLanguage]
                                            ['text_cancel'])
                                  ],
                                ),
                              ),
                            )
                          : Container(),
                      (userRequestData.isNotEmpty &&
                              userRequestData['accepted_at'] != null)
                          ? Positioned(
                              bottom: 0,
                              child: GestureDetector(
                                onPanUpdate: (val) {
                                  // print(val.delta.dy);
                                  if (val.delta.dy > 0) {
                                    setState(() {
                                      _ontripBottom = false;
                                    });
                                  }
                                  if (val.delta.dy < 0) {
                                    setState(() {
                                      _ontripBottom = true;
                                    });
                                  }
                                },
                                child: Container(
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    width: media.width * 1,
                                    decoration: BoxDecoration(
                                        color: page,
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12))),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        children: [
                                          // SizedBox(height: media.width*0.02,),
                                          Container(
                                            height: media.width * 0.02,
                                            width: media.width * 0.2,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      media.width * 0.01),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          (userRequestData['is_trip_start'] !=
                                                  1)
                                              ? Container(
                                                  padding: EdgeInsets.fromLTRB(
                                                      0,
                                                      media.width * 0.02,
                                                      0,
                                                      0),
                                                  child: Text(
                                                    languages[choosenLanguage][
                                                            'text_startridewithotp'] +
                                                        ':' +
                                                        userRequestData[
                                                                'ride_otp']
                                                            .toString(),
                                                    style: GoogleFonts.roboto(
                                                        fontSize: media.width *
                                                            fourteen,
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                )
                                              : Container(),
                                          SizedBox(
                                            height: media.height * 0.02,
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                height: media.width * 0.16,
                                                width: media.width * 0.16,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    image: DecorationImage(
                                                        image: NetworkImage(
                                                            userRequestData[
                                                                        'driverDetail']
                                                                    ['data'][
                                                                'profile_picture']),
                                                        fit: BoxFit.cover)),
                                              ),
                                              SizedBox(
                                                  width: media.width * 0.05),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    userRequestData[
                                                            'driverDetail']
                                                        ['data']['name'],
                                                    style: GoogleFonts.roboto(
                                                        fontSize: media.width *
                                                            eighteen,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: textColor),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          media.width * 0.03),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        userRequestData[
                                                                    'driverDetail']
                                                                [
                                                                'data']['rating']
                                                            .toString(),
                                                        style: GoogleFonts
                                                            .roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    twelve,
                                                                color:
                                                                    textColor),
                                                      ),
                                                      Icon(
                                                        Icons.star,
                                                        color: buttonColor,
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Container(
                                                          height: media.width *
                                                              0.069,
                                                          decoration: BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .black,
                                                                  width: 1.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                          padding: EdgeInsets
                                                              .fromLTRB(
                                                                  media.width *
                                                                      0.02,
                                                                  media.width *
                                                                      0.01,
                                                                  media.width *
                                                                      0.02,
                                                                  media.width *
                                                                      0.01),
                                                          child: Text(
                                                            userRequestData[
                                                                        'driverDetail']
                                                                    ['data']
                                                                ['car_number'],
                                                            style: GoogleFonts.roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    textColor),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                            height:
                                                                media.width *
                                                                    0.03),
                                                        Text(
                                                          userRequestData[
                                                                          'driverDetail']
                                                                      [
                                                                      'data'][
                                                                  'car_color'] +
                                                              ' ' +
                                                              userRequestData[
                                                                          'driverDetail']
                                                                      ['data'][
                                                                  'car_make_name'] +
                                                              ' ' +
                                                              userRequestData[
                                                                          'driverDetail']
                                                                      ['data'][
                                                                  'car_model_name'],
                                                          style: GoogleFonts.roboto(
                                                              fontSize:
                                                                  media.width *
                                                                      twelve,
                                                              color: textColor),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          (userRequestData['is_trip_start'] !=
                                                  1)
                                              ? Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        makingPhoneCall(
                                                            userRequestData[
                                                                    'driverDetail']
                                                                [
                                                                'data']['mobile']);
                                                      },
                                                      child: Container(
                                                        height:
                                                            media.width * 0.117,
                                                        width:
                                                            media.width * 0.128,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  borderLines,
                                                              width: 1.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: SizedBox(
                                                          height: media.width *
                                                              0.064,
                                                          width: media.width *
                                                              0.064,
                                                          child: RotatedBox(
                                                            quarterTurns:
                                                                (languageDirection ==
                                                                        'rtl')
                                                                    ? 3
                                                                    : 0,
                                                            child: Image.asset(
                                                              'assets/images/call.png',
                                                              fit: BoxFit
                                                                  .contain,
                                                              // height: media.width*0.064,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: media.width * 0.05,
                                                    ),
                                                    Expanded(
                                                        child: InkWell(
                                                      onTap: () async {
                                                        var result = await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const ChatPage()));
                                                        if (result) {
                                                          setState(() {});
                                                        }
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                            media.width * 0.03),
                                                        height:
                                                            media.width * 0.117,
                                                        decoration: BoxDecoration(
                                                            border: Border.all(
                                                                color: (chatList
                                                                        .where((element) =>
                                                                            element['from_type'] ==
                                                                                2 &&
                                                                            element['seen'] ==
                                                                                0)
                                                                        .isEmpty)
                                                                    ? borderLines
                                                                    : const Color(
                                                                        0xffFF0000),
                                                                width: 1.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12)),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                (chatList
                                                                        .where((element) =>
                                                                            element['from_type'] ==
                                                                                2 &&
                                                                            element['seen'] ==
                                                                                0)
                                                                        .isEmpty)
                                                                    ? languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_pickup_instruction']
                                                                    : languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_newmessagereceived'],
                                                                style: GoogleFonts.roboto(
                                                                    fontSize: media
                                                                            .width *
                                                                        twelve,
                                                                    color: (chatList
                                                                            .where((element) =>
                                                                                element['from_type'] == 2 &&
                                                                                element['seen'] ==
                                                                                    0)
                                                                            .isEmpty)
                                                                        ? hintColor
                                                                        : const Color(
                                                                            0xffFF0000)),
                                                              ),
                                                            ),
                                                            (chatList
                                                                    .where((element) =>
                                                                        element['from_type'] ==
                                                                            2 &&
                                                                        element['seen'] ==
                                                                            0)
                                                                    .isEmpty)
                                                                ? RotatedBox(
                                                                    quarterTurns:
                                                                        (languageDirection ==
                                                                                'rtl')
                                                                            ? 2
                                                                            : 0,
                                                                    child: Image
                                                                        .asset(
                                                                            'assets/images/send.png'),
                                                                  )
                                                                : Text(
                                                                    chatList
                                                                        .where((element) =>
                                                                            element['from_type'] ==
                                                                                2 &&
                                                                            element['seen'] ==
                                                                                0)
                                                                        .length
                                                                        .toString(),
                                                                    style: GoogleFonts.roboto(
                                                                        fontSize:
                                                                            media.width *
                                                                                twelve,
                                                                        color: const Color(
                                                                            0xffFF0000)),
                                                                  )
                                                          ],
                                                        ),
                                                      ),
                                                    ))
                                                  ],
                                                )
                                              : Container(),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: borderLines,
                                                    width: 1.2),
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            width: media.width * 0.9,
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.034),
                                                  height: media.width * 0.21,
                                                  child: Row(
                                                    children: [
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.width *
                                                                    0.025,
                                                            width: media.width *
                                                                0.025,
                                                            alignment: Alignment
                                                                .center,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: const Color(
                                                                        0xff319900)
                                                                    .withOpacity(
                                                                        0.3)),
                                                            child: Container(
                                                              height:
                                                                  media.width *
                                                                      0.01,
                                                              width:
                                                                  media.width *
                                                                      0.01,
                                                              decoration: const BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: Color(
                                                                      0xff319900)),
                                                            ),
                                                          ),
                                                          Column(
                                                            children: [
                                                              Container(
                                                                height: media
                                                                        .width *
                                                                    0.01,
                                                                width: media
                                                                        .width *
                                                                    0.001,
                                                                color: const Color(
                                                                    0xff319900),
                                                              ),
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.002,
                                                              ),
                                                              Container(
                                                                height: media
                                                                        .width *
                                                                    0.01,
                                                                width: media
                                                                        .width *
                                                                    0.001,
                                                                color: const Color(
                                                                    0xff319900),
                                                              ),
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.002,
                                                              ),
                                                              Container(
                                                                height: media
                                                                        .width *
                                                                    0.01,
                                                                width: media
                                                                        .width *
                                                                    0.001,
                                                                color: const Color(
                                                                    0xff319900),
                                                              ),
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.002,
                                                              ),
                                                              Container(
                                                                height: media
                                                                        .width *
                                                                    0.01,
                                                                width: media
                                                                        .width *
                                                                    0.001,
                                                                color: const Color(
                                                                    0xff319900),
                                                              ),
                                                            ],
                                                          ),
                                                          Container(
                                                            height:
                                                                media.width *
                                                                    0.025,
                                                            width: media.width *
                                                                0.025,
                                                            alignment: Alignment
                                                                .center,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: const Color(
                                                                        0xffFF0000)
                                                                    .withOpacity(
                                                                        0.3)),
                                                            child: Container(
                                                              height:
                                                                  media.width *
                                                                      0.01,
                                                              width:
                                                                  media.width *
                                                                      0.01,
                                                              decoration: const BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: Color(
                                                                      0xffFF0000)),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.03,
                                                      ),
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          (userRequestData
                                                                  .isNotEmpty)
                                                              ? SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.75,
                                                                  child: Text(
                                                                    userRequestData[
                                                                        'pick_address'],
                                                                    style: GoogleFonts.roboto(
                                                                        fontSize:
                                                                            media.width *
                                                                                twelve,
                                                                        color:
                                                                            textColor),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                )
                                                              : (addressList
                                                                      .where((e) =>
                                                                          e.id ==
                                                                          'drop')
                                                                      .isNotEmpty)
                                                                  ? SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.75,
                                                                      child:
                                                                          Text(
                                                                        addressList
                                                                            .firstWhere((element) =>
                                                                                element.id ==
                                                                                'pickup')
                                                                            .address,
                                                                        style: GoogleFonts.roboto(
                                                                            fontSize: media.width *
                                                                                twelve,
                                                                            color:
                                                                                textColor),
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    )
                                                                  : Container(),
                                                          Container(
                                                            height: 1,
                                                            width: media.width *
                                                                0.75,
                                                            color: borderLines,
                                                          ),
                                                          (userRequestData
                                                                  .isNotEmpty)
                                                              ? SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.75,
                                                                  child: Text(
                                                                    userRequestData[
                                                                        'drop_address'],
                                                                    style: GoogleFonts.roboto(
                                                                        fontSize:
                                                                            media.width *
                                                                                twelve,
                                                                        color:
                                                                            textColor),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                )
                                                              : (addressList
                                                                      .where((e) =>
                                                                          e.id ==
                                                                          'drop')
                                                                      .isNotEmpty)
                                                                  ? SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.75,
                                                                      child:
                                                                          Text(
                                                                        addressList
                                                                            .firstWhere((element) =>
                                                                                element.id ==
                                                                                'drop')
                                                                            .address,
                                                                        style: GoogleFonts.roboto(
                                                                            fontSize: media.width *
                                                                                twelve,
                                                                            color:
                                                                                textColor),
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    )
                                                                  : Container(),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                (userRequestData[
                                                            'is_trip_start'] !=
                                                        1)
                                                    ? Container(
                                                        margin: EdgeInsets.only(
                                                            bottom:
                                                                media.width *
                                                                    0.05),
                                                        height: 1,
                                                        width:
                                                            media.width * 0.9,
                                                        color: borderLines,
                                                      )
                                                    : Container(),
                                                (userRequestData[
                                                            'is_trip_start'] !=
                                                        1)
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          (userRequestData[
                                                                      'is_trip_start'] !=
                                                                  1)
                                                              ? InkWell(
                                                                  onTap:
                                                                      () async {
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          true;
                                                                    });
                                                                    var reason = await cancelReason((userRequestData['is_driver_arrived'] ==
                                                                            0)
                                                                        ? 'before'
                                                                        : 'after');
                                                                    if (reason ==
                                                                        true) {
                                                                      setState(
                                                                          () {
                                                                        _cancelling =
                                                                            true;
                                                                      });
                                                                    }
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          false;
                                                                    });
                                                                  },
                                                                  child: Column(
                                                                    children: [
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.064,
                                                                        width: media.width *
                                                                            0.064,
                                                                        child: Image.asset(
                                                                            'assets/images/cancel.png'),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.02,
                                                                      ),
                                                                      Text(
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_cancel'],
                                                                        style: GoogleFonts.roboto(
                                                                            fontSize: media.width *
                                                                                ten,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color: textColor),
                                                                      )
                                                                    ],
                                                                  ),
                                                                )
                                                              : Container(),
                                                        ],
                                                      )
                                                    : Container(),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                              ],
                                            ),
                                          ),
                                          (_ontripBottom == true)
                                              ? Container(
                                                  margin: EdgeInsets.only(
                                                      top: media.width * 0.05),
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.02),
                                                  height: media.width * 0.2,
                                                  width: media.width * 0.9,
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: borderLines,
                                                          width: 1.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            ['text_payingvia'],
                                                        style:
                                                            GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  twelve,
                                                          color: const Color(
                                                              0xff666666),
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          SizedBox(
                                                            width: media.width *
                                                                0.06,
                                                            child: (userRequestData[
                                                                        'payment_opt'] ==
                                                                    '1')
                                                                ? Image.asset(
                                                                    'assets/images/cash.png',
                                                                    fit: BoxFit
                                                                        .contain,
                                                                  )
                                                                : (userRequestData[
                                                                            'payment_opt'] ==
                                                                        '2')
                                                                    ? Image
                                                                        .asset(
                                                                        'assets/images/wallet.png',
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      )
                                                                    : (userRequestData['payment_opt'] ==
                                                                            '0')
                                                                        ? Image
                                                                            .asset(
                                                                            'assets/images/card.png',
                                                                            fit:
                                                                                BoxFit.contain,
                                                                          )
                                                                        : Container(),
                                                          ),
                                                          SizedBox(
                                                            width: media.width *
                                                                0.05,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                etaDetails[choosenVehicle]
                                                                        [
                                                                        'payment_type']
                                                                    .toString()
                                                                    .split(',')
                                                                    .toList()[
                                                                        payingVia]
                                                                    .toString(),
                                                                style: GoogleFonts.roboto(
                                                                    fontSize: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                              Text(
                                                                (userRequestData[
                                                                            'payment_opt'] ==
                                                                        '1')
                                                                    ? languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_paycash']
                                                                    : (userRequestData['payment_opt'] ==
                                                                            '2')
                                                                        ? languages[choosenLanguage]
                                                                            [
                                                                            'text_paywallet']
                                                                        : (userRequestData['payment_opt'] ==
                                                                                '0')
                                                                            ? languages[choosenLanguage]['text_paycard']
                                                                            : '',
                                                                style:
                                                                    GoogleFonts
                                                                        .roboto(
                                                                  fontSize:
                                                                      media.width *
                                                                          ten,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                )
                                              : Container()
                                        ],
                                      ),
                                    )),
                              ))
                          : Container(),

                      //cancel request
                      (_cancelling == true)
                          ? Positioned(
                              child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                        color: page,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Column(children: [
                                      Container(
                                        height: media.width * 0.18,
                                        width: media.width * 0.18,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xffFEF2F2)),
                                        alignment: Alignment.center,
                                        child: Container(
                                          height: media.width * 0.14,
                                          width: media.width * 0.14,
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xffFF0000)),
                                          child: const Center(
                                            child: Icon(
                                              Icons.cancel_outlined,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        children: cancelReasonsList
                                            .asMap()
                                            .map((i, value) {
                                              return MapEntry(
                                                  i,
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _cancelReason =
                                                            cancelReasonsList[i]
                                                                ['reason'];
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.01),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.height *
                                                                    0.05,
                                                            width: media.width *
                                                                0.05,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    color: Colors
                                                                        .black,
                                                                    width:
                                                                        1.2)),
                                                            alignment: Alignment
                                                                .center,
                                                            child: (_cancelReason ==
                                                                    cancelReasonsList[
                                                                            i][
                                                                        'reason'])
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
                                                            width: media.width *
                                                                0.05,
                                                          ),
                                                          SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.65,
                                                              child: Text(
                                                                  cancelReasonsList[
                                                                          i][
                                                                      'reason']))
                                                        ],
                                                      ),
                                                    ),
                                                  ));
                                            })
                                            .values
                                            .toList(),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _cancelReason = 'others';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(
                                              media.width * 0.01),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: media.height * 0.05,
                                                width: media.width * 0.05,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.black,
                                                        width: 1.2)),
                                                alignment: Alignment.center,
                                                child: (_cancelReason ==
                                                        'others')
                                                    ? Container(
                                                        height:
                                                            media.width * 0.03,
                                                        width:
                                                            media.width * 0.03,
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.black,
                                                        ),
                                                      )
                                                    : Container(),
                                              ),
                                              SizedBox(
                                                width: media.width * 0.05,
                                              ),
                                              Text(languages[choosenLanguage]
                                                  ['text_others'])
                                            ],
                                          ),
                                        ),
                                      ),
                                      (_cancelReason == 'others')
                                          ? Container(
                                              margin: EdgeInsets.fromLTRB(
                                                  0,
                                                  media.width * 0.025,
                                                  0,
                                                  media.width * 0.025),
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              // height: media.width*0.2,
                                              width: media.width * 0.9,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: TextField(
                                                decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    hintText: languages[
                                                            choosenLanguage][
                                                        'text_cancelRideReason'],
                                                    hintStyle:
                                                        GoogleFonts.roboto(
                                                            fontSize:
                                                                media.width *
                                                                    twelve)),
                                                maxLines: 4,
                                                minLines: 2,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _cancelCustomReason = val;
                                                  });
                                                },
                                              ),
                                            )
                                          : Container(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Button(
                                              color: page,
                                              textcolor: buttonColor,
                                              width: media.width * 0.39,
                                              onTap: () async {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                if (_cancelReason != '') {
                                                  if (_cancelReason ==
                                                      'others') {
                                                    await cancelRequestWithReason(
                                                        _cancelCustomReason);
                                                    setState(() {
                                                      _cancelling = false;
                                                    });
                                                  } else {
                                                    await cancelRequestWithReason(
                                                        _cancelReason);
                                                    setState(() {
                                                      _cancelling = false;
                                                    });
                                                  }
                                                } else {}
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_cancel']),
                                          Button(
                                              width: media.width * 0.39,
                                              onTap: () {
                                                setState(() {
                                                  _cancelling = false;
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['tex_dontcancel'])
                                        ],
                                      )
                                    ]),
                                  ),
                                ],
                              ),
                            ))
                          : Container(),

                      //date picker for ride later
                      (_dateTimePicker == true)
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
                                                      _dateTimePicker = false;
                                                    });
                                                  },
                                                  child: const Icon(
                                                      Icons.cancel_outlined))),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: media.width * 0.5,
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: CupertinoDatePicker(
                                          minimumDate: DateTime.now()
                                              .add(const Duration(minutes: 30)),
                                          initialDateTime: DateTime.now()
                                              .add(const Duration(minutes: 31)),
                                          maximumDate: DateTime.now()
                                              .add(const Duration(days: 4)),
                                          onDateTimeChanged: (val) {
                                            choosenDateTime = val;
                                          }),
                                    ),
                                    Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.05),
                                        child: Button(
                                            onTap: () {
                                              setState(() {
                                                _dateTimePicker = false;
                                                _confirmRideLater = true;
                                              });
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_confirm']))
                                  ],
                                ),
                              ))
                          : Container(),

                      //confirm ride later
                      (_confirmRideLater == true)
                          ? Positioned(
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
                                                      _dateTimePicker = true;
                                                      _confirmRideLater = false;
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
                                                ['text_confirmridelater'],
                                            style: GoogleFonts.roboto(
                                                fontSize:
                                                    media.width * fourteen,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Text(
                                            DateFormat()
                                                .format(choosenDateTime)
                                                .toString(),
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
                                                if (etaDetails[choosenVehicle]
                                                        ['has_discount'] ==
                                                    false) {
                                                  dynamic val;
                                                  setState(() {
                                                    _isLoading = true;
                                                  });

                                                  val =
                                                      await createRequestLater();
                                                  setState(() {
                                                    if (val == 'success') {
                                                      _isLoading = false;
                                                      _confirmRideLater = false;
                                                      _rideLaterSuccess = true;
                                                    }
                                                  });
                                                } else {
                                                  dynamic val;
                                                  setState(() {
                                                    _isLoading = true;
                                                  });

                                                  val =
                                                      await createRequestLaterPromo();
                                                  setState(() {
                                                    if (val == 'success') {
                                                      _isLoading = false;

                                                      _confirmRideLater = false;
                                                      _rideLaterSuccess = true;
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
                              ),
                            )
                          : Container(),

                      //ride later success
                      (_rideLaterSuccess == true)
                          ? Positioned(
                              child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_rideLaterSuccess'],
                                            style: GoogleFonts.roboto(
                                                fontSize:
                                                    media.width * fourteen,
                                                color: textColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () {
                                                addressList.removeWhere(
                                                    (element) =>
                                                        element.id == 'drop');
                                                _rideLaterSuccess = false;
                                                // addressList.clear();
                                                myMarker.clear();
                                                Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const Maps()),
                                                    (route) => false);
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_confirm'])
                                        ],
                                      ),
                                    )
                                  ]),
                            ))
                          : Container(),

                      //sos popup
                      (showSos == true)
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
                                        width: media.width * 0.7,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  notifyCompleted = false;
                                                  showSos = false;
                                                });
                                              },
                                              child: Container(
                                                height: media.width * 0.1,
                                                width: media.width * 0.1,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: page),
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
                                        height: media.height * 0.5,
                                        width: media.width * 0.7,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: page),
                                        child: SingleChildScrollView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                InkWell(
                                                  onTap: () async {
                                                    setState(() {
                                                      notifyCompleted = false;
                                                    });
                                                    var val =
                                                        await notifyAdmin();
                                                    if (val == true) {
                                                      setState(() {
                                                        notifyCompleted = true;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.05),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_notifyadmin'],
                                                              style: GoogleFonts.roboto(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            (notifyCompleted ==
                                                                    true)
                                                                ? Container(
                                                                    padding: EdgeInsets.only(
                                                                        top: media.width *
                                                                            0.01),
                                                                    child: Text(
                                                                      languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_notifysuccess'],
                                                                      style: GoogleFonts
                                                                          .roboto(
                                                                        fontSize:
                                                                            media.width *
                                                                                twelve,
                                                                        color: const Color(
                                                                            0xff319900),
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Container()
                                                          ],
                                                        ),
                                                        const Icon(Icons
                                                            .notification_add)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                (sosData.isNotEmpty)
                                                    ? Column(
                                                        children: sosData
                                                            .asMap()
                                                            .map((i, value) {
                                                              return MapEntry(
                                                                  i,
                                                                  InkWell(
                                                                    onTap: () {
                                                                      makingPhoneCall(sosData[i]
                                                                              [
                                                                              'number']
                                                                          .toString()
                                                                          .replaceAll(
                                                                              ' ',
                                                                              ''));
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      padding: EdgeInsets.all(
                                                                          media.width *
                                                                              0.05),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              SizedBox(
                                                                                width: media.width * 0.4,
                                                                                child: Text(
                                                                                  sosData[i]['name'],
                                                                                  style: GoogleFonts.roboto(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                height: media.width * 0.01,
                                                                              ),
                                                                              Text(
                                                                                sosData[i]['number'],
                                                                                style: GoogleFonts.roboto(
                                                                                  fontSize: media.width * twelve,
                                                                                  color: textColor,
                                                                                ),
                                                                              )
                                                                            ],
                                                                          ),
                                                                          const Icon(
                                                                              Icons.call)
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ));
                                                            })
                                                            .values
                                                            .toList(),
                                                      )
                                                    : Container(
                                                        width:
                                                            media.width * 0.7,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_noDataFound'],
                                                          style: GoogleFonts.roboto(
                                                              fontSize:
                                                                  media.width *
                                                                      eighteen,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: textColor),
                                                        ),
                                                      ),
                                              ],
                                            )),
                                      )
                                    ]),
                              ))
                          : Container(),

                      //loader
                      (_isLoading == true)
                          ? const Positioned(top: 0, child: Loading())
                          : Container(),

                      //no internet
                      (internet == false)
                          ? Positioned(
                              top: 0,
                              child: NoInternet(
                                onTap: () {
                                  setState(() {
                                    internetTrue();
                                  });
                                },
                              ))
                          : Container(),

                      //pick drop marker
                      Positioned(
                        top: media.height * 1.5,
                        child: RepaintBoundary(
                            key: iconKey,
                            child: Column(
                              children: [
                                Container(
                                  width: media.width * 0.5,
                                  height: media.width * 0.12,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: page),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: media.width * 0.12,
                                        width: media.width * 0.12,
                                        decoration: BoxDecoration(
                                            borderRadius: (languageDirection ==
                                                    'ltr')
                                                ? const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(10),
                                                    bottomLeft:
                                                        Radius.circular(10))
                                                : const BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(10),
                                                    bottomRight:
                                                        Radius.circular(10)),
                                            color: const Color(0xff222222)),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.star,
                                          color: Color(0xff319900),
                                        ),
                                      ),
                                      Expanded(
                                          child: Container(
                                        padding: EdgeInsets.only(
                                            left: media.width * 0.02,
                                            right: media.width * 0.02),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              languages[choosenLanguage]
                                                  ['text_pickpoint'],
                                              style: GoogleFonts.roboto(
                                                  fontSize:
                                                      media.width * twelve,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            (userRequestData.isNotEmpty)
                                                ? Text(
                                                    userRequestData[
                                                        'pick_address'],
                                                    maxLines: 1,
                                                    overflow: TextOverflow.fade,
                                                    softWrap: false,
                                                    style: GoogleFonts.roboto(
                                                        fontSize: media.width *
                                                            twelve),
                                                  )
                                                : (addressList
                                                        .where((element) =>
                                                            element.id ==
                                                            'pickup')
                                                        .isNotEmpty)
                                                    ? Text(
                                                        addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .id ==
                                                                    'pickup')
                                                            .address,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.fade,
                                                        softWrap: false,
                                                        style:
                                                            GoogleFonts.roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    twelve),
                                                      )
                                                    : Container(),
                                          ],
                                        ),
                                      ))
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                          image: AssetImage(
                                              'assets/images/userloc.png'),
                                          fit: BoxFit.contain)),
                                  height: media.width * 0.05,
                                  width: media.width * 0.05,
                                )
                              ],
                            )),
                      ),
                      Positioned(
                          top: media.height * 2,
                          child: RepaintBoundary(
                              key: iconDropKey,
                              child: Column(
                                children: [
                                  Container(
                                    width: media.width * 0.5,
                                    height: media.width * 0.12,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: page),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: media.width * 0.12,
                                          width: media.width * 0.12,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  (languageDirection == 'ltr')
                                                      ? const BorderRadius.only(
                                                          topLeft:
                                                              Radius
                                                                  .circular(10),
                                                          bottomLeft:
                                                              Radius
                                                                  .circular(10))
                                                      : const BorderRadius.only(
                                                          topRight: Radius
                                                              .circular(10),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  10)),
                                              color: const Color(0xff222222)),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.star,
                                            color: Color(0xffE60000),
                                          ),
                                        ),
                                        Expanded(
                                            child: Container(
                                          padding: EdgeInsets.only(
                                              left: media.width * 0.02,
                                              right: media.width * 0.02),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_droppoint'],
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * twelve,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              (userRequestData.isNotEmpty)
                                                  ? Text(
                                                      userRequestData[
                                                          'drop_address'],
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.fade,
                                                      softWrap: false,
                                                      style: GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  twelve),
                                                    )
                                                  : (addressList
                                                          .where((element) =>
                                                              element.id ==
                                                              'drop')
                                                          .isNotEmpty)
                                                      ? Text(
                                                          addressList
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .id ==
                                                                      'drop')
                                                              .address,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.fade,
                                                          softWrap: false,
                                                          style: GoogleFonts
                                                              .roboto(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve),
                                                        )
                                                      : Container(),
                                            ],
                                          ),
                                        ))
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                            image: AssetImage(
                                                'assets/images/droploc.png'),
                                            fit: BoxFit.contain)),
                                    height: media.width * 0.05,
                                    width: media.width * 0.05,
                                  )
                                ],
                              )))
                    ],
                  );
                }),
          ),
        ),
      ),
    );
  }
}
