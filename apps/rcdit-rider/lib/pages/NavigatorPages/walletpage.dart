import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/NavigatorPages/selectwallet.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';
import 'paystackpayment.dart';
import 'flutterWavePage.dart';
import 'razorpaypage.dart';
import 'cashfreepage.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  _WalletPageState createState() => _WalletPageState();
} 

dynamic addMoney;

class _WalletPageState extends State<WalletPage> {
  TextEditingController addMoneyController = TextEditingController();

  bool _isLoading = true;
  bool _addPayment = false;
  bool _choosePayment = false;
  @override
  void initState() {
    getWallet();
    super.initState();
  }

//get wallet details
  getWallet() async {
    var val = await getWalletHistory();
    if (val == 'success') {
      _isLoading = false;

      valueNotifierBook.incrementNotifier();
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: ValueListenableBuilder(
          valueListenable: valueNotifierBook.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Scaffold(
                body: Stack(
                  alignment: Alignment.center,
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
                                width: media.width * 1,
                                alignment: Alignment.center,
                                child: Text(
                                  languages[choosenLanguage]
                                      ['text_enable_wallet'],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twenty,
                                      fontWeight: FontWeight.w600,
                                      color: textColor),
                                ),
                              ),
                              Positioned(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Icon(Icons.arrow_back)))
                            ],
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          (walletBalance.isNotEmpty)
                              ? Column(
                                  children: [
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_availablebalance'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * twelve,
                                          color: textColor),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.01,
                                    ),
                                    Text(
                                      walletBalance['currency_symbol'] +
                                          walletBalance['wallet_balance']
                                              .toString(),
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * fourty,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Text(
                                        languages[choosenLanguage]
                                            ['text_recenttransactions'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * fourteen,
                                            color: textColor,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(),
                          Expanded(
                              child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                Column(
                                  children: walletHistory
                                      .asMap()
                                      .map((i, value) {
                                        return MapEntry(
                                            i,
                                            Container(
                                              margin: EdgeInsets.only(
                                                  top: media.width * 0.02,
                                                  bottom: media.width * 0.02),
                                              width: media.width * 0.9,
                                              padding: EdgeInsets.all(
                                                  media.width * 0.025),
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: page),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height:
                                                        media.width * 0.1067,
                                                    width: media.width * 0.1067,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color: const Color(
                                                                0xff000000)
                                                            .withOpacity(0.05)),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      (walletHistory[i][
                                                                  'is_credit'] ==
                                                              1)
                                                          ? '+'
                                                          : '-',
                                                      style: GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  twentyfour,
                                                          color: textColor),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.025,
                                                  ),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [walletHistory[i]
                                                                ['remarks']],
                                                        style:
                                                            GoogleFonts.roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.01,
                                                      ),
                                                      Text(
                                                        walletHistory[i]
                                                            ['created_at'],
                                                        style:
                                                            GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width * ten,
                                                          color: hintColor,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Expanded(
                                                      child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        walletHistory[i][
                                                                'currency_symbol'] +
                                                            ' ' +
                                                            walletHistory[i]
                                                                    ['amount']
                                                                .toString(),
                                                        style:
                                                            GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  twelve,
                                                          color: const Color(
                                                              0xffE60000),
                                                        ),
                                                      )
                                                    ],
                                                  ))
                                                ],
                                              ),
                                            ));
                                      })
                                      .values
                                      .toList(),
                                ),

                                //load more button
                                (walletPages.isNotEmpty)
                                    ? (walletPages['current_page'] <
                                            walletPages['total_pages'])
                                        ? InkWell(
                                            onTap: () async {
                                              setState(() {
                                                _isLoading = true;
                                              });

                                              await getWalletHistoryPage(
                                                  (walletPages['current_page'] +
                                                          1)
                                                      .toString());

                                              setState(() {
                                                _isLoading = false;
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.025),
                                              margin: EdgeInsets.only(
                                                  bottom: media.width * 0.05),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: page,
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2)),
                                              child: Text(
                                                languages[choosenLanguage]
                                                    ['text_loadmore'],
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * sixteen,
                                                    color: textColor),
                                              ),
                                            ),
                                          )
                                        : Container()
                                    : Container()
                              ],
                            ),
                          )),

                          //add payment popup
                          (_addPayment == false)
                              ? Container(
                                  padding: EdgeInsets.only(
                                      top: media.width * 0.05,
                                      bottom: media.width * 0.05),
                                  child: Button(
                                      onTap: () {
                                        if (_addPayment == false) {
                                          setState(() {
                                            _addPayment = true;
                                          });
                                        }
                                      },
                                      text: languages[choosenLanguage]
                                          ['text_addmoney']),
                                )
                              : Container()
                        ],
                      ),
                    ),

                    //add payment
                    (_addPayment == true)
                        ? Positioned(
                            bottom: 0,
                            child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(
                                        bottom: media.width * 0.05),
                                    width: media.width * 0.9,
                                    padding:
                                        EdgeInsets.all(media.width * 0.025),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: borderLines, width: 1.2),
                                        color: page),
                                    child: Column(children: [
                                      Container(
                                        height: media.width * 0.128,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: borderLines, width: 1.2),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                                width: media.width * 0.1,
                                                height: media.width * 0.128,
                                                decoration: const BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(12),
                                                      bottomLeft:
                                                          Radius.circular(12),
                                                    ),
                                                    color: Color(0xffF0F0F0)),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  walletBalance[
                                                      'currency_symbol'],
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * fifteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                )),
                                            SizedBox(
                                              width: media.width * 0.05,
                                            ),
                                            Container(
                                              height: media.width * 0.128,
                                              width: media.width * 0.6,
                                              alignment: Alignment.center,
                                              child: TextField(
                                                controller: addMoneyController,
                                                onChanged: (val) {
                                                  setState(() {
                                                    addMoney = int.parse(val);
                                                  });
                                                },
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText:
                                                      languages[choosenLanguage]
                                                          ['text_enteramount'],
                                                  hintStyle: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * twelve,
                                                      color: hintColor),
                                                ),
                                                maxLines: 1,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.05,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text = '100';
                                                addMoney = 100;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.17,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: Text(
                                                walletBalance[
                                                        'currency_symbol'] +
                                                    '100',
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * twelve,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: media.width * 0.05,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text = '500';
                                                addMoney = 500;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.17,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: Text(
                                                walletBalance[
                                                        'currency_symbol'] +
                                                    '500',
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * twelve,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: media.width * 0.05,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text =
                                                    '1000';
                                                addMoney = 1000;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.17,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: Text(
                                                walletBalance[
                                                        'currency_symbol'] +
                                                    '1000',
                                                style: GoogleFonts.roboto(
                                                    fontSize:
                                                        media.width * twelve,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: media.width * 0.1,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Button(
                                            onTap: () async {
                                              setState(() {
                                                _addPayment = false;
                                                addMoney = null;
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                                addMoneyController.clear();
                                              });
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_cancel'],
                                            width: media.width * 0.4,
                                          ),
                                          Button(
                                            onTap: () async {
                                              // print(addMoney);
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              if (addMoney != 0 &&
                                                  addMoney != null) {
                                                setState(() {
                                                      _choosePayment = true;
                                                      _addPayment = false;
                                                    });
                                              }
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_addmoney'],
                                            width: media.width * 0.4,
                                          ),
                                        ],
                                      )
                                    ]),
                                  ),
                                ],
                              ),
                            ))
                        : Container(),

                        //choose payment method
                    (_choosePayment == true) ? Positioned(child: Container(
                          height: media.height*1,
                          width: media.width*1,
                          color: Colors.transparent.withOpacity(0.6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                      width: media.width * 0.8,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _choosePayment = false;
                                                _addPayment = true;
                                              });
                                            },
                                            child: Container(
                                              height: media.height * 0.05,
                                              width: media.height * 0.05,
                                              decoration: BoxDecoration(
                                                color: page,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.cancel,
                                                  color: buttonColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: media.width * 0.025),
                                    Container(
                                      padding: EdgeInsets.all(media.width*0.05),
                                      width: media.width*0.8,
                                      height: media.height*0.6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color:page
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            
                                                    width: media.width*0.7,
                                                    child: Text(languages[choosenLanguage]['text_choose_payment'],
                                                    style: GoogleFonts.roboto(
                                                      fontSize:media.width*eighteen,
                                                      fontWeight: FontWeight.w600
                                                    ),
                                                    )),
                                                    SizedBox(height: media.width*0.05,),
                                          Expanded(
                                            
                                            child: SingleChildScrollView(
                                              physics: const BouncingScrollPhysics(),
                                              child: Column(
                                                children: [
                                                  (walletBalance['stripe'] == true) ?
                                                    Container(
                                                      margin: EdgeInsets.only(bottom: media.width*0.025),
                                                      alignment: Alignment.center,
                                                    width: media.width*0.7,
                                                    child: InkWell(
                                                      onTap: ()async{
                                                        var val = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const SelectWallet()));
                                                if (val) {
                                                  setState(() {
                                                    _choosePayment = false;
                                                    _addPayment = false;
                                                    addMoney = null;
                                                    addMoneyController.clear();
                                                  });
                                                }
                                                      },
                                                      child: Container(
                                                        width: media.width*0.25,
                                                        height: media.width*0.125,
                                                        decoration:const BoxDecoration(
                                                          image: DecorationImage(image: AssetImage('assets/images/stripe-icon.png'),fit: BoxFit.contain)
                                                        ),
                                                      ),
                                                    )) : Container(),
                                                   (walletBalance['paystack'] == true) ?
                                                    Container(
                                                      alignment: Alignment.center,
                                                      margin: EdgeInsets.only(bottom: media.width*0.025),
                                                    width: media.width*0.7,
                                                    child: InkWell(
                                                       onTap: ()async{
                                                        var val = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const PayStackPage()));
                                                if (val) {
                                                  setState(() {
                                                    _choosePayment = false;
                                                    _addPayment = false;
                                                    addMoney = null;
                                                    addMoneyController.clear();
                                                  });
                                                }
                                                      },
                                                      child: Container(
                                                        width: media.width*0.25,
                                                        height: media.width*0.125,
                                                        decoration:const BoxDecoration(
                                                          image: DecorationImage(image: AssetImage('assets/images/paystack-icon.png'),fit: BoxFit.contain)
                                                        ),
                                                      ),
                                                    )) : Container(),
                                                    (walletBalance['flutter_wave'] == true) ?
                                                    Container(
                                                      margin: EdgeInsets.only(bottom: media.width*0.025),
                                                      alignment: Alignment.center,
                                                    width: media.width*0.7,
                                                    child: InkWell(
                                                       onTap: ()async{
                                                        var val = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const FlutterWavePage()));
                                                if (val) {
                                                  setState(() {
                                                    _choosePayment = false;
                                                    _addPayment = false;
                                                    addMoney = null;
                                                    addMoneyController.clear();
                                                  });
                                                }
                                                      },
                                                      child: Container(
                                                        width: media.width*0.25,
                                                        height: media.width*0.125,
                                                        decoration:const BoxDecoration(
                                                          image: DecorationImage(image: AssetImage('assets/images/flutterwave-icon.png'),fit: BoxFit.contain)
                                                        ),
                                                      ),
                                                    )) : Container(),
                                                    (walletBalance['razor_pay'] == true) ?
                                                    Container(
                                                      margin: EdgeInsets.only(bottom: media.width*0.025),
                                                      alignment: Alignment.center,
                                                    width: media.width*0.7,
                                                    child: InkWell(
                                                       onTap: ()async{
                                                        var val = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const RazorPayPage()));
                                                if (val) {
                                                  setState(() {
                                                    _choosePayment = false;
                                                    _addPayment = false;
                                                    addMoney = null;
                                                    addMoneyController.clear();
                                                  });
                                                }
                                                      },
                                                      child: Container(
                                                        width: media.width*0.25,
                                                        height: media.width*0.125,
                                                        decoration:const BoxDecoration(
                                                          image: DecorationImage(image: AssetImage('assets/images/razorpay-icon.jpeg'),fit: BoxFit.contain)
                                                        ),
                                                      ),
                                                    )) : Container(),
                                                    (walletBalance['cash_free'] == true) ?
                                                    Container(
                                                      margin: EdgeInsets.only(bottom: media.width*0.025),
                                                      alignment: Alignment.center,
                                                    width: media.width*0.7,
                                                    child: InkWell(
                                                       onTap: ()async{
                                                        var val = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const CashFreePage()));
                                                if (val) {
                                                  setState(() {
                                                    _choosePayment = false;
                                                    _addPayment = false;
                                                    addMoney = null;
                                                    addMoneyController.clear();
                                                  });
                                                }
                                                      },
                                                      child: Container(
                                                        width: media.width*0.25,
                                                        height: media.width*0.125,
                                                        decoration:const BoxDecoration(
                                                          image: DecorationImage(image: AssetImage('assets/images/cashfree-icon.jpeg'),fit: BoxFit.contain)
                                                        ),
                                                      ),
                                                    )) : Container(),
                                                    
                                                    
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                            ],
                          ),
                        )) : Container(),
                    //no internet
                    (internet == false)
                        ? Positioned(
                            top: 0,
                            child: NoInternet(
                              onTap: () {
                                setState(() {
                                  internetTrue();
                                  // _complete = false;
                                  _isLoading = true;
                                  getWallet();
                                });
                              },
                            ))
                        : Container(),

                    //loader
                    (_isLoading == true)
                        ? const Positioned(child: Loading())
                        : Container()
                  ],
                ),
              ),
            );
          }),
    );
  }
}
