import 'package:flutter_test/flutter_test.dart';
import 'package:sensortrack/main.dart';

void main() {
  testWidgets('SensorTrack smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SensorTrackApp());
    expect(find.text('SensorTrack'), findsWidgets);
  });
}
