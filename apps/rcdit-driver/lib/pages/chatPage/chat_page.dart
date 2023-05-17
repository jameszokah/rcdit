import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rcdit_user/functions/functions.dart';
import 'package:rcdit_user/pages/loadingPage/loading.dart';
import 'package:rcdit_user/styles/styles.dart';
import 'package:rcdit_user/translations/translation.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController chatText = TextEditingController();
  ScrollController controller = ScrollController();
  bool _sendingMessage = false;
  @override
  void initState() {
    //get messages
    getCurrentMessages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return true;
      },
      child: Material(
        child: Scaffold(
          body: ValueListenableBuilder(
              valueListenable: valueNotifierBook.value,
              builder: (context, value, child) {
                WidgetsBinding.instance?.addPostFrameCallback((_) {
                  controller.animateTo(controller.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease);
                });
                //call for message seen
                messageSeen();

                return Directionality(
                  textDirection: (languageDirection == 'rtl')
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            media.width * 0.05,
                            MediaQuery.of(context).padding.top +
                                media.width * 0.05,
                            media.width * 0.05,
                            media.width * 0.05),
                        height: media.height * 1,
                        width: media.width * 1,
                        color: page,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: media.width * 0.9,
                                  height: media.width * 0.1,
                                  alignment: Alignment.center,
                                  child: Text(
                                    languages[choosenLanguage]
                                        ['text_chatwithdriver'],
                                    style: GoogleFonts.roboto(
                                        fontSize: media.width * twenty,
                                        color: textColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Positioned(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: Container(
                                      height: media.width * 0.1,
                                      width: media.width * 0.1,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                spreadRadius: 2,
                                                blurRadius: 2)
                                          ],
                                          color: page),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.arrow_back),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            Expanded(
                                child: SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                children: chatList
                                    .asMap()
                                    .map((i, value) {
                                      return MapEntry(
                                          i,
                                          Container(
                                            padding: EdgeInsets.only(
                                                top: media.width * 0.025),
                                            width: media.width * 0.9,
                                            alignment:
                                                (chatList[i]['from_type'] == 1)
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                            child: Column(
                                              crossAxisAlignment: (chatList[i]
                                                          ['from_type'] ==
                                                      1)
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: media.width * 0.4,
                                                  padding: EdgeInsets.fromLTRB(
                                                      media.width * 0.04,
                                                      media.width * 0.02,
                                                      media.width * 0.04,
                                                      media.width * 0.02),
                                                  decoration: BoxDecoration(
                                                      borderRadius: (chatList[i]['from_type'] == 1)
                                                          ? const BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                      24),
                                                              bottomLeft:
                                                                  Radius.circular(
                                                                      24),
                                                              bottomRight:
                                                                  Radius.circular(
                                                                      24))
                                                          : const BorderRadius.only(
                                                              topRight:
                                                                  Radius.circular(
                                                                      24),
                                                              bottomLeft:
                                                                  Radius.circular(
                                                                      24),
                                                              bottomRight:
                                                                  Radius.circular(24)),
                                                      color: (chatList[i]['from_type'] == 1) ? const Color(0xff000000).withOpacity(0.15) : const Color(0xff222222)),
                                                  child: Text(
                                                    chatList[i]['message'],
                                                    style: GoogleFonts.roboto(
                                                        fontSize: media.width *
                                                            fourteen,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.015,
                                                ),
                                                Text(chatList[i]
                                                    ['converted_created_at'])
                                              ],
                                            ),
                                          ));
                                    })
                                    .values
                                    .toList(),
                              ),
                            )),

                            //text field
                            Container(
                              margin: EdgeInsets.only(top: media.width * 0.025),
                              padding: EdgeInsets.fromLTRB(
                                  media.width * 0.025,
                                  media.width * 0.01,
                                  media.width * 0.025,
                                  media.width * 0.01),
                              
                              width: media.width * 0.9,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: borderLines, width: 1.2),
                                  color: page),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: media.width * 0.7,
                                    child: TextField(
                                      controller: chatText,
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: languages[choosenLanguage]
                                              ['text_entermessage'],
                                          hintStyle: GoogleFonts.roboto(
                                              fontSize: media.width * twelve,
                                              color: hintColor)),
                                      minLines: 1,
                                      maxLines: 4,
                                      onChanged: (val) {},
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      setState(() {
                                        _sendingMessage = true;
                                      });
                                      await sendMessage(chatText.text);
                                      chatText.clear();
                                      setState(() {
                                        _sendingMessage = false;
                                      });
                                    },
                                    child: Image.asset(
                                      'assets/images/send.png',
                                      fit: BoxFit.contain,
                                      width: media.width * 0.075,
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      //loader
                      (_sendingMessage == true)
                          ? const Positioned(top: 0, child: Loading())
                          : Container()
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }
}
