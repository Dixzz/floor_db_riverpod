import 'dart:async';

import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:omni_datetime_picker/src/variants/omni_datetime_picker_variants/omni_dtp_basic.dart';
import 'package:scheduler/helpers/dates.dart';
import 'package:scheduler/helpers/iterables.dart';
import 'package:scheduler/helpers/logger.dart';
import 'package:scheduler/pages/add_revent.dart';
import 'package:scheduler/provider/global_providers.dart';

import '../models/revent.dart';

part 'home_provider.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends ConsumerState {
  StreamSubscription? _subs;
  final k = GlobalKey<AddREventState>();

  void fetchReminders() {
    _subs?.cancel();
    final priority = ref.read(rEventFilterBy);

    final filterDate = ref.read(dateStateProvider);
    final now = DateTime(filterDate.year, filterDate.month, filterDate.day);
    final endDate = DateTime(now.year, now.month, now.day + 1);
    if (priority == -1) {
      _subs = ref
          .read(dbProvider)
          .personDao
          .findAllPersons(now, endDate)
          .listen((event) {
        logit("Fetched items ${event.length} ${ref.read(rEventFilterBy)}");
        ref.read(rEventStateProvider.notifier).state = event;
      });
      return;
    }
    _subs = ref
        .read(dbProvider)
        .personDao
        .findAllPersonsFiltered(ref.read(rEventFilterBy), now, endDate)
        .listen((event) {
      logit("Fetched items ${event.length} ${ref.read(rEventFilterBy)}");
      ref.read(rEventStateProvider.notifier).state = event;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ref.read(dateStateProvider.notifier).addListener((_) {
      fetchReminders();
    });
    ref.read(rEventFilterBy.notifier).addListener((_) {
      fetchReminders();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _subs?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    logit("wew built main");
    return Scaffold(
      body: Column(
        children: [
          const Statusbar(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminders',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: const Color(0xff8d8d8d),
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          var res = await showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: OmniDtpBasic(
                                      type: OmniDateTimePickerType.date,
                                    ),
                                  )));
                          if (res is DateTime) {
                            // re-fetch
                            ref.read(dateStateProvider.notifier).state = res;
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                DatePatterns.eeeddmmmyy
                                    .format(ref.watch(dateStateProvider)),
                                textAlign: TextAlign.left,
                                style: GoogleFonts.comfortaa(
                                    fontSize: 24, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 24,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xff4993ff),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await showCustomModalBottomSheet(
                          context: context,
                          builder: (_) => AddREvent(
                                key: k,
                                date: ref.read(dateStateProvider),
                              ),
                          containerWidget: (BuildContext context,
                              Animation<double> animation, Widget child) {
                            return Scaffold(body: child);
                          });
                      k.currentState?.reset();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 20, top: 14, right: 20, bottom: 14),
                      child: Text(
                        'Add New',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.comfortaa(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const SizedBox(
            height: 16,
          ),
          Expanded(
            child: Builder(builder: (_) {
              final p0 = ref.watch(rEventStateProvider);
              final selectedItem = p0.where((element) => element.edit);
              logit("Wew ${p0.length} ${selectedItem.length}");
              return Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: selectedItem.isNotEmpty
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 75),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected',
                                        style: GoogleFonts.comfortaa(
                                            fontSize: 20,
                                            color: const Color(0xff8E8E8E)),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Text(
                                        '${selectedItem.length} ${selectedItem.length == 1 ? "event" : "events"}',
                                        style: GoogleFonts.comfortaa(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                      onTap: () async {
                                        await Future.wait(selectedItem.map((e) => ref
                                            .read(notifProvider)
                                            .cancel(e.title.hashCode)));
                                        await ref
                                            .read(dbProvider)
                                            .personDao
                                            .deletePeople(
                                                selectedItem.toImmutableList());
                                      },
                                      child: Image.asset(
                                        'assets/images/ic_bin.png',
                                        width: 20,
                                      ))
                                ],
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              const SizedBox(
                                width: 8,
                              ),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      ref
                                                          .read(rEventFilterBy
                                                              .notifier)
                                                          .state = -1;
                                                      Navigator.pop(context);
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text('All'),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          ref.read(rEventFilterBy) ==
                                                                  -1
                                                              ? const Icon(
                                                                  Icons
                                                                      .check_rounded,
                                                                  size: 20,
                                                                  color: Colors
                                                                      .lightBlueAccent,
                                                                )
                                                              : const SizedBox
                                                                  .shrink()
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      ref
                                                          .read(rEventFilterBy
                                                              .notifier)
                                                          .state = 0;
                                                      Navigator.pop(context);
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text('High'),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          ref.read(rEventFilterBy) ==
                                                                  0
                                                              ? const Icon(
                                                                  Icons
                                                                      .check_rounded,
                                                                  color: Colors
                                                                      .lightBlueAccent,
                                                                  size: 20,
                                                                )
                                                              : const SizedBox
                                                                  .shrink()
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      ref
                                                          .read(rEventFilterBy
                                                              .notifier)
                                                          .state = -2;
                                                      Navigator.pop(context);
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text('Medium'),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          ref.watch(rEventFilterBy) ==
                                                                  -2
                                                              ? const Icon(
                                                                  Icons
                                                                      .check_rounded,
                                                                  color: Colors
                                                                      .lightBlueAccent,
                                                                  size: 20,
                                                                )
                                                              : const SizedBox
                                                                  .shrink()
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      ref
                                                          .read(rEventFilterBy
                                                              .notifier)
                                                          .state = 1;
                                                      Navigator.pop(context);
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text('Low'),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          ref.watch(rEventFilterBy) ==
                                                                  1
                                                              ? const Icon(
                                                                  Icons
                                                                      .check_rounded,
                                                                  color: Colors
                                                                      .lightBlueAccent,
                                                                  size: 20,
                                                                )
                                                              : const SizedBox
                                                                  .shrink()
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 12, top: 6, bottom: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.filter_list_rounded,
                                        size: 24,
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Builder(builder: (_) {
                                        final value = ref.watch(rEventFilterBy);
                                        return Text(
                                          value == -1
                                              ? 'All'
                                              : value == 0
                                                  ? 'High'
                                                  : value == -2
                                                      ? 'Medium'
                                                      : 'Low',
                                          style: GoogleFonts.comfortaa(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            height: 0,
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                                width: 1,
                                child: ColoredBox(
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: EasyDateTimeLine(
                                  key: ValueKey(ref.read(dateStateProvider)),
                                  initialDate: ref.read(dateStateProvider),
                                  activeColor: const Color(0x334993ff),
                                  headerProps:
                                      const EasyHeaderProps(showHeader: false),
                                  onDateChange: (res) {
                                    ref.read(dateStateProvider.notifier).state =
                                        res;
                                  },
                                  // timeLineProps: EasyTimeLineProps(
                                  //   vPadding: 20,
                                  // ),
                                  dayProps: EasyDayProps(
                                    height: 75,
                                    width: 50,
                                    dayStructure: DayStructure.dayStrDayNum,
                                    inactiveDayStyle: DayStyle(
                                      dayNumStyle: GoogleFonts.comfortaa(
                                          fontSize: 22,
                                          color: const Color(0xff7d7d7d),
                                          fontWeight: FontWeight.w600),
                                      dayStrStyle: GoogleFonts.comfortaa(
                                          fontSize: 10,
                                          color: const Color(0xff7d7d7d),
                                          fontWeight: FontWeight.w600),
                                    ),
                                    activeDayStyle: DayStyle(
                                      dayNumStyle: GoogleFonts.comfortaa(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700),
                                      dayStrStyle: GoogleFonts.comfortaa(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700),
                                      decoration: BoxDecoration(
                                        color: const Color(0x334993ff),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                      child: ImplicitlyAnimatedList(
                          items: p0,
                          itemBuilder: (_, animation, event, index) {
                            final m = Tween(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero)
                                .animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInCubic));
                            return GestureDetector(
                                onTap: () async {
                                  if (p0.any((element) => element.edit)) {
                                    setState(() {
                                      p0[index] = event.toggleEdit(!event.edit);
                                    });
                                  } else {
                                    await showCustomModalBottomSheet(
                                        context: context,
                                        containerWidget: (BuildContext context,
                                            Animation<double> animation,
                                            Widget child) {
                                          return Scaffold(body: child);
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        builder: (_) => AddREvent(
                                              event: event,
                                              key: k,
                                            ));
                                    k.currentState?.reset();
                                  }
                                },
                                onLongPress: () {
                                  setState(() {
                                    p0[index] = event.toggleEdit(true);
                                  });
                                },
                                child: SlideTransition(
                                  position: m,
                                  child: FadeTransition(
                                    opacity: animation
                                        .drive(Tween(begin: 0, end: 1)),
                                    child: AnimatedContainer(
                                        margin: const EdgeInsets.all(12),
                                        clipBehavior: Clip.hardEdge,
                                        decoration: BoxDecoration(
                                            color: !event.edit
                                                ? const Color(0xfff0f0f0)
                                                : const Color(0xFFEDF4FF),
                                            borderRadius:
                                                BorderRadius.circular(32)),
                                        duration:
                                            const Duration(milliseconds: 400),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  width: 16,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        event.title,
                                                        style: GoogleFonts
                                                            .comfortaa(
                                                                fontSize: 24,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                event.priority != -1
                                                    ? Transform.translate(
                                                        offset:
                                                            const Offset(5, 0),
                                                        child: DecoratedBox(
                                                          decoration: const BoxDecoration(
                                                              color: Color(
                                                                  0x265E5E5E),
                                                              borderRadius: BorderRadius.only(
                                                                  bottomLeft: Radius
                                                                      .circular(
                                                                          24),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          24))),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 16,
                                                                    right: 24,
                                                                    top: 6,
                                                                    bottom: 6),
                                                            child: Text(
                                                              event.priority ==
                                                                      0
                                                                  ? 'high'
                                                                  : event.priority ==
                                                                          -2
                                                                      ? 'Medium'
                                                                      : 'low',
                                                              style: GoogleFonts
                                                                  .comfortaa(
                                                                      fontSize:
                                                                          12),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : const SizedBox.shrink(),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 8,
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const SizedBox(
                                                  width: 16,
                                                ),
                                                Image.asset(
                                                  'assets/images/ic_clock_tinted.png',
                                                  width: 20,
                                                ),
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                  TimePatterns.hhmmaa
                                                      .format(event.event),
                                                  style: GoogleFonts.comfortaa(
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 16,
                                            ),
                                          ],
                                        )),
                                  ),
                                ));
                          },
                          areItemsTheSame: (a, b) => a.title == b.title)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
