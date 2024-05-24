import 'dart:async';
import 'dart:convert';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scheduler/helpers/iterables.dart';
import 'package:scheduler/helpers/logger.dart';
import 'package:scheduler/main.dart' show faClientMemColRef, faProdMemColRef;
import 'package:scheduler/models/api_helper.dart';
import 'package:scheduler/models/fs_product_member.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ViewEventController extends GetxController {
  var prodIndex = -1;
  var clientIndex = -1;

  late final prodMembers = <ProductMember>[].obs;
  late final clientMembers = <ProductMember>[].obs;
  late final StreamSubscription<QuerySnapshot<ProductMember>>? _prodMembersSubs;
  late final StreamSubscription<QuerySnapshot<ProductMember>>? _clientsSubs;

  late final ctr = TextEditingController();

  var virtual = false.obs;

  @override
  void onInit() {
    super.onInit();
    _prodMembersSubs = faProdMemColRef.snapshots().listen((event) {
      prodIndex = -1;
      prodMembers.value = event.docs.map((e) => e.data()).toImmutableList();
    });
    _clientsSubs = faClientMemColRef.snapshots().listen((event) {
      clientIndex = -1;
      clientMembers.value = event.docs.map((e) => e.data()).toImmutableList();
    });
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    super.dispose();
    await _prodMembersSubs?.cancel();
    await _clientsSubs?.cancel();
    ctr.dispose();
  }
}

class AddEvent extends StatelessWidget {
  ViewEventController get c => Get.find();

  const AddEvent({Key? key}) : super(key: key);

  ImageProvider? _buildImageProvider(String? image) {
    ImageProvider? imageProvider = image != null ? NetworkImage(image) : null;
    if (image != null && image.startsWith('data:image')) {
      imageProvider = MemoryImage(
        base64Decode(image.substring(image.indexOf('base64') + 7)),
      );
    }
    return imageProvider;
  }

