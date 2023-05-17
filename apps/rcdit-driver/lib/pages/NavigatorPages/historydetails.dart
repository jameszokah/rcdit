import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/NavigatorPages/history.dart';
import 'package:rcdit_user/pages/NavigatorPages/makecomplaint.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';

class HistoryDetails extends StatefulWidget {
  const HistoryDetails({Key? key}) : super(key: key);

  @override
  _HistoryDetailsState createState() => _HistoryDetailsState();
}

class _HistoryDetailsState extends State<HistoryDetails> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Container(
          padding: EdgeInsets.fromLTRB(
              media.width * 0.05,
              MediaQuery.of(context).padding.top + media.width * 0.05,
              media.width * 0.05,
              0),
          height: media.height * 1,
          width: media.width * 1,
          color: page,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(bottom: media.width * 0.05),
                    width: media.width * 0.9,
                    alignment: Alignment.center,
                    child: Text(
                      languages[choosenLanguage]['text_tripsummary'],
                      style: GoogleFonts.roboto(
                          fontSize: media.width * sixteen,
                          fontWeight: FontWeight.bold),
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),

                  //history details
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: media.height * 0.04,
                      ),
                      Container(
                        width: media.width * 0.9,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          languages[choosenLanguage]['text_location'],
                          style: GoogleFonts.roboto(
                              fontSize: media.width * sixteen,
                              color: textColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Container(
                        padding: EdgeInsets.all(media.width * 0.034),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  height: media.width * 0.025,
                                  width: media.width * 0.025,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xff319900)
                                          .withOpacity(0.3)),
                                  child: Container(
                                    height: media.width * 0.01,
                                    width: media.width * 0.01,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xff319900)),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      height: media.width * 0.01,
                                      width: media.width * 0.001,
                                      color: const Color(0xff319900),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.002,
                                    ),
                                    Container(
                                      height: media.width * 0.01,
                                      width: media.width * 0.001,
                                      color: const Color(0xff319900),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.002,
                                    ),
                                    Container(
                                      height: media.width * 0.01,
                                      width: media.width * 0.001,
                                      color: const Color(0xff319900),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.002,
                                    ),
                                    Container(
                                      height: media.width * 0.01,
                                      width: media.width * 0.001,
                                      color: const Color(0xff319900),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: media.width * 0.025,
                                  width: media.width * 0.025,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xffFF0000)
                                          .withOpacity(0.3)),
                                  child: Container(
                                    height: media.width * 0.01,
                                    width: media.width * 0.01,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xffFF0000)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: media.width * 0.03,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: media.width * 0.75,
                                  child: Text(
                                    myHistory[selectedHistory]['pick_address'],
                                    style: GoogleFonts.roboto(
                                        fontSize: media.width * twelve,
                                        color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  height: 1,
                                  width: media.width * 0.75,
                                  color: borderLines,
                                ),
                                SizedBox(
                                  width: media.width * 0.75,
                                  child: Text(
                                    myHistory[selectedHistory]['drop_address'],
                                    style: GoogleFonts.roboto(
                                        fontSize: media.width * twelve,
                                        color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: media.width * 0.04,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                height: media.width * 0.05,
                                width: media.width * 0.05,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: buttonColor),
                                child: Icon(
                                  Icons.done,
                                  size: media.width * 0.04,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: media.width * 0.16,
                                child: Text(
                                  languages[choosenLanguage]['text_assigned'],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor.withOpacity(0.4)),
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: media.width * 0.16,
                                child: Text(
                                  myHistory[selectedHistory]['accepted_at']
                                          .toString()
                                          .split(' ')
                                          .toList()[2] +
                                      ' ' +
                                      myHistory[selectedHistory]['accepted_at']
                                          .toString()
                                          .split(' ')
                                          .toList()[3],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor.withOpacity(0.4)),
                                ),
                              )
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(top: media.width * 0.025),
                            height: 1,
                            width: media.width * 0.15,
                            color: buttonColor,
                          ),
                          Column(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                height: media.width * 0.05,
                                width: media.width * 0.05,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: buttonColor),
                                child: Icon(
                                  Icons.done,
                                  size: media.width * 0.04,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: media.width * 0.16,
                                child: Text(
                                  languages[choosenLanguage]['text_started'],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor.withOpacity(0.4)),
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: media.width * 0.16,
                                child: Text(
                                  myHistory[selectedHistory]['trip_start_time']
                                          .toString()
                                          .split(' ')
                                          .toList()[2] +
                                      ' ' +
                                      myHistory[selectedHistory]
                                              ['trip_start_time']
                                          .toString()
                                          .split(' ')
                                          .toList()[3],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor.withOpacity(0.4)),
                                ),
                              )
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(top: media.width * 0.025),
                            height: 1,
                            width: media.width * 0.15,
                            color: buttonColor,
                          ),
                          Column(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                height: media.width * 0.05,
                                width: media.width * 0.05,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: buttonColor),
                                child: Icon(
                                  Icons.done,
                                  size: media.width * 0.04,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: media.width * 0.16,
                                child: Text(
                                  languages[choosenLanguage]['text_completed'],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor.withOpacity(0.4)),
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: media.width * 0.16,
                                child: Text(
                                  myHistory[selectedHistory]['completed_at']
                                          .toString()
                                          .split(' ')
                                          .toList()[2] +
                                      ' ' +
                                      myHistory[selectedHistory]['completed_at']
                                          .toString()
                                          .split(' ')
                                          .toList()[3],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor.withOpacity(0.4)),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.width * 0.04,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: media.width * 0.13,
                            width: media.width * 0.13,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                    image: NetworkImage(
                                        myHistory[selectedHistory]
                                                ['driverDetail']['data']
                                            ['profile_picture']),
                                    fit: BoxFit.cover)),
                          ),
                          SizedBox(
                            width: media.width * 0.05,
                          ),
                          Text(
                            myHistory[selectedHistory]['driverDetail']['data']
                                ['name'],
                            style: GoogleFonts.roboto(
                              fontSize: media.width * eighteen,
                            ),
                          ),
                          Expanded(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                myHistory[selectedHistory]['ride_user_rating']
                                    .toString(),
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * eighteen,
                                    fontWeight: FontWeight.w600),
                              ),
                              Icon(
                                Icons.star,
                                size: media.width * twenty,
                                color: buttonColor,
                              )
                            ],
                          ))
                        ],
                      ),
                      SizedBox(
                        height: media.height * 0.05,
                      ),
                      SizedBox(
                        width: media.width * 0.72,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_reference'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * twelve,
                                          color: const Color(0xff898989)),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                    Text(
                                      myHistory[selectedHistory]
                                          ['request_number'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * fourteen,
                                          color: textColor),
                                    )
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_rideType'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * twelve,
                                          color: const Color(0xff898989)),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                    Text(
                                      (myHistory[selectedHistory]
                                                  ['is_rental'] ==
                                              false)
                                          ? 'Regular'
                                          : 'Rental',
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * fourteen,
                                          color: textColor),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height: media.height * 0.02,
                            ),
                            Container(
                              height: 2,
                              color: const Color(0xffAAAAAA),
                            ),
                            SizedBox(
                              height: media.height * 0.02,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_distance'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * twelve,
                                          color: const Color(0xff898989)),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                    Text(
                                      myHistory[selectedHistory]
                                              ['total_distance'] +
                                          ' ' +
                                          myHistory[selectedHistory]['unit'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * fourteen,
                                          color: textColor),
                                    )
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_duration'],
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * twelve,
                                          color: const Color(0xff898989)),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                    Text(
                                      myHistory[selectedHistory]['total_time']
                                              .toString() +
                                          ' mins',
                                      style: GoogleFonts.roboto(
                                          fontSize: media.width * fourteen,
                                          color: textColor),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: media.height * 0.05,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info),
                          SizedBox(
                            width: media.width * 0.04,
                          ),
                          Text(
                            languages[choosenLanguage]['text_tripfare'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * fourteen,
                                color: textColor),
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.height * 0.05,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_baseprice'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                          Text(
                            myHistory[selectedHistory]['requestBill']['data']
                                    ['requested_currency_code'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['base_price']
                                    .toString(),
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_distprice'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                          Text(
                            myHistory[selectedHistory]['requestBill']['data']
                                    ['requested_currency_code'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['distance_price']
                                    .toString(),
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_timeprice'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                          Text(
                            myHistory[selectedHistory]['requestBill']['data']
                                    ['requested_currency_code'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['time_price']
                                    .toString(),
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                        ],
                      ),
                      (myHistory[selectedHistory]['requestBill']['data']
                                  ['cancellation_fee'] !=
                              0)
                          ? SizedBox(
                              height: media.height * 0.02,
                            )
                          : Container(),
                      (myHistory[selectedHistory]['requestBill']['data']
                                  ['cancellation_fee'] !=
                              0)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  languages[choosenLanguage]['text_cancelfee'],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor),
                                ),
                                Text(
                                  myHistory[selectedHistory]['requestBill']
                                          ['data']['requested_currency_code'] +
                                      ' ' +
                                      myHistory[selectedHistory]['requestBill']
                                              ['data']['cancellation_fee']
                                          .toString(),
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor),
                                ),
                              ],
                            )
                          : Container(),
                      (myHistory[selectedHistory]['requestBill']['data']
                                  ['airport_surge_fee'] !=
                              0)
                          ? SizedBox(
                              height: media.height * 0.02,
                            )
                          : Container(),
                      (myHistory[selectedHistory]['requestBill']['data']
                                  ['airport_surge_fee'] !=
                              0)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  languages[choosenLanguage]['text_surge_fee'],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor),
                                ),
                                Text(
                                  myHistory[selectedHistory]['requestBill']
                                          ['data']['requested_currency_code'] +
                                      ' ' +
                                      myHistory[selectedHistory]['requestBill']
                                              ['data']['airport_surge_fee']
                                          .toString(),
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: textColor),
                                ),
                              ],
                            )
                          : Container(),
                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_waiting_time_1'] +
                                ' (' +
                                myHistory[selectedHistory]['requestBill']
                                    ['data']['requested_currency_symbol'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['waiting_charge_per_min']
                                    .toString() +
                                ' x ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['calculated_waiting_time']
                                    .toString() +
                                ' mins' +
                                ')',
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                          Text(
                            myHistory[selectedHistory]['requestBill']['data']
                                    ['requested_currency_symbol'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['waiting_charge']
                                    .toString(),
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_convfee'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                          Text(
                            myHistory[selectedHistory]['requestBill']['data']
                                    ['requested_currency_code'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['admin_commision']
                                    .toString(),
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                        ],
                      ),
                      (myHistory[selectedHistory]['requestBill']['data']
                                  ['promo_discount'] !=
                              null)
                          ? SizedBox(
                              height: media.height * 0.02,
                            )
                          : Container(),
                      (myHistory[selectedHistory]['requestBill']['data']
                                  ['promo_discount'] !=
                              null)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  languages[choosenLanguage]['text_discount'],
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: Colors.red),
                                ),
                                Text(
                                  myHistory[selectedHistory]['requestBill']
                                              ['data']
                                          ['requested_currency_symbol'] +
                                      ' ' +
                                      myHistory[selectedHistory]['requestBill']
                                              ['data']['promo_discount']
                                          .toString(),
                                  style: GoogleFonts.roboto(
                                      fontSize: media.width * twelve,
                                      color: Colors.red),
                                ),
                              ],
                            )
                          : Container(),
                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_taxes'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                          Text(
                            myHistory[selectedHistory]['requestBill']['data']
                                    ['requested_currency_code'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['service_tax']
                                    .toString(),
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Container(
                        height: 1.5,
                        color: const Color(0xffE0E0E0),
                      ),
                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_totalfare'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                          Text(
                            myHistory[selectedHistory]['requestBill']['data']
                                    ['requested_currency_code'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['total_amount']
                                    .toString(),
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twelve,
                                color: textColor),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: media.height * 0.02,
                      ),
                      Container(
                        height: 1.5,
                        color: const Color(0xffE0E0E0),
                      ),
                      // SizedBox(height: media.height*0.02,),
                      SizedBox(
                        height: media.height * 0.05,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (myHistory[selectedHistory]['payment_opt'] == '1')
                                ? languages[choosenLanguage]['text_cash']
                                : (myHistory[selectedHistory]['payment_opt'] ==
                                        '2')
                                    ? languages[choosenLanguage]['text_wallet']
                                    : '',
                            style: GoogleFonts.roboto(
                                fontSize: media.width * sixteen,
                                color: buttonColor),
                          ),
                          Text(
                            myHistory[selectedHistory]['requestBill']['data']
                                    ['requested_currency_symbol'] +
                                ' ' +
                                myHistory[selectedHistory]['requestBill']
                                        ['data']['total_amount']
                                    .toString(),
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twentysix,
                                color: textColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              //make complaint button
              Container(
                padding: EdgeInsets.all(media.width * 0.05),
                child: Button(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MakeComplaint(fromPage: 1)));
                    },
                    text: languages[choosenLanguage]['text_make_complaints']),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
