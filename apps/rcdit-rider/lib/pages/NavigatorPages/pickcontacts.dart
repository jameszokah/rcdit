import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'package:rcdit_user/widgets/widgets.dart';

class PickContact extends StatefulWidget {
  const PickContact({Key? key}) : super(key: key);

  @override
  _PickContactState createState() => _PickContactState();
}

class _PickContactState extends State<PickContact> {
  bool _isLoading = false;
  String pickedName = '';
  String pickedNumber = '';
  bool _contactDenied = false;

  List contacts = [];
  @override
  void initState() {
    getContact();
    super.initState();
  }

//get permission
  getContactPermission() async {
    var status = await Permission.contacts.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.contacts.request();
    }
    return status;
  }

//fetch contacts
  getContact() async {
    var permission = await getContactPermission();
    if (permission == PermissionStatus.granted) {
      setState(() {
        _isLoading = true;
      });
      Iterable<Contact> contactsList = await ContactsService.getContacts();

      setState(() {
        // ignore: avoid_function_literals_in_foreach_calls
        contactsList.forEach((contact) {
          contact.phones!.toSet().forEach((phone) {
            contacts.add({
              'name': contact.displayName ?? contact.givenName,
              'phone': phone.value
            });
          });
          
        });
        _isLoading = false;
      });
    } else {
      setState(() {
        _contactDenied = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Stack(
          children: [
            Container(
              height: media.height * 1,
              width: media.width * 1,
              color: page,
              padding: EdgeInsets.only(
                  left: media.width * 0.05, right: media.width * 0.05),
              child: Column(children: [
                SizedBox(
                    height: MediaQuery.of(context).padding.top +
                        media.width * 0.05),
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.only(bottom: media.width * 0.05),
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
                              Navigator.pop(context);
                            },
                            child: const Icon(Icons.arrow_back)))
                  ],
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: contacts
                          .asMap()
                          .map((i, value) {
                            return MapEntry(
                                i,
                                (sosData
                                        .map((e) => e['number'])
                                        .toString()
                                        .replaceAll(' ', '')
                                        .contains(contacts[i]['phone']
                                            .toString()
                                            .replaceAll(' ', '')))
                                    ? Container()
                                    : Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.025),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              pickedName = contacts[i]['name'];
                                              pickedNumber =
                                                  contacts[i]['phone'];
                                            });
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: media.width * 0.7,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      contacts[i]['name'],
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  fourteen,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: textColor),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.01,
                                                    ),
                                                    Text(
                                                      contacts[i]['phone'],
                                                      style: GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  twelve,
                                                          color: textColor),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                height: media.width * 0.05,
                                                width: media.width * 0.05,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xff222222),
                                                        width: 1.2)),
                                                alignment: Alignment.center,
                                                child: (pickedName ==
                                                        contacts[i]['name'])
                                                    ? Container(
                                                        height:
                                                            media.width * 0.03,
                                                        width:
                                                            media.width * 0.03,
                                                        decoration:
                                                            const BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Color(
                                                                    0xff222222)),
                                                      )
                                                    : Container(),
                                              )
                                            ],
                                          ),
                                        ),
                                      ));
                          })
                          .values
                          .toList(),
                    ),
                  ),
                ),
                (pickedName != '')
                    ? Container(
                        padding: EdgeInsets.only(
                            top: media.width * 0.05,
                            bottom: media.width * 0.05),
                        child: Button(
                            onTap: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              var val = await addSos(pickedName, pickedNumber);
                              if (val == 'success') {
                                Navigator.pop(context, true);
                              }
                              setState(() {
                                _isLoading = false;
                              });
                            },
                            text: languages[choosenLanguage]['text_confirm']),
                      )
                    : Container()
              ]),
            ),

            //permission denied popup
            (_contactDenied == true)
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
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _contactDenied = false;
                                  });
                                  Navigator.pop(context, false);
                                },
                                child: Container(
                                  height: media.width * 0.1,
                                  width: media.width * 0.1,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: page),
                                  child: const Icon(Icons.cancel_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        Container(
                          padding: EdgeInsets.all(media.width * 0.05),
                          width: media.width * 0.9,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: page,
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 2.0,
                                    spreadRadius: 2.0,
                                    color: Colors.black.withOpacity(0.2))
                              ]),
                          child: Column(
                            children: [
                              SizedBox(
                                  width: media.width * 0.8,
                                  child: Text(
                                    languages[choosenLanguage]
                                        ['text_open_contact_setting'],
                                    style: GoogleFonts.roboto(
                                        fontSize: media.width * sixteen,
                                        color: textColor,
                                        fontWeight: FontWeight.w600),
                                  )),
                              SizedBox(height: media.width * 0.05),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                      onTap: () async {
                                        await openAppSettings();
                                      },
                                      child: Text(
                                        languages[choosenLanguage]
                                            ['text_open_settings'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * sixteen,
                                            color: buttonColor,
                                            fontWeight: FontWeight.w600),
                                      )),
                                  InkWell(
                                      onTap: () async {
                                        setState(() {
                                          _contactDenied = false;
                                        });
                                        getContact();
                                      },
                                      child: Text(
                                        languages[choosenLanguage]['text_done'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * sixteen,
                                            color: buttonColor,
                                            fontWeight: FontWeight.w600),
                                      ))
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ))
                : Container(),
            //loader
            (_isLoading == true)
                ? const Positioned(top: 0, child: Loading())
                : Container(),

            //no internet
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(
                      onTap: () {
                        internetTrue();
                      },
                    ))
                : Container()
          ],
        ),
      ),
    );
  }
}
