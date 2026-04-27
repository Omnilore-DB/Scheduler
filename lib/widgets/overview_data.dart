import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/theme.dart';

class OverviewData extends StatelessWidget {
  const OverviewData(
      {Key? key,
      required this.courseTakers,
      required this.goCourses,
      required this.placesAsked,
      required this.placesGiven,
      required this.unmetWants,
      required this.onLeave,
      required this.onUnmetWantsClicked})
      : super(key: key);

  final int courseTakers;
  final int goCourses;
  final int placesAsked;
  final int placesGiven;
  final int unmetWants;
  final int onLeave;
  final VoidCallback onUnmetWantsClicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: themeColors['LightBlue'],
      constraints: const BoxConstraints.expand(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _statRow('Course Takers', courseTakers),
          _statRow('Go Courses', goCourses),
          _statRow('Places Asked', placesAsked),
          _statRow('Places Given', placesGiven),
          _unmetWantsRow(context),
          _statRow('On Leave', onLeave),
          _statRow('Missing', 0),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text('$value',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ],
      ),
    );
  }

  Widget _unmetWantsRow(BuildContext context) {
    return InkWell(
      onTap: onUnmetWantsClicked,
      mouseCursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Unmet Wants',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue,
                  decoration: TextDecoration.underline),
            ),
            Text(
              '$unmetWants',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
