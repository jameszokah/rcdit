import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/NavigatorPages/pickcontacts.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';

class Sos extends StatefulWidget {
  const Sos({Key? key}) : super(key: key);

  @override
  _SosState createState() => _SosState();
}

class _SosState extends State<Sos> {
  bool _isDeleting = false;
  bool _isLoading = false;
  String _deleteId = '';

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
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: media.width * 0.05, right: media.width * 0.05),
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    child: Column(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).padding.top +
                                media.width * 0.05),
                        Stack(
                          children: [
                            Container(
                              padding:
                                  EdgeInsets.only(bottom: media.width * 0.05),
                              width: media.width * 1,
                              alignment: Alignment.center,
                              child: Text(
                                languages[choosenLanguage]['text_sos'],
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * twenty,
                                    fontWeight: FontWeight.w600,
                                    color: textColor),
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
                        SizedBox(
                          height: media.height * 0.25,
                          child: Image.asset(
                            'assets/images/sosimage.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        Text(
                          languages[choosenLanguage]['text_trust_contact_3'],
                          style: GoogleFonts.roboto(
                              fontSize: media.width * fourteen,
                              fontWeight: FontWeight.w600,
                              color: textColor),
                        ),
                        Text(
                          languages[choosenLanguage]['text_trust_contact_4'],
                          style: GoogleFonts.roboto(
                              fontSize: media.width * twelve, color: textColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        Text(
                          languages[choosenLanguage]
                              ['text_yourTrustedContacts'],
                          style: GoogleFonts.roboto(
                              fontSize: media.width * fourteen,
                              fontWeight: FontWeight.w600,
                              color: buttonColor),
                        ),
                        SizedBox(
                          height: media.width * 0.025,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: media.width * 0.025,
                                ),
                                (sosData
                                        .where((element) =>
                                            element['user_type'] != 'admin')
                                        .isNotEmpty)
                                    ? Column(
                                        children: sosData
                                            .asMap()
                                            .map((i, value) {
                                              return MapEntry(
                                                  i,
                                                  (sosData[i]['user_type'] !=
                                                          'admin')
                                                      ? Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  media.width *
                                                                      0.025),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.7,
                                                                    child: Text(
                                                                      sosData[i]
                                                                          [
                                                                          'name'],
                                                                      style: GoogleFonts.roboto(
                                                                          fontSize: media.width *
                                                                              sixteen,
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          color:
                                                                              textColor),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.01,
                                                                  ),
                                                                  Text(
                                                                    sosData[i][
                                                                        'number'],
                                                                    style: GoogleFonts.roboto(
                                                                        fontSize:
                                                                            media.width *
                                                                                twelve,
                                                                        color:
                                                                            textColor),
                                                                  ),
                                                                ],
                                                              ),
                                                              InkWell(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      _deleteId =
                                                                          sosData[i]
                                                                              [
                                                                              'id'];
                                                                      _isDeleting =
                                                                          true;
                                                                    });
                                                                  },
                                                                  child: const Icon(
                                                                      Icons
                                                                          .remove_circle_outline))
                                                            ],
                                                          ),
                                                        )
                                                      : Container());
                                            })
                                            .values
                                            .toList(),
                                      )
                                    : Text(
                                        languages[choosenLanguage]
                                            ['text_noDataFound'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * eighteen,
                                            fontWeight: FontWeight.w600,
                                            color: textColor),
                                      )
                              ],
                            ),
                          ),
                        ),

                        //add sos button
                        (sosData
                                    .where((element) =>
                                        element['user_type'] != 'admin')
                                    .length <
                                5)
                            ? Container(
                                padding: EdgeInsets.only(
                                    top: media.width * 0.05,
                                    bottom: media.width * 0.05),
                                child: Button(
                                    onTap: () async {
                                      var nav = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const PickContact()));
                                      if (nav) {
                                        setState(() {});
                                      }
                                    },
                                    text: languages[choosenLanguage]
                                        ['text_add_trust_contact']))
                            : Container()
                      ],
                    ),
                  ),

                  //delete sos 
                  (_isDeleting == true)
                      ? Positioned(
                          top: 0,
                          child: Container(
                            height: media.height * 1,
                            width: media.width * 1,
                            color: Colors.transparent.withOpacity(0.6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: media.width * 0.9,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                          height: media.height * 0.1,
                                          width: media.width * 0.1,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: page),
                                          child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _isDeleting = false;
                                                });
                                              },
                                              child: const Icon(
                                                  Icons.cancel_outlined))),
                                    ],
                                  ),
                                ),
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
                                            ['text_removeSos'],
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
                                              _isLoading = true;
                                            });

                                            var val =
                                                await deleteSos(_deleteId);
                                            if (val == 'success') {
                                              setState(() {
                                                _isDeleting = false;
                                              });
                                            }
                                            setState(() {
                                              _isLoading = false;
                                            });
                                          },
                                          text: languages[choosenLanguage]
                                              ['text_confirm'])
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
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
