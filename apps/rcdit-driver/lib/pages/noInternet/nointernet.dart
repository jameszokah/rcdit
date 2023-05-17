import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';

// ignore: must_be_immutable
class NoInternet extends StatefulWidget {
  dynamic onTap;
  // ignore: use_key_in_widget_constructors
  NoInternet({required this.onTap});

  @override
  _NoInternetState createState() => _NoInternetState();
}

class _NoInternetState extends State<NoInternet> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Container(
      height: media.height * 1,
      width: media.width * 1,
      color: Colors.transparent.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //no internet popup
          Container(
            padding: EdgeInsets.all(media.width * 0.05),
            width: media.width * 0.8,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), color: page),
            child: Column(
              children: [
                SizedBox(
                  width: media.width * 0.6,
                  child: Image.asset(
                    'assets/images/noInternet.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Text(
                  (languages.isNotEmpty && choosenLanguage != '')
                      ? languages[choosenLanguage]['text_nointernet']
                      : 'No Internet Connection',
                  style: GoogleFonts.roboto(
                      fontSize: media.width * eighteen,
                      fontWeight: FontWeight.w600,
                      color: textColor),
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Text(
                  (languages.isNotEmpty && choosenLanguage != '')
                      ? languages[choosenLanguage]['text_nointernetdesc']
                      : 'Please check your Internet connection, try enabling wifi or tey again later',
                  style: GoogleFonts.roboto(
                      fontSize: media.width * fourteen, color: hintColor),
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Button(
                    onTap: widget.onTap,
                    text: (languages.isNotEmpty && choosenLanguage != '')
                        ? languages[choosenLanguage]['text_ok']
                        : 'Ok')
              ],
            ),
          )
        ],
      ),
    );
  }
}
