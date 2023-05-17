import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/NavigatorPages/walletpage.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/noInternet/noInternet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';
import 'package:flutterwave_standard/flutterwave.dart';

class FlutterWavePage extends StatefulWidget {
  const FlutterWavePage({Key? key}) : super(key: key);

  @override
  _FlutterWavePageState createState() => _FlutterWavePageState();
}

class _FlutterWavePageState extends State<FlutterWavePage> {
  bool _isLoading = false;
  bool _success = false;
  bool _failed = false;
  dynamic flutterwave;
  @override
  void initState() {
    payMoney();
    super.initState();
  }

//payment gateway code
  payMoney() async {
    setState(() {
      _isLoading = true;
    });

    final style = FlutterwaveStyle(
      appBarText: "Flutterwave Checkout",
      buttonColor: buttonColor,
      appBarIcon: const Icon(Icons.message, color: Color(0xffd0ebff)),
      buttonTextStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      appBarColor: const Color(0xffd0ebff),
      dialogCancelTextStyle: const TextStyle(
        color: Colors.redAccent,
        fontSize: 16,
      ),
      dialogContinueTextStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 16,
      ),
    );

    final Customer customer = Customer(
        name: userDetails['name'],
        phoneNumber: userDetails['mobile'],
        email: userDetails['email']);

    flutterwave = Flutterwave(
      redirectUrl: '',
      context: context,
      style: style,
      publicKey: "public key",
      currency: "NGN",
      txRef: "${userDetails['id'].toString()} ${DateTime.now().toString()}",
      amount: addMoney.toString(),
      customer: customer,
      paymentOptions: "ussd, card, barter, payattitude, account",
      customization: Customization(title: "Test Payment"),
      isTestMode: true,
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(media.width * 0.05,
                        media.width * 0.05, media.width * 0.05, 0),
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        Stack(
                          children: [
                            Container(
                              padding:
                                  EdgeInsets.only(bottom: media.width * 0.05),
                              width: media.width * 0.9,
                              alignment: Alignment.center,
                              child: Text(
                                languages[choosenLanguage]['text_addmoney'],
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * sixteen,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Positioned(
                                child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Icon(Icons.arrow_back)))
                          ],
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        Text(
                          walletBalance['currency_symbol'] +
                              ' ' +
                              addMoney.toString(),
                          style: GoogleFonts.roboto(
                              fontSize: media.width * twenty,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        Button(
                            onTap: () async {
                              final ChargeResponse response =
                                  await flutterwave.charge();
// ignore: unnecessary_null_comparison
                              if (response != null) {
                                if (response.status == 'success') {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  var val = await addMoneyFlutterwave(
                                      addMoney, response.transactionId);
                                  if (val == 'success') {
                                    setState(() {
                                      _success = true;
                                      _isLoading = false;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    _failed = true;
                                    _isLoading = false;
                                  });
                                  // Transaction not successful
                                }
                              } else {
                                _isLoading = false;
                                Navigator.pop(context, true);
                              }
                            },
                            text: 'Pay')
                      ],
                    ),
                  ),
                  //payment failed
                  (_failed == true)
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
                                  padding: EdgeInsets.all(media.width * 0.05),
                                  width: media.width * 0.9,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: page),
                                  child: Column(
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_somethingwentwrong'],
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
                                              _failed = false;
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
                  (_success == true)
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
                                  padding: EdgeInsets.all(media.width * 0.05),
                                  width: media.width * 0.9,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: page),
                                  child: Column(
                                    children: [
                                      Text(
                                        languages[choosenLanguage]
                                            ['text_paymentsuccess'],
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
                                              _success = false;
                                              // super.detachFromGLContext();
                                              Navigator.pop(context, true);
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

                  //no internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _isLoading = true;
                              });
                            },
                          ))
                      : Container(),

                  //loader
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container()
                ],
              ),
            );
          }),
    );
  }
}
