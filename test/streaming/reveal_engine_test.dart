import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('pacing', () {
    test('reveals at the given speed when it is keeping up', () {
      final engine = RevealEngine();
      // Backlog of 30 clears in 0.3s at 100/s, inside the 0.4s lag window, so
      // the baseline speed applies rather than the adaptation.
      engine.tick(0.1, 30, 100);
      expect(engine.revealedFloor, 10);
    });

    test('speeds up rather than falling behind a fast stream', () {
      final engine = RevealEngine();
      // 1000 characters waiting, baseline 100/s: at the baseline this would
      // take ten seconds. It must clear the backlog inside the lag window.
      engine.tick(RevealEngine.maxLagSeconds, 1000, 100);
      expect(engine.revealedFloor, 1000);
    });

    test('never overshoots the text it was given', () {
      final engine = RevealEngine();
      engine.tick(10, 50, 1000);
      expect(engine.revealed, 50);
    });

    test('reports completion so the caller can stop ticking', () {
      final engine = RevealEngine();
      expect(engine.tick(0.1, 1000, 100), isTrue);
      expect(engine.tick(100, 1000, 100), isFalse);
    });
  });

  group('fast-forward', () {
    test('clears the remainder within the catch-up window', () {
      final engine = RevealEngine();
      engine.beginFastForward();
      engine.tick(RevealEngine.fastForwardSeconds, 5000, 10);
      expect(engine.revealedFloor, 5000);
    });

    test('is cleared when more text arrives after all', () {
      final engine = RevealEngine();
      engine.beginFastForward();
      engine.clearFastForward();
      // Back to the slower lag window, so a large backlog is not cleared in
      // the shorter fast-forward time.
      engine.tick(RevealEngine.fastForwardSeconds, 5000, 10);
      expect(engine.revealedFloor, lessThan(5000));
    });
  });

  group('replacement', () {
    test('reset starts again from nothing', () {
      final engine = RevealEngine()..snapToEnd(500);
      engine.reset();
      expect(engine.revealedFloor, 0);
    });

    test('snapToEnd skips the animation entirely', () {
      final engine = RevealEngine()..snapToEnd(500);
      expect(engine.caughtUp(500), isTrue);
    });

    test('truncateTo clamps when the source shrank', () {
      final engine = RevealEngine()..snapToEnd(500);
      engine.truncateTo(100);
      expect(engine.revealedFloor, 100);
    });

    test('truncateTo leaves a longer source alone', () {
      final engine = RevealEngine()..snapToEnd(100);
      engine.truncateTo(500);
      expect(engine.revealedFloor, 100);
    });
  });
}
