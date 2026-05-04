import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veto/features/call/call_args.dart';
import 'package:veto/features/call/call_screen.dart';
import 'package:veto/features/call/call_session_controller.dart';
import 'package:veto/main.dart';

void main() {
  test('CallArgs parses the existing /call route contract', () {
    final args = CallArgs.tryParse(<String, dynamic>{
      'roomId': '674a1b2c3d4e5f6789012345',
      'eventId': '674a1b2c3d4e5f6789012345',
      'language': 'he',
      'agoraToken': 'token',
      'agoraUid': '1234',
      'peerName': 'Adv. Shir',
      'peerSpecialization': 'Criminal',
      'caseSummary': 'Arrested near Allenby at 22:40.',
      'distanceLabel': '1.2km',
      'callType': 'webrtc',
      'role': 'user',
    });

    expect(args, isNotNull);
    expect(args!.channelId, '674a1b2c3d4e5f6789012345');
    expect(args.eventId, '674a1b2c3d4e5f6789012345');
    expect(args.language, 'he');
    expect(args.agoraUid, 1234);
    expect(args.peerLabel, 'Adv. Shir');
    expect(args.wantVideo, isTrue);
    expect(args.chatOnly, isFalse);
    expect(args.isIncoming, isFalse);
    expect(args.isRtl, isTrue);
  });

  test('CallArgs supports chat and incoming modes', () {
    final args = CallArgs.tryParse(<String, dynamic>{
      'roomId': 'room-1',
      'callType': 'chat',
      'peerName': 'Citizen',
      'role': 'lawyer',
      'language': 'ru',
      'mode': 'incoming',
    });

    expect(args, isNotNull);
    expect(args!.chatOnly, isTrue);
    expect(args.wantVideo, isFalse);
    expect(args.isIncoming, isTrue);
    expect(args.socketRole, 'lawyer');
    expect(args.isRtl, isFalse);
  });

  test('CallNetworkQuality reports the worse direction', () {
    const quality = CallNetworkQuality(up: 2, down: 5, rttMs: 78, txKbps: 640);

    expect(quality.worst, 5);
    expect(quality.rttMs, 78);
    expect(quality.txKbps, 640);
  });

  test('CallChatLine preserves ownership and text', () {
    const mine = CallChatLine(text: 'שלום', mine: true);
    const theirs = CallChatLine(text: 'Hi', mine: false);

    expect(mine.text, 'שלום');
    expect(mine.mine, isTrue);
    expect(theirs.mine, isFalse);
  });

  test('CallFailure carries kind and raw diagnostics', () {
    const failure = CallFailure(
      CallFailureKind.tokenInvalid,
      'ErrInvalidToken: 42',
    );

    expect(failure.kind, CallFailureKind.tokenInvalid);
    expect(failure.message, contains('ErrInvalidToken'));
  });

  test('/call route is registered', () {
    expect(vetoAppRoutes.containsKey('/call'), isTrue);
  });

  testWidgets('CallScreen without route args redirects to home', (tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: <String, WidgetBuilder>{
        '/veto_screen': (_) => const Text('home'),
      },
      home: const CallScreen(),
    ));

    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
