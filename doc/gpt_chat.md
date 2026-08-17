# `gpt_chat` — the chat page

A chat UI layer for any app, rendered with `gpt_markdown`.

The package owns the **shell**: the scaffold, the transcript and its scrolling,
the anchoring of the newest exchange, the composer, the layout metrics. Where the
conversation comes from is yours.

```dart
import 'package:gpt_markdown/gpt_chat.dart';
```

That library pulls in no HTTP dependency. The Plusfinity Gateway client lives
separately in `package:gpt_markdown/gpt_chat_gateway.dart`.

---

## 1. The shortest thing that works

Extend `StreamingChatAdapter` and implement one method. Sessions, titling,
cancellation, retry and persistence are handled for you.

```dart
class EchoAdapter extends StreamingChatAdapter {
  @override
  Stream<ChatDelta> streamReply(List<ChatMessage> history) async* {
    final question = history.last.content;
    for (final word in question.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      yield ChatDelta('$word ');
    }
  }
}

// …
GptChat(adapter: EchoAdapter())
```

Throw from `streamReply` to fail the reply; the exception's `toString()` becomes
the message the user sees. Yield `ChatDelta.replace(whole)` instead of `ChatDelta(chunk)`
when your provider re-sends the full text each tick.

A runnable version of this, with and without customization, is in
[`example/lib/adapter_demo.dart`](../example/lib/adapter_demo.dart).

---

## 2. Customization is progressive

Four levels. Most apps stop at the first.

| Level | Reach | What you write |
|---|---|---|
| 1 | colours, spacing, widths, typography | `ChatTheme` |
| 2 | one part looks different | a builder for that part |
| 3 | a region is structurally different | a container builder, reusing the parts it hands you |
| 4 | you want the whole page | `ChatScope` + the exported widgets |

### Level 1 — theme

```dart
GptChat(
  adapter: adapter,
  theme: const ChatTheme(
    contentMaxWidth: 720,
    questionBubbleRadius: BorderRadius.all(Radius.circular(22)),
    hintText: 'Say something',
  ),
)
```

A `ChatTheme` registered as a `ThemeExtension` works too. Resolution order is
`GptChat(theme:)` → extension → defaults derived from `Theme.of(context)`.

Fields worth knowing: `contentMaxWidth`, `composerMaxWidth`, `appBarHeight`,
`composerReserve`, `transcriptPadding`, `scrollPhysics`, `pairSpacing`,
`messageSpacing`, `horizontalPadding`, `showQuestionBubble`,
`questionCollapseThreshold`, `answerActionsAlwaysVisible`, `showSeparators`,
and the usual colour/radius/padding set for the bubble, composer and buttons.

### Levels 2 and 3 — builders

Every builder takes one `ChatSlot`. The slot carries the controller, the resolved
theme, `child` (the widget the package would have built), **and the parts that
composed it**.

```dart
ChatBuilders(
  // decorate: keep the default, wrap it
  answerText: (s) => Padding(padding: const EdgeInsets.all(8), child: s.child),

  // replace a leaf
  composerSend: (s) => MySendButton(onTap: s.controller.onSend),

  // recompose, keeping every part the package built
  answer: (s) => Column(children: [...s.above, s.text, MyCitations(), s.actions]),

  // your own list, the package's exchanges
  messageList: (s) => AnimatedList(
    controller: s.scrollController,
    itemBuilder: (_, i, __) => s.item(i),
  ),

  // your own shell, the package's regions
  scaffold: (s) => MyShell(bar: s.appBar, body: s.body, input: s.composer),
)
```

That is the whole idea: overriding one level never costs you the levels beneath
it. Hide anything by returning `const SizedBox.shrink()`.

Names are flat and prefixed, so typing `answer` or `composer` in an IDE lists
everything in that area: `answer`, `answerText`, `answerStatus`,
`answerReasoning`, `answerAttachments`, `answerError`, `answerActions`,
`answerAbove`, `answerBelow`; `composer`, `composerField`, `composerSend`,
`composerStop`, `composerAbove`, `composerSuggestions`, `composerAttachments`,
`composerLeading`, `composerTrailing`; and so on for `question…`, `appBar…`,
`drawer…`, plus `scaffold`, `body`, `messageList`, `pair`, `separator`,
`listHeader`, `listFooter`, `empty`, `typingIndicator`, `errorBar`,
`jumpToLatest`, `sessionTile`, `modelTile`, and the markdown hooks `codeBlock`,
`latex`, `link`, `image`, `highlight`, `sourceTag`, `genUi`.

`answerAbove` and `answerBelow` are **lists**, in order — that is where sources,
tool output, media or citations go without touching the answer itself.

### Level 4 — no `GptChat` at all

```dart
ChatScope(
  controller: myController,
  theme: ChatTheme.of(context),
  child: MyCompletelyOwnPage(),   // uses ChatTranscript, ChatComposer, … à la carte
)
```

---

## 3. When the app already owns its state

`StreamingChatAdapter` owns the conversation. If your app already has a chat view
model, use cases and persistence, do **not** hand that over — implement
`ChatAdapter` directly and project what you have.

```dart
class MyAdapter extends ChatAdapter {
  MyAdapter(this._vm) { _vm.addListener(notifyListeners); }
  final MyChatViewModel _vm;

  @override
  ChatSnapshot get snapshot => ChatSnapshot(
    messages: _vm.messages,           // your type, implementing ChatMessage
    isResponding: _vm.isStreaming,
  );

  @override
  ChatCapabilities get capabilities =>
      const ChatCapabilities(sessions: false, attachments: true);

  @override
  Future<void> send(ChatDraft draft) => _vm.ask(draft.text, draft.attachments);

  @override
  Future<void> stop() async => _vm.cancel();

  @override
  Future<void> retryLast() => _vm.retry();
}
```

