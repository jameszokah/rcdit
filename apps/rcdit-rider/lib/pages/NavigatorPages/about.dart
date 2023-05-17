import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';

class About extends StatefulWidget {
  const About({Key? key}) : super(key: key);

  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Container(
          padding: EdgeInsets.all(media.width * 0.05),
          height: media.height * 1,
          width: media.width * 1,
          color: page,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: media.width * 0.05),
                          width: media.width * 1,
                          alignment: Alignment.center,
                          child: Text(
                            languages[choosenLanguage]['text_about'],
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
                    SizedBox(
                      width: media.width * 0.9,
                      height: media.height * 0.16,
                      child: Image.asset(
                        'assets/images/aboutImage.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(
                      height: media.width * 0.1,
                    ),
                    //terms and condition
                    InkWell(
                      onTap: () {
                        openBrowser(
                            'terms and conditions url');
                      },
                      child: Text(
                        languages[choosenLanguage]['text_termsandconditions'],
                        style: GoogleFonts.roboto(
                            fontSize: media.width * sixteen,
                            fontWeight: FontWeight.w600,
                            color: textColor),
                      ),
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    //privacy policy
                    InkWell(
                      onTap: () {
                        openBrowser(
                            'privacy policy url');
                      },
                      child: Text(
                        languages[choosenLanguage]['text_privacy'],
                        style: GoogleFonts.roboto(
                            fontSize: media.width * sixteen,
                            fontWeight: FontWeight.w600,
                            color: textColor),
                      ),
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    //website
                    InkWell(
                      onTap: () {
                        openBrowser('website url');
                      },
                      child: Text(
                        languages[choosenLanguage]['text_about'],
                        style: GoogleFonts.roboto(
                            fontSize: media.width * sixteen,
                            fontWeight: FontWeight.w600,
                            color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