  @override
  Widget build(BuildContext context) {
    final ViewEventController c = Get.put(ViewEventController());

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        // primary: true,
        controller: ModalScrollController.of(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Statusbar(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Add new event',
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                ),
                Image.asset(
                  'assets/images/ic_application.png',
                  width: 38,
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            TextField(
              decoration: const InputDecoration.collapsed(
                  hintText: 'Application Name',
                  hintStyle: TextStyle(color: Color(0xFFB7B7B7))),
              style: GoogleFonts.comfortaa(
                fontSize: 24,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            TextField(
              decoration: const InputDecoration.collapsed(
                  hintText: 'Client Name',
                  hintStyle: TextStyle(color: Color(0xFFB7B7B7))),
              style: GoogleFonts.comfortaa(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(
              height: 16,
            ),
            const Divider(),
            const SizedBox(
              height: 16,
            ),
            Text('Client Segment',
                style: GoogleFonts.comfortaa(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600)),
            const SizedBox(
              height: 16,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ObxValue((p0) {
                logit("Built ${p0.toJson()}");
                var i = -1;
                return Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.start,
                  children: [
                    ...p0.map((element) {
                      i += 1;
                      final index = i;
                      logit("Built $index");
                      return InkWell(
                        onTap: () {
                          logit(
                              "Updated ${element.toJson()} $index ${c.prodIndex}");
                          if (c.clientIndex == index) return;
                          if (c.clientIndex != -1) {
                            c.clientMembers[c.clientIndex] = ProductMember(
                                c.clientMembers[c.clientIndex].name, false);
                          }
                          c.clientMembers[index] =
                              ProductMember(element.name, !element.edit);
                          c.clientIndex = index;
                        },
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: element.edit
                                ? const Color(0x264993FF)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 1,
                                  color: Color(
                                      element.edit ? 0xFF98C2FF : 0xFFBDBDBD)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(
                              element.name,
                              style: GoogleFonts.comfortaa(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 0,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    InkWell(
                      onTap: () {
                        Get.dialog(Dialog(
                          backgroundColor: Colors.transparent,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Add Client Member',
                                      style:
                                          GoogleFonts.comfortaa(fontSize: 18)),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  TextField(
                                    controller: c.ctr,
                                    autofocus: true,
                                    style: GoogleFonts.nunito(),
                                    decoration: const InputDecoration.collapsed(
                                        hintText: 'Enter name'),
                                    onSubmitted: (_) async {
                                    },
                                  ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  Center(
                                    child: FilledButton(
                                        onPressed: () async {
                                        },
                                        child: const Text('Create')),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                      },
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0x804993FF)),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(
                            dimension: 20,
                            child: Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Color(0xFF4993FF),
                            ),
                          )),
                    ),
                  ],
                );
              }, c.clientMembers),
            ),
            const SizedBox(
              height: 16,
            ),
            const Divider(),
            const SizedBox(
              height: 16,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Virtual Event',
                    style: GoogleFonts.comfortaa(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                ObxValue(
                    (p0) => FlutterSwitch(
                          width: 30.0,
                          height: 22.0,
                          // valueFontSize: 25.0,
                          toggleSize: 12.0,
                          borderRadius: 30.0,
                          value: p0.value,
                          onToggle: c.virtual,
                        ),
                    c.virtual)
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            const Divider(),
            const SizedBox(
              height: 24,
            ),
            Wrap(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            width: 1, color: Color(0xFFC6C6C6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Date',
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF929292),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 0,
                                ),
                              ),
                              Text(
                                'Wed, 9 June 24’',
                                style: GoogleFonts.nunito(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          SvgPicture.asset(
                            'assets/images/ic_date_outlined.svg',
                            width: 16,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            width: 1, color: Color(0xFFC6C6C6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Clock',
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF929292),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 0,
                                ),
                              ),
                              Text(
                                '09.30 AM',
                                style: GoogleFonts.nunito(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 57,
                          ),
                          SvgPicture.asset(
                            'assets/images/ic_clock_outlined.svg',
                            width: 16,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Wrap(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            width: 1, color: Color(0xFFC6C6C6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: InkWell(
                      onTap: () async {
                        launchUrlString(
                            'https://meet.google.com/dye-wojk-wzz?pli=1',
                            mode: LaunchMode.externalApplication);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Link to join',
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFF929292),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 0,
                                  ),
                                ),
                                FutureBuilder(
                                  builder: (_, data) {
                                    AnyLinkPreview.isValidLink(
                                        'https://meet.google.com/dye-wojk-wzz?pli=1');
                                    if (data.hasError) {
                                      return const Text('Unable to preview');
                                    }
                                    final img =
                                        _buildImageProvider(data.data?.image);
                                    if (img == null) {
                                      return const Text('Unable to preview');
                                    }
                                    return Row(children: [
                                      Image(
                                        image: img,
                                        width: 20,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(data.data?.title ?? 'NA',
                                          style: GoogleFonts.comfortaa(
                                            color: Colors.black,
                                            // fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            height: 0,
                                          ))
                                    ]);
                                  },
                                  future: AnyLinkPreview.getMetadata(
                                      link:
                                          'https://meet.google.com/dye-wojk-wzz?pli=1'),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 70,
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: SvgPicture.asset(
                                'assets/images/ic_meeting_outlined.svg',
                                width: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            width: 1, color: Color(0xFFC6C6C6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Duration',
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF929292),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 0,
                                ),
                              ),
                              Text(
                                '30m',
                                style: GoogleFonts.nunito(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 80,
                          ),
                          SvgPicture.asset(
                            'assets/images/ic_duration_outlined.svg',
                            width: 16,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            const Divider(),
            const SizedBox(
              height: 16,
            ),
            Text('Product Members',
                style: GoogleFonts.comfortaa(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600)),
            const SizedBox(
              height: 16,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ObxValue((p0) {
                logit("Built ${p0.toJson()}");
                var i = -1;
                return Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.start,
                  children: [
                    ...p0.map((element) {
                      i += 1;
                      final index = i;
                      logit("Built $index");
                      return InkWell(
                        onTap: () {
                          logit(
                              "Updated ${element.toJson()} $index ${c.prodIndex}");
                          if (c.prodIndex == index) return;
                          if (c.prodIndex != -1) {
                            c.prodMembers[c.prodIndex] = ProductMember(
                                c.prodMembers[c.prodIndex].name, false);
                          }
                          c.prodMembers[index] =
                              ProductMember(element.name, !element.edit);
                          c.prodIndex = index;
                        },
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: element.edit
                                ? const Color(0x264993FF)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 1,
                                  color: Color(
                                      element.edit ? 0xFF98C2FF : 0xFFBDBDBD)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(
                              element.name,
                              style: GoogleFonts.comfortaa(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 0,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    InkWell(
                      onTap: () {
                        Get.dialog(Dialog(
                          backgroundColor: Colors.transparent,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Add Product Member',
                                      style:
                                          GoogleFonts.comfortaa(fontSize: 18)),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  TextField(
                                    controller: c.ctr,
                                    autofocus: true,
                                    style: GoogleFonts.nunito(),
                                    decoration: const InputDecoration.collapsed(
                                        hintText: 'Enter name'),
                                    onSubmitted: (_) async {
                                    },
                                  ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  Center(
                                    child: FilledButton(
                                        onPressed: () async {
                                        },
                                        child: const Text('Create')),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ));
                      },
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0x804993FF)),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(
                            dimension: 20,
                            child: Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Color(0xFF4993FF),
                            ),
                          )),
                    ),
                  ],
                );
              }, c.prodMembers),
            ),
            const SizedBox(
              height: 24,
            ),
            Center(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  elevation: 4,
                    textStyle: GoogleFonts.comfortaa(fontSize: 14)),
                onPressed: () {},
                child: Text('Create'),
              ),
            ),
            const SizedBox(
              height: 4,
            ),

          ],
        ),
      ),
    );
  }
}
