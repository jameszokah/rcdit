import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/onTripPage/map_page.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';

class Referral extends StatefulWidget {
  const Referral({Key? key}) : super(key: key);

  @override
  _ReferralState createState() => _ReferralState();
}

dynamic referralCode;

class _ReferralState extends State<Referral> {
  bool _loading = false;
  String _error = '';
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    referralCode = '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(
                left: media.width * 0.08, right: media.width * 0.08),
            height: media.height * 1,
            width: media.width * 1,
            color: page,
            child: Column(
              children: [
                Container(
                  alignment: Alignment.bottomLeft,
                  height: media.height * 0.12,
                  width: media.width * 1,
                  color: topBar,
                ),
                SizedBox(
                  height: media.height * 0.04,
                ),
                SizedBox(
                    width: media.width * 1,
                    child: Text(
                      languages[choosenLanguage]['text_apply_referral'],
                      style: GoogleFonts.roboto(
                          fontSize: media.width * twenty,
                          color: textColor,
                          fontWeight: FontWeight.bold),
                    )),
                const SizedBox(height: 10),
                InputField(
                  text: languages[choosenLanguage]['text_enter_referral'],
                  textController: controller,
                  onTap: (val) {
                    setState(() {
                      referralCode = controller.text;
                    });
                  },
                  color: (_error == '') ? null : Colors.red,
                ),
                (_error != '')
                    ? Container(
                        margin: EdgeInsets.only(top: media.height * 0.02),
                        child: Text(
                          _error,
                          style: GoogleFonts.roboto(
                              fontSize: media.width * sixteen,
                              color: Colors.red),
                        ),
                      )
                    : Container(),
                const SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //skip
                    Button(
                        onTap: () {
                          registerUser();
                          FocusManager.instance.primaryFocus?.unfocus();
                          _error = '';

                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Maps()));
                        },
                        text: languages[choosenLanguage]['text_skip']),
                    //apply code
                    Button(
                      onTap: () async {
                        if (controller.text.isNotEmpty) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          await registerUser();
                          setState(() {
                            _error = '';
                            _loading = true;
                          });
                          var result = await updateReferral();
                          if (result == 'true') {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Maps()));
                          } else {
                            setState(() {
                              _error = 'please enter valid referral code';
                            });
                          }
                          setState(() {
                            _loading = false;
                          });
                        } else {}
                      },
                      text: languages[choosenLanguage]['text_apply'],
                      color: (controller.text.isNotEmpty)
                          ? buttonColor
                          : Colors.grey,
                    )
                  ],
                )
              ],
            ),
          ),
          //loader
          (_loading == true)
              ? const Positioned(top: 0, child: Loading())
              : Container()
        ],
      ),
    );
  }
}
