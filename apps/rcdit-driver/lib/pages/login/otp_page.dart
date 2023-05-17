import 'package:flutter/material.dart';
import 'package:rcdit_user/pages/onTripPage/booking_confirmation.dart';
import 'package:rcdit_user/pages/onTripPage/invoice.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/login/get_started.dart';
import 'package:rcdit_user/pages/login/login.dart';
import 'package:rcdit_user/pages/onTripPage/map_page.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class Otp extends StatefulWidget {
  const Otp({Key? key}) : super(key: key);

  @override
  _OtpState createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  String otpNumber = ''; //otp number
  List otpText = []; //otp number as list for 6 boxes
  List otpPattern = [1, 2, 3, 4, 5, 6]; //list to create number of input box
  var resendTime = 60; //otp resend time
  late Timer timer; //timer for resend time
  String _error =
      ''; //otp error string to show if error occurs in otp validation
  TextEditingController otpController =
      TextEditingController(); //otp textediting controller
  TextEditingController first = TextEditingController();
  TextEditingController second = TextEditingController();
  TextEditingController third = TextEditingController();
  TextEditingController fourth = TextEditingController();
  TextEditingController fifth = TextEditingController();
  TextEditingController sixth = TextEditingController();
  bool _loading = false; //loading screen showing
  @override
  void initState() {
    _loading = false;
    timers();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel;
    super.dispose();
  }
  //auto verify otp

  verifyOtp() async {
    try {
      // Sign the user in (or link) with the credential
      await FirebaseAuth.instance.signInWithCredential(credentials);

      var verify = await verifyUser(phnumber);
      if (verify == true) {
        if (userRequestData.isNotEmpty &&
            userRequestData['is_completed'] == 1) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Invoice()),
              (route) => false);
        } else if (userRequestData.isNotEmpty &&
            userRequestData['is_completed'] != 1) {
          mqttForUser();
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const BookingConfirmation()),
                (route) => false);
          });
        } else {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Maps()),
              (route) => false);
        }
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const GetStarted()));
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-verification-code') {
        setState(() {
          otpController.clear();
          otpNumber = '';
          _error = languages[choosenLanguage]['text_otp_error'];
        });
      }
    }
  }

