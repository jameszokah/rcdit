import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/NavigatorPages/walletpage.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/noInternet/noInternet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';
import 'package:cashfree_pg/cashfree_pg.dart';


class CashFreePage extends StatefulWidget {
  const CashFreePage({Key? key}) : super(key: key);

  @override
  _CashFreePageState createState() => _CashFreePageState();
}



class _CashFreePageState extends State<CashFreePage> {
  bool _isLoading = false;
  bool _success = false;
  bool _failed = false;

  @override
  void initState() {
    payMoney();
    super.initState();
  }

//payment code
payMoney()async{
   setState(() {
                                      _isLoading = true;
                                    });
var getToken = await getCfToken(addMoney.toString(),walletBalance['currency_code'] );
                                                  if(getToken == 'success'){
                                                    
                                                    await CashfreePGSDK.doPayment({
                                                    'appId':'app id',
                                                    'stage' : 'TEST',
                                                    'orderId' : cftToken['orderId'],
                                                    'orderAmount' : addMoney.toString(),
                                                    'orderCurrency' : walletBalance['currency_code'],
                                                    'customerPhone' : userDetails['mobile'],
                                                    'customerEmail' : userDetails['email'],
                                                    'tokenData' : cftToken['cftoken'],
                                                    'color1' : '#FCB13D',
                                                    'color2' : '#ffffff',
                                                    'customerName' : userDetails['name']
                                                    }).then((value) async{
                                                      cfSuccessList = jsonDecode(jsonEncode(value));
                                                      if(cfSuccessList['txStatus'] == 'SUCCESS'){
                                                       var verify = await cashFreePaymentSuccess();
                                                       if(verify == 'success'){
                                                         setState(() {
                                                            _success = true;
                                                  _isLoading = false;
                                                });
                                                       }else{
                                                         setState(() {
                                                           _failed = true;
                                                           _isLoading = false;
                                                         });
                                                       }
                                                      }else{
                                                        setState(() {
                                                          _failed = true;
                                                        });
                                                      }
                                                    });
                                                  }else{
                                                    setState(() {
                                                      _failed = true;
                                                    });
                                                  }
                                    
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
                                            Navigator.pop(context,true);
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

                      //payment success
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
