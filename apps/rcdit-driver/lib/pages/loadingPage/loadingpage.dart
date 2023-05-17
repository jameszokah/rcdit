import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rcdit_user/pages/onTripPage/booking_confirmation.dart';
import 'package:rcdit_user/pages/onTripPage/invoice.dart';
import 'package:rcdit_user/pages/language/languages.dart';
import 'package:rcdit_user/pages/login/login.dart';
import 'package:rcdit_user/pages/onTripPage/map_page.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  String dot = '.';
  var demopage = TextEditingController();

  @override
  void initState() {
    getLanguageDone();

    super.initState();
  }

//get language json and data saved in local (bearer token , choosen language) and find users current status
  getLanguageDone() async {
    
    await getDetailsOfDevice();
    if (internet == true) {
      var val = await getLocalData();

      if (val == '3') {

        if (userRequestData.isNotEmpty &&
            userRequestData['is_completed'] == 1) {
              //invoice page of ride
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Invoice()),
              (route) => false);
        } else if (userRequestData.isNotEmpty &&
            userRequestData['is_completed'] != 1) {
              //searching ride page
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const BookingConfirmation()),
              (route) => false);
          mqttForUser();
        } else {
          //home page
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Maps()),
              (route) => false);
        }
      } else if (val == '2') {
        Future.delayed(const Duration(seconds: 2), () {
          //login page
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const Login()));
        });
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          //choose language page
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const Languages()));
        });
      }
    } else {
      setState(() {});
    }
   
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: media.height * 1,
              width: media.width * 1,
              decoration: BoxDecoration(
                color: page,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(media.width * 0.01),
                    width: media.width * 0.429,
                    height: media.width * 0.429,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/logo.png'),
                            fit: BoxFit.contain)),
                  ),
                ],
              ),
            ),

            //no internet
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(
                      onTap: () {
                        setState(() {
                          internetTrue();
                          getLanguageDone();
                        });
                      },
                    ))
                : Container(),
            
          ],
        ),
      ),
    );
  }
}
