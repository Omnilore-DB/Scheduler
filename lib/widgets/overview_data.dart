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

  static const double _labelSize = 17;
  static const double _valueSize = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: themeColors['LightBlue'],
      constraints: const BoxConstraints.expand(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _statRow('Course Takers', courseTakers),
          _divider(),
          _statRow('Go Courses', goCourses),
          _divider(),
          _statRow('Places Asked', placesAsked),
          _divider(),
          _statRow('Places Given', placesGiven),
          _divider(),
          _unmetWantsRow(),
          _divider(),
          _statRow('On Leave', onLeave),
          _divider(),
          _statRow('Missing', 0),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: Colors.black.withValues(alpha: 0.08),
      );

  Widget _statRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: _labelSize, color: Colors.black87)),
          Text('$value',
              style: const TextStyle(
                  fontSize: _valueSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ],
      ),
    );
  }

  Widget _unmetWantsRow() {
    return InkWell(
      onTap: onUnmetWantsClicked,
      mouseCursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Unmet Wants',
              style: TextStyle(
                  fontSize: _labelSize,
                  color: Colors.blue,
                  decoration: TextDecoration.underline),
            ),
            Text(
              '$unmetWants',
              style: const TextStyle(
                  fontSize: _valueSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