// running resend otp timer
  timers() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTime != 0) {
        if (mounted) {
          setState(() {
            resendTime--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              if (credentials != null) {
                _loading = true;
                verifyOtp();
              }
              return Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: media.width * 0.08, right: media.width * 0.08),
                    color: page,
                    height: media.height * 1,
                    width: media.width * 1,
                    child: Column(
                      children: [
                        Container(
                            height: media.height * 0.12,
                            width: media.width * 1,
                            color: topBar,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Icon(Icons.arrow_back)),
                              ],
                            )),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: media.height * 0.04,
                              ),
                              SizedBox(
                                width: media.width * 1,
                                child: Text(
                                  languages[choosenLanguage]
                                      ['text_phone_verify'],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twentyeight,
                                      fontWeight: FontWeight.bold,
                                      color: textColor),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                languages[choosenLanguage]['text_enter_otp'],
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * sixteen,
                                    color: textColor.withOpacity(0.3)),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                countries[phcode]['dial_code'] + phnumber,
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * sixteen,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1),
                              ),
                              SizedBox(height: media.height * 0.1),

                              //otp text box
                              Container(
                                height: media.width * 0.15,
                                width: media.width * 0.9,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: page,
                                    border: Border.all(
                                        color: borderLines, width: 1.2)),
                                child: TextField(
                                  autofocus: true,
                                  onChanged: (val) {
                                    setState(() {
                                      otpNumber = val;
                                    });
                                    if (val.length == 6) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    }
                                  },
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      counterText: '',
                                      hintText: languages[choosenLanguage]
                                          ['text_enter_otp_login']),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    fontSize: media.width * twenty,
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLength: 6,
                                  keyboardType: TextInputType.number,
                                ),
                              ),

                              //otp error
                              (_error != '')
                                  ? Container(
                                      alignment: Alignment.center,
                                      margin: EdgeInsets.only(
                                          top: media.height * 0.02),
                                      child: Text(
                                        _error,
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * sixteen,
                                            color: Colors.red),
                                      ),
                                    )
                                  : Container(),
                              SizedBox(
                                height: media.height * 0.05,
                              ),
                              Container(
                                alignment: Alignment.center,
                                child: Button(
                                  onTap: () async {
                                    if (otpNumber.length == 6) {
                                      setState(() {
                                        _loading = true;
                                        _error = '';
                                      });
                                      //firebase code send false
                                      if (phoneAuthCheck == false) {
                                        var verify = await verifyUser(phnumber);

                                        if (verify == true) {
                                          if (userRequestData.isNotEmpty &&
                                              userRequestData['is_completed'] ==
                                                  1) {
                                                    //invoice page
                                            Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Invoice()),
                                                (route) => false);
                                          } else if (userRequestData
                                                  .isNotEmpty &&
                                              userRequestData['is_completed'] !=
                                                  1) {
                                            mqttForUser();
                                            Future.delayed(
                                                const Duration(seconds: 2), () {
                                                  // ride page
                                              Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const BookingConfirmation()),
                                                  (route) => false);
                                            });
                                          } else {
                                            //home page
                                            Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Maps()),
                                                (route) => false);
                                            
                                          }
                                        } else {
                                          //get started
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const GetStarted()));
                                        }
                                      } else {
                                        // firebase code send true
                                        try {
                                          PhoneAuthCredential credential =
                                              PhoneAuthProvider.credential(
                                                  verificationId: verId,
                                                  smsCode: otpNumber);

                                          // Sign the user in (or link) with the credential
                                          await FirebaseAuth.instance
                                              .signInWithCredential(credential);

                                          var verify =
                                              await verifyUser(phnumber);
                                          if (verify == true) {
                                            if (userRequestData.isNotEmpty &&
                                                userRequestData[
                                                        'is_completed'] ==
                                                    1) {
                                              Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const Invoice()),
                                                  (route) => false);
                                            } else if (userRequestData
                                                    .isNotEmpty &&
                                                userRequestData[
                                                        'is_completed'] !=
                                                    1) {
                                              mqttForUser();
                                              Future.delayed(
                                                  const Duration(seconds: 2),
                                                  () {
                                                Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const BookingConfirmation()),
                                                    (route) => false);
                                              });
                                            } else {
                                              Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const Maps()),
                                                  (route) => false);
                                            }
                                          } else {
                                            Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const GetStarted()));
                                          }
                                        } on FirebaseAuthException catch (error) {
                                          if (error.code ==
                                              'invalid-verification-code') {
                                            setState(() {
                                              otpController.clear();
                                              otpNumber = '';
                                              _error =
                                                  languages[choosenLanguage]
                                                      ['text_otp_error'];
                                            });
                                          }
                                        }
                                      }
                                      setState(() {
                                        _loading = false;
                                      });
                                    } else if (phoneAuthCheck == true &&
                                        resendTime == 0 &&
                                        otpNumber.length != 6) {
                                      setState(() {
                                        setState(() {
                                          resendTime = 60;
                                        });
                                        timers();
                                      });
                                      phoneAuth(countries[phcode]['dial_code'] +
                                          phnumber);
                                    }
                                  },
                                  text: (otpNumber.length == 6)
                                      ? languages[choosenLanguage]
                                          ['text_verify']
                                      : (resendTime == 0)
                                          ? languages[choosenLanguage]
                                              ['text_resend_code']
                                          : languages[choosenLanguage]
                                                  ['text_resend_code'] +
                                              ' ' +
                                              resendTime.toString(),
                                  color:
                                      (resendTime != 0 && otpNumber.length != 6)
                                          ? underline
                                          : null,
                                  borcolor:
                                      (resendTime != 0 && otpNumber.length != 6)
                                          ? underline
                                          : null,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  //no internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(onTap: () {
                            setState(() {
                              internetTrue();
                            });
                          }))
                      : Container(),

                  //loader
                  (_loading == true)
                      ? Positioned(
                          top: 0,
                          child: SizedBox(
                            height: media.height * 1,
                            width: media.width * 1,
                            child: const Loading(),
                          ))
                      : Container()
                ],
              );
            }),
      ),
    );
  }
}