Call `notifyListeners()` when the *shape* changes — a message added or removed,
the session switched, the responding flag flipped. Token-level updates inside one
message do not need it if the message is itself a `Listenable`; see §5.

### `ChatCapabilities` decides the chrome

The screen adapts to the adapter, not to flags at the call site.

`sessions`, `sessionPaging`, `deleteSessions`, `renameSessions`, `models`,
`stop`, `retry`, `attachments`, `tools`, `suggestions`.
`ChatCapabilities.minimal` turns everything off but sending.

Two of these are advisory: `attachments` gates the staged-attachment strip but
the attach button is yours (the package ships no picker — use `ChatAttachButton`
in `composerLeading`), and `tools` gates nothing package-side; read it in your own
`composerLeading` and drive `ChatController.setTool`.

---

## 4. Your own message type

`ChatMessage` is an **interface**, not a base class, so your model keeps its
shape:

```dart
abstract interface class ChatMessage {
  String get id;
  ChatRole get role;
  String get content;
  DateTime get createdAt;
  ChatMessageStatus get status;   // sending | streaming | done | error
  String? get error;
}
```

Implement it on your type, or wrap your type if the names collide — a model with
its own `String role` or `String status` cannot implement this directly, and a
small wrapper forwarding `addListener` is the clean way out.

`SimpleChatMessage` is the package's own implementation, for hosts with nothing
extra to carry.

### Streaming a rich model through `StreamingChatAdapter`

If you use `StreamingChatAdapter` *and* want your own message type, override two
hooks:

```dart
@override
ChatMessage newMessage({required ChatRole role, required String content, ...}) =>
    MyMessage(...);

@override
ChatMessage updateMessage(ChatMessage m, {String? content, ChatMessageStatus? status, String? error}) {
  (m as MyMessage).update(content: content, status: status, error: error);
  return m;                       // mutable models may return the same instance
}
```

Forgetting `updateMessage` fails loudly at send time in debug, not silently
inside the stream.

For chunks that carry more than prose, put it on the delta and route it:

```dart
yield ChatDelta.data(mySourcesChunk);           // or ChatDelta(text, payload: …)

@override
ChatMessage applyDelta(ChatMessage reply, ChatDelta delta, String buffered) {
  if (delta.payload is MyChunk) (reply as MyMessage).sources = …;
  return super.applyDelta(reply, delta, buffered);
}
```

---

## 5. Streaming performance

The transcript wraps each message in a `ListenableBuilder` when the message *is*
a `Listenable`. A `ChangeNotifier`-based model therefore repaints **one bubble**
per token instead of the whole list, for free.

Immutable messages that are observable some other way can override
`ChatAdapter.messageListenable(String id)`. Return null to fall back to
whole-list rebuilds.

---

## 6. Scrolling

The transcript follows new content and **yields the moment the user scrolls up**;
`ChatJumpToLatest` brings them back. Scrolling is never disabled to achieve this.

If your app already drives the transcript — its own `scrollToBottom`, its own
`ScrollController` — turn the package's following off, or two things will fight
over one controller:

```dart
ChatController(
  adapter: adapter,
  scrollController: myExistingController,
  followLatest: false,
)
```

Pass that controller to `GptChat(controller: …)`.

---

## 7. Gotchas worth reading before you integrate

**Overriding a container silently orphans its parts.** If you override `scaffold`
and never mount `s.errorBar`, the error banner does not exist. If you override
`answer` and ignore `s.text`, the body does not render. That is usually what you
want — but nothing warns you, so re-read your overrides when something is
missing.

**The awaiting-first-token window is real.** Between a send and the first token
there is a state where the answer has no content. The default draws typing dots;
if you override `answer`, *your* widget renders throughout that window, so it
must handle empty content.

**Metrics before structure.** If you find yourself overriding `messageList` just
to change physics or padding, use `ChatTheme.scrollPhysics` /
`ChatTheme.transcriptPadding` instead.

**Migrating an existing chat page?** Budget for proving equivalence, not for
writing the integration. The code is quick; the behavioural differences — scroll
ownership, layout maths, what renders before the first token — are what take the
time, and none of them show up in a compiler error.

---

## 8. Using the Plusfinity Gateway

```dart
import 'package:gpt_markdown/gpt_chat_gateway.dart';

GatewayChat(config: PlusfinityConfig(apiKey: 'plus_live_…'))
```

`GatewayChat` is `GptChat` plus a prebuilt adapter, the model list and the
animation cards. `theme`, `builders` and everything above work identically,
because it *is* `GptChat` underneath.

`/chat/completions` blocks browsers by design — on Flutter web, point
`PlusfinityConfig.baseUrl` at your own server-side proxy so the key never ships
in a bundle.

---

## Reference

| Type | Role |
|---|---|
| `GptChat` | The screen |
| `ChatAdapter` | Where the conversation comes from |
| `StreamingChatAdapter` | Adapter that owns state, given one `streamReply` |
| `ChatController` | State + actions; what every slot carries |
| `ChatBuilders` / `ChatSlot` | Per-part overrides |
| `ChatTheme` | Every visual constant |
| `ChatCapabilities` | Which chrome to show |
| `ChatSnapshot` | The immutable picture the UI renders |
| `ChatMessage` / `SimpleChatMessage` | The message interface and its default |
| `ChatDraft` / `ChatAttachment` | What the composer sends |
| `ChatDelta` | One slice of a streamed reply |
| `ChatModelSource` | Model list and current choice |

Design rationale, and the record of migrating a large existing app onto this,
is in [`chat_adapter_plan.md`](chat_adapter_plan.md).
