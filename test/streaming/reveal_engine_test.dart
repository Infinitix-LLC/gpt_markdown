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
      // Catching up is not the same as being finished: the characters that
      // just landed are still playing their entrance, and stopping the ticker
      // here would freeze them part-way through.
      expect(engine.tick(100, 1000, 100), isTrue);
      expect(engine.tailStillFading, isTrue);
      // Once the last of them has finished, there is nothing left to draw.
      expect(engine.tick(RevealEngine().fadeSeconds, 1000, 100), isFalse);
      expect(engine.tailStillFading, isFalse);
    });

    test('a zero fade finishes the moment it catches up', () {
      final engine = RevealEngine(fadeSeconds: 0);
      expect(engine.tick(0.1, 1000, 100), isTrue);
      expect(engine.tick(100, 1000, 100), isFalse);
    });

    test('progress ramps from 0 to 1 over the fade', () {
      final engine = RevealEngine(fadeSeconds: 0.2);
      engine.tick(0.1, 10, 100);
      expect(engine.revealedFloor, 10);
      // The newest character has only just landed; the oldest is further on.
      expect(engine.progressFor(9), lessThan(engine.progressFor(0)));
      expect(engine.progressFor(9), inInclusiveRange(0, 1));
      engine.tick(0.5, 10, 100);
      expect(engine.progressFor(9), 1);
    });

    test('a character past the reveal head has not started', () {
      final engine = RevealEngine();
      engine.tick(0.01, 1000, 100);
      expect(engine.progressFor(999), 0);
    });

    test('stamps stay bounded however much lands in one frame', () {
      final engine = RevealEngine(fadeSeconds: 0.2);
      // One frame revealing far more than the ring can hold.
      engine.tick(1, 100000, 1000000);
      expect(engine.revealedFloor, 100000);
      // Everything older than the ring is finished by definition.
      expect(engine.progressFor(0), 1);
      expect(engine.progressFor(100000 - RevealEngine.fadeWindow - 1), 1);
      // The newest ones are still arriving.
      expect(engine.progressFor(99999), lessThan(1));
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
