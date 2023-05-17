import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/pages/noInternet/nointernet.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rcdit_user/translations/translation.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:rcdit_user/widgets/widgets.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

dynamic imageFile;

class _EditProfileState extends State<EditProfile> {
  ImagePicker picker = ImagePicker();
  bool _isLoading = false;
  bool _error = false;
  String _permission = '';
  bool _pickImage = false;
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();

//gallery permission
  getGalleryPermission() async {
    var status = await Permission.photos.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.photos.request();
    }
    return status;
  }

//camera permission
  getCameraPermission() async {
    var status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.camera.request();
    }
    return status;
  }

//pick image from gallery
  pickImageFromGallery() async {
    var permission = await getGalleryPermission();
    if (permission == PermissionStatus.granted) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        imageFile = pickedFile?.path;
        _pickImage = false;
      });
    } else {
      setState(() {
        _permission = 'noPhotos';
      });
    }
  }

//pick image from camera
  pickImageFromCamera() async {
    var permission = await getCameraPermission();
    if (permission == PermissionStatus.granted) {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      setState(() {
        imageFile = pickedFile?.path;
        _pickImage = false;
      });
    } else {
      setState(() {
        _permission = 'noCamera';
      });
    }
  }

  @override
  void initState() {
    imageFile = null;
    name.text = userDetails['name'];
    email.text = userDetails['email'];
    super.initState();
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
              padding: EdgeInsets.all(media.width * 0.05),
              height: media.height * 1,
              width: media.width * 1,
              color: page,
              child: Column(
                children: [
                  Expanded(
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
                                languages[choosenLanguage]['text_editprofile'],
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
                        SizedBox(height: media.width * 0.1),
                        Container(
                          height: media.width * 0.4,
                          width: media.width * 0.4,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: page,
                              image: (imageFile == null)
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        userDetails['profile_picture'],
                                      ),
                                      fit: BoxFit.cover)
                                  : DecorationImage(
                                      image: FileImage(File(imageFile)),
                                      fit: BoxFit.cover)),
                        ),
                        SizedBox(
                          height: media.width * 0.04,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _pickImage = true;
                            });
                          },
                          child: Text(
                              languages[choosenLanguage]['text_editimage'],
                              style: GoogleFonts.roboto(
                                  fontSize: media.width * sixteen,
                                  color: buttonColor)),
                        ),
                        SizedBox(
                          height: media.width * 0.1,
                        ),
                        SizedBox(
                          width: media.width * 0.8,
                          child: TextField(
                            textDirection: (choosenLanguage == 'iw' ||
                                    choosenLanguage == 'ur' ||
                                    choosenLanguage == 'ar')
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            controller: name,
                            decoration: InputDecoration(
                                labelText: languages[choosenLanguage]
                                    ['text_name'],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    gapPadding: 1),
                                isDense: true),
                          ),
                        ),
                        SizedBox(
                          height: media.width * 0.1,
                        ),
                        SizedBox(
                          width: media.width * 0.8,
                          child: TextField(
                            controller: email,
                            textDirection: (choosenLanguage == 'iw' ||
                                    choosenLanguage == 'ur' ||
                                    choosenLanguage == 'ar')
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            decoration: InputDecoration(
                                labelText: languages[choosenLanguage]
                                    ['text_email'],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    gapPadding: 1),
                                isDense: true),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                      width: media.width * 0.8,
                      child: Button(
                          onTap: () async {
                            setState(() {
                              _isLoading = true;
                            });
                            dynamic val;

                            if (imageFile == null) {
                              //update name or email
                              val = await updateProfileWithoutImage(
                                  name.text, email.text);
                            } else {
                              //update image
                              val = await updateProfile(name.text, email.text);
                            }
                            if (val == 'success') {
                              Navigator.pop(context, true);
                            } else {
                              setState(() {
                                _error = true;
                              });
                            }
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          text: languages[choosenLanguage]['text_confirm']))
                ],
              ),
            ),

            //pick image bar
            (_pickImage == true)
                ? Positioned(
                    bottom: 0,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _pickImage = false;
                        });
                      },
                      child: Container(
                        height: media.height * 1,
                        width: media.width * 1,
                        color: Colors.transparent.withOpacity(0.6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.all(media.width * 0.05),
                              width: media.width * 1,
                              decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25)),
                                  border: Border.all(
                                    color: borderLines,
                                    width: 1.2,
                                  ),
                                  color: page),
                              child: Column(
                                children: [
                                  Container(
                                    height: media.width * 0.02,
                                    width: media.width * 0.15,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          media.width * 0.01),
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              pickImageFromCamera();
                                            },
                                            child: Container(
                                                height: media.width * 0.171,
                                                width: media.width * 0.171,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: borderLines,
                                                        width: 1.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                child: Icon(
                                                  Icons.camera_alt_outlined,
                                                  size: media.width * 0.064,
                                                )),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.01,
                                          ),
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_camera'],
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * ten,
                                                color: const Color(0xff666666)),
                                          )
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              pickImageFromGallery();
                                            },
                                            child: Container(
                                                height: media.width * 0.171,
                                                width: media.width * 0.171,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: borderLines,
                                                        width: 1.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  size: media.width * 0.064,
                                                )),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.01,
                                          ),
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_gallery'],
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * ten,
                                                color: const Color(0xff666666)),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                : Container(),

                //popup for denied permission
            (_permission != '')
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
                                    _permission = '';
                                    _pickImage = false;
                                  });
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
                                    (_permission == 'noPhotos')
                                        ? languages[choosenLanguage]
                                            ['text_open_photos_setting']
                                        : languages[choosenLanguage]
                                            ['text_open_camera_setting'],
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
                                        (_permission == 'noCamera')
                                            ? pickImageFromCamera()
                                            : pickImageFromGallery();
                                        setState(() {
                                          _permission = '';
                                        });
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
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(
                      onTap: () {
                        setState(() {
                          internetTrue();
                        });
                      },
                    ))
                : Container(),

                //loader
            (_isLoading == true)
                ? const Positioned(top: 0, child: Loading())
                : Container(),

                //error
            (_error == true)
                ? Positioned(
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
                                      _error = false;
                                    });
                                  },
                                  text: languages[choosenLanguage]['text_ok'])
                            ],
                          ),
                        )
                      ],
                    ),
                  ))
                : Container(),
          ],
        ),
      ),
    );
  }
}
