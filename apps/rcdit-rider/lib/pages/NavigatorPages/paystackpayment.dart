import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/NavigatorPages/walletpage.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';

class PayStackPage extends StatefulWidget {
  const PayStackPage({Key? key}) : super(key: key);

  @override
  _PayStackPageState createState() => _PayStackPageState();
}



class _PayStackPageState extends State<PayStackPage> {
  bool _isLoading = false;
  bool _success = false;
  bool _failed = false;
 final plugin = PaystackPlugin();
  @override
  void initState() {
    plugin.initialize(publicKey: 'public key');
    payMoney();
    super.initState();
  }

//payment gateway code

payMoney()async{
   setState(() {
                                      _isLoading = true;
                                    });
                                    var val = await getPaystackPayment(addMoney * 100);
                                    if(val == 'success'){
                                    Charge charge = Charge()
                                    ..amount = addMoney * 100
                                    ..reference = paystackCode['reference']
                                    ..accessCode = paystackCode['access_code']
                                    ..email = userDetails['email'];

                                    var response = await plugin.checkout(
       context,
       method: CheckoutMethod.selectable, // Defaults to CheckoutMethod.selectable
       charge: charge,
     );
    
     if(response.message == 'Transaction terminated'){
       Navigator.pop(context,true);
     }
     if(response.status == false){
    
       setState(() {
         _failed = true;
         _isLoading = false;
       });
     }
    else if(response.message == 'Success'){
      var val = await addMoneyPaystack(addMoney, response.reference);
      if(val == 'success'){
        setState(() {
          _success = true;
        });
      }
     }
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

                      //success
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
