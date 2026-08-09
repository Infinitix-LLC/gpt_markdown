import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat/gpt_chat.dart';

const _tag =
    '{"type":"val_artifact","id":"ruKa","name":"Seed Germination",'
    '"frame":"reels","status":"queued","token":"eyJ"}';

void main() {
  test('parses a val_artifact tag', () {
    final artifact = parseGenUiArtifact(_tag)!;

    expect(artifact.id, 'ruKa');
    expect(artifact.name, 'Seed Germination');
    expect(artifact.frame, ArtifactFrame.reels);
    expect(artifact.status, ArtifactStatus.queued);
    expect(artifact.token, 'eyJ');
  });

  test('ignores gen-UI types owned by the host app', () {
    expect(parseGenUiArtifact('{"type":"chart","id":"1"}'), isNull);
  });

  test('ignores malformed payloads', () {
    expect(parseGenUiArtifact('{not json'), isNull);
  });
}
