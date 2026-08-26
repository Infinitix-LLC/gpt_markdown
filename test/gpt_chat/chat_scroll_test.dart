import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

String get _long =>
    List.generate(60, (i) => 'Line $i of the reply.').join('\n\n');

void main() {
  group('host-driven scrolling', _hostDrivenScrollTests);

  testWidgets('a wheel scroll away from the bottom stops following', (
    tester,
  ) async {
    late ChatController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: GptChat(
          adapter: FakeAdapter(deltas: [_long]),
          onControllerReady: (c) => controller = c,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await controller.onSend('q');
    await tester.pumpAndSettle();

    expect(controller.isFollowingLatest, isTrue);
    final before = controller.scrollController.position.pixels;

    // Wheel, not drag: pointer-signal scrolling carries no dragDetails.
    final center = tester.getCenter(find.byType(ChatTranscript));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(center);
    for (var i = 0; i < 4; i++) {
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -160)));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pumpAndSettle();

    final afterScroll = controller.scrollController.position.pixels;
    expect(
      afterScroll,
      lessThan(before),
      reason: 'the wheel moved the viewport',
    );
    expect(
      controller.isFollowingLatest,
      isFalse,
      reason: 'a wheel scroll is a user scroll',
    );

    // Anything that makes the adapter notify must not drag the view back.
    controller.adapter.notifyListeners();
    await tester.pumpAndSettle();

    expect(
      controller.scrollController.position.pixels,
      afterScroll,
      reason: 'the view must stay where the user put it',
    );
  });
}

void _hostDrivenScrollTests() {
  testWidgets('followLatest false leaves the viewport to the host', (
    tester,
  ) async {
    final scroll = ScrollController();
    final adapter = FakeAdapter(deltas: [_long]);
    final controller = ChatController(
      adapter: adapter,
      scrollController: scroll,
      followLatest: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: GptChat(adapter: adapter, controller: controller)),
    );
    await tester.pumpAndSettle();

    await controller.onSend('q');
    await tester.pumpAndSettle();

    expect(
      scroll.position.pixels,
      0,
      reason: 'sending must not move a viewport the host owns',
    );
    expect(controller.canJumpToLatest, isFalse);

    // Nothing the adapter does may drag it either.
    adapter.notifyListeners();
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, 0);

    controller.dispose();
    scroll.dispose();
  });
}
