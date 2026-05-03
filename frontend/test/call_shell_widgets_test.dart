// ============================================================
//  call_shell_widgets_test.dart — Isolated widget tests for the
//  V26 call sub-widgets. We do NOT pump the full CallShellScreen
//  here because that spins up Agora, sockets, permission handlers,
//  etc. — each of which is verified separately.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veto/services/agora_service.dart';
import 'package:veto/widgets/call/call_i18n.dart';
import 'package:veto/widgets/call/v26_call_connecting.dart';
import 'package:veto/widgets/call/v26_call_error_sheet.dart';
import 'package:veto/widgets/call/v26_call_incoming.dart';
import 'package:veto/widgets/call/v26_call_side_panel.dart';
import 'package:veto/widgets/call/v26_call_top_bar.dart';
import 'package:veto/widgets/call/v26_call_video_area.dart';
import 'package:veto/widgets/call/v26_call_voice_stage.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: child,
      ),
    ),
  );
}

Future<void> _pumpTall(WidgetTester tester, Widget host) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(host);
}

void main() {
  testWidgets('V26CallConnecting shows lawyer search label + cancel button',
      (tester) async {
    var cancelled = false;
    await _pumpTall(
      tester,
      _host(V26CallConnecting(
        language: 'he',
        elapsedSec: 4,
        onCancel: () => cancelled = true,
      )),
    );
    await tester.pump();
    expect(find.text(CallI18n.findingLawyer.t('he')), findsOneWidget);
    expect(find.text(CallI18n.badgeConnecting.t('he')), findsOneWidget);
    expect(find.text('4s'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(cancelled, isTrue);
  });

  testWidgets('V26CallIncoming renders case summary and fires accept/decline',
      (tester) async {
    var accepted = false;
    var declined = false;
    await _pumpTall(
        tester,
        _host(V26CallIncoming(
          language: 'en',
          callerName: 'Dana L.',
          caseSummary: 'Arrested near Allenby at 22:40.',
          specialization: 'Criminal',
          distanceLabel: '1.2km',
          onAccept: () => accepted = true,
          onDecline: () => declined = true,
        ))); // _pumpTall wrapper already applied to this widget's host
    await tester.pump();
    expect(find.text('Dana L.'), findsOneWidget);
    expect(find.text('Arrested near Allenby at 22:40.'), findsOneWidget);
    expect(find.text(CallI18n.incomingBadge.t('en')), findsOneWidget);
    expect(find.text('Criminal · 1.2km'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.call_rounded));
    await tester.pump();
    expect(accepted, isTrue);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(declined, isTrue);
  });

  testWidgets('V26CallTopBar formats duration + peer name', (tester) async {
    await tester.pumpWidget(_host(const V26CallTopBar(
      peerName: 'Adv. Shir',
      specialization: 'Criminal',
      durationSec: 125,
      quality: NetworkQuality(up: 2, down: 2, rttMs: 78),
      language: 'he',
      isRecording: true,
    )));
    await tester.pump();
    expect(find.text('Adv. Shir'), findsOneWidget);
    expect(find.text('02:05'), findsOneWidget);
    expect(find.text(CallI18n.recordingShort.t('he')), findsOneWidget);
  });

  testWidgets('V26VideoPlaceholder displays initials and waiting copy',
      (tester) async {
    await tester.pumpWidget(_host(const V26VideoPlaceholder(
      peerName: 'Dana Levi',
      language: 'en',
    )));
    await tester.pump();
    expect(find.text('DL'), findsOneWidget);
    expect(find.text(CallI18n.waitingForPeer.t('en')), findsOneWidget);
  });

  testWidgets('V26CallVoiceStage shows timer + peer', (tester) async {
    await tester.pumpWidget(_host(const V26CallVoiceStage(
      peerName: 'Adv. Noa',
      specialization: 'Family',
      durationSec: 65,
      isRecording: false,
      language: 'ru',
    )));
    await tester.pump();
    expect(find.text('Adv. Noa'), findsOneWidget);
    expect(find.text('01:05'), findsOneWidget);
    expect(find.text(CallI18n.voiceHeader.t('ru')), findsOneWidget);
  });

  testWidgets('V26CallErrorSheet translates errInvalidToken to Hebrew message',
      (tester) async {
    var retried = false;
    var exited = false;
    await tester.pumpWidget(_host(V26CallErrorSheet(
      language: 'he',
      error: const CallErrorEvent(
          CallErrorKind.tokenInvalid, 'ErrInvalidToken: 42'),
      onRetry: () => retried = true,
      onExit: () => exited = true,
    )));
    await tester.pump();
    expect(find.text(CallI18n.errorTitle.t('he')), findsOneWidget);
    expect(find.text(CallI18n.errorTokenInvalid.t('he')), findsOneWidget);
    await tester.tap(find.text(CallI18n.errorRetry.t('he')));
    await tester.pump();
    expect(retried, isTrue);
    await tester.tap(find.text(CallI18n.errorExit.t('he')));
    await tester.pump();
    expect(exited, isTrue);
  });

  testWidgets('V26CallSidePanel chat tab surfaces empty state + send callback',
      (tester) async {
    var sent = '';
    await tester.pumpWidget(_host(V26CallSidePanel(
      language: 'he',
      lines: const <CallChatLine>[],
      onSend: (t) => sent = t,
    )));
    await tester.pump();
    expect(find.text(CallI18n.chatEmpty.t('he')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'שלום');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(sent, 'שלום');
  });
}
