import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/NavigatorPages/walletpage.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/noInternet/noInternet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';


class RazorPayPage extends StatefulWidget {
  const RazorPayPage({Key? key}) : super(key: key);

  @override
  _RazorPayPageState createState() => _RazorPayPageState();
}



class _RazorPayPageState extends State<RazorPayPage> {
  bool _isLoading = false;
  bool _success = false;
  bool _failed = false;
 dynamic _razorpay;

  @override
  void initState() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    payMoney();
    super.initState();
  }


void _handlePaymentSuccess(PaymentSuccessResponse response)async {
    var val = await addMoneyRazorpay(addMoney , response.paymentId);
    if(val == 'success'){
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
   
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _failed = true;
      _isLoading = false;
    });
  
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
   
  }


//payment gateway code
payMoney()async{
   setState(() {
                                      _isLoading = true;
                                    });
    var options = {
  'key': 'key',
  'amount': addMoney * 100,
  'name': userDetails['name'],
  'description': '',
  'prefill': {
    'contact': userDetails['mobile'],
    'email': userDetails['email']
  }
};

await _razorpay.open(options);

                                    
                                    
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
