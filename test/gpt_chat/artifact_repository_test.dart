import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

import 'fakes.dart';

const _queued = ValArtifact(
  id: 'a1',
  name: 'Seed Germination',
  status: ArtifactStatus.queued,
  token: 'tok',
);

void main() {
  late FakeArtifactService service;
  late ArtifactRepository repository;

  setUp(() {
    service = FakeArtifactService();
    repository = ArtifactRepository(service: service);
  });

  tearDown(() => repository.dispose());

  test('tracking a queued artifact starts one watcher', () {
    repository.track(_queued);
    repository.track(_queued);

    expect(service.watched, ['a1']);
    expect(repository['a1']!.status, ArtifactStatus.queued);
  });

  test('updates are merged and broadcast', () async {
    final seen = <ArtifactStatus>[];
    repository.updates.listen((a) => seen.add(a.status));
    repository.track(_queued);

    service.emit(
      'a1',
      const ValArtifact(id: 'a1', name: '', status: ArtifactStatus.generating),
    );
    service.emit(
      'a1',
      const ValArtifact(
        id: 'a1',
        name: '',
        status: ArtifactStatus.ready,
        script: 'scene {}',
      ),
    );
    await pumpEventQueue();

    expect(seen, [
      ArtifactStatus.queued,
      ArtifactStatus.generating,
      ArtifactStatus.ready,
    ]);
    expect(repository['a1']!.script, 'scene {}');
    expect(repository['a1']!.name, 'Seed Germination');
    expect(repository['a1']!.token, 'tok');
  });

  test('a terminal artifact is never watched', () {
    repository.track(
      const ValArtifact(id: 'a2', name: 'Done', status: ArtifactStatus.ready),
    );

    expect(service.watched, isEmpty);
  });

  test('a watch failure marks the artifact failed', () async {
    repository.track(_queued);
    service.failWatch('a1', const ChatException('token expired'));
    await pumpEventQueue();

    expect(repository['a1']!.hasFailed, isTrue);
    expect(repository['a1']!.error, 'token expired');
  });

  test('snapshot exposes every tracked artifact', () {
    repository.track(_queued);

    expect(repository.snapshot.keys, ['a1']);
  });
}
