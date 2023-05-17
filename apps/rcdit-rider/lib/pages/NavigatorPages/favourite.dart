import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';

class Favorite extends StatefulWidget {
  const Favorite({Key? key}) : super(key: key);

  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  bool _isLoading = false;
  bool _deletingAddress = false;
  dynamic _deletingId;
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
                                languages[choosenLanguage]['text_favourites'],
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
                            'assets/images/favpage.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(
                          height: media.width * 0.1,
                        ),
                        (favAddress.isNotEmpty)
                            ? Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: favAddress
                                        .asMap()
                                        .map((i, value) {
                                          return MapEntry(
                                            i,
                                            Container(
                                              width: media.width * 0.9,
                                              padding: EdgeInsets.only(
                                                  top: media.width * 0.03,
                                                  bottom: media.width * 0.03),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    favAddress[i]
                                                        ['address_name'],
                                                    style: GoogleFonts.roboto(
                                                        fontSize: media.width *
                                                            sixteen,
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.03,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      (favAddress[i][
                                                                  'address_name'] ==
                                                              'Home')
                                                          ? Image.asset(
                                                              'assets/images/home.png',
                                                              color:
                                                                  Colors.black,
                                                              width:
                                                                  media.width *
                                                                      0.075,
                                                            )
                                                          : (favAddress[i][
                                                                      'address_name'] ==
                                                                  'Work')
                                                              ? Image.asset(
                                                                  'assets/images/briefcase.png',
                                                                  color: Colors
                                                                      .black,
                                                                  width: media
                                                                          .width *
                                                                      0.075,
                                                                )
                                                              : Image.asset(
                                                                  'assets/images/navigation.png',
                                                                  color: Colors
                                                                      .black,
                                                                  width: media
                                                                          .width *
                                                                      0.075,
                                                                ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.02,
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.6,
                                                        child: Text(
                                                          favAddress[i]
                                                              ['pick_address'],
                                                          style: GoogleFonts
                                                              .roboto(
                                                            fontSize:
                                                                media.width *
                                                                    twelve,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                          child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          InkWell(
                                                              onTap: () async {
                                                                setState(() {
                                                                  _deletingId =
                                                                      favAddress[
                                                                              i]
                                                                          [
                                                                          'id'];
                                                                  _deletingAddress =
                                                                      true;
                                                                });
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .remove_circle_outline)),
                                                        ],
                                                      ))
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        })
                                        .values
                                        .toList(),
                                  ),
                                ),
                              )
                            : Text(
                                languages[choosenLanguage]['text_noDataFound'],
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * eighteen,
                                    fontWeight: FontWeight.w600,
                                    color: textColor),
                              )
                      ],
                    ),
                  ),

                  //popup for delete address
                  (_deletingAddress == true)
                      ? Positioned(
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
                                                _deletingAddress = false;
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
                                          ['text_removeFav'],
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
                                          var result = await removeFavAddress(
                                              _deletingId);
                                          if (result == 'success') {
                                            setState(() {
                                              _deletingAddress = false;
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
                        ))
                      : Container(),

                  //no internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(onTap: () {
                            setState(() {
                              internetTrue();
                            });
                          }))
                      : Container(),

                  //loader
                  (_isLoading == true)
                      ? const Positioned(child: Loading())
                      : Container()
                ],
              ),
            );
          }),
    );
  }
}
