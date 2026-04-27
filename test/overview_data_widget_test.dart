import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/widgets/overview_data.dart';

void main() {
  Widget buildWidget({
    int courseTakers = 10,
    int goCourses = 8,
    int placesAsked = 30,
    int placesGiven = 25,
    int unmetWants = 5,
    int onLeave = 2,
    VoidCallback? onUnmetWantsClicked,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: OverviewData(
          courseTakers: courseTakers,
          goCourses: goCourses,
          placesAsked: placesAsked,
          placesGiven: placesGiven,
          unmetWants: unmetWants,
          onLeave: onLeave,
          onUnmetWantsClicked: onUnmetWantsClicked ?? () {},
        ),
      ),
    );
  }

  testWidgets('displays all stat labels', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.text('Course Takers'), findsOneWidget);
    expect(find.text('Go Courses'), findsOneWidget);
    expect(find.text('Places Asked'), findsOneWidget);
    expect(find.text('Places Given'), findsOneWidget);
    expect(find.text('Unmet Wants'), findsOneWidget);
    expect(find.text('On Leave'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
  });

  testWidgets('displays correct stat values', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      courseTakers: 42,
      goCourses: 7,
      placesAsked: 100,
      placesGiven: 90,
      unmetWants: 3,
      onLeave: 1,
    ));
    expect(find.text('42'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // Missing is always 0
  });

  testWidgets('tapping Unmet Wants label triggers callback',
      (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(buildWidget(
      unmetWants: 5,
      onUnmetWantsClicked: () => tapped++,
    ));
    await tester.tap(find.text('Unmet Wants'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('tapping Unmet Wants count triggers callback',
      (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(buildWidget(
      unmetWants: 5,
      onUnmetWantsClicked: () => tapped++,
    ));
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('stats panel uses compact font size (13)', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (final t in textWidgets) {
      if (t.style?.fontSize != null) {
        expect(t.style!.fontSize, lessThanOrEqualTo(13));
      }
    }
  });
}
