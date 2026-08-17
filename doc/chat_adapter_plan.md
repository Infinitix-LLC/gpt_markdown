# gpt_chat — adapter + builder plan

Goal: `gpt_markdown/gpt_chat` is the chat UI layer for **any** app. Defaults look
and behave like the ChatGPT app. Plusfinity is customer #1 but nothing
Plusfinity-shaped enters the core.

Decisions locked:

1. **Package owns the shell, host owns the state.** Package owns scaffold,
   transcript, scroll/follow, composer, layout, theming. Host keeps its own state
   behind a `ChatAdapter`.
2. **No generics.** `ChatMessage` is an interface; hosts implement it on their own
   message type and cast in their own builders.
3. **Gateway behind a second entrypoint** in the same package.
4. **Progressive customization, no cliffs** — the governing principle, §4.

---

## 1. Design principles

**P1 — Theme covers the common case.** Colors, radii, spacing, typography, widths,
markdown styling: zero builders.

**P2 — One builder signature.** Every slot is `Widget Function(TSlot slot)`. Learn
it once.

**P3 — No cliffs. Every slot hands down the parts, pre-built.** A slot never gives
only "the default widget" — it gives the *pieces that composed it*. Override the
list and you still get the bubbles. Override the bubble and you still get the
text, the actions, the attachments. Customize 10% or 90%; the cost is
proportional, never a step function. This is the rule the whole API is shaped
around.

**P4 — Flat, prefix-grouped names.** `answerText`, `composerSend`,
`questionAttachments`. Type `answer` in the IDE, see every answer slot. No nested
builder classes to discover first.

**P5 — Every default is an exported widget.** `ChatAnswerText`, `ChatSendButton`,
`ChatSessionTile`. Override = wrap a public widget, or copy 30 readable lines.

**P6 — Defaults are ChatGPT-shaped, not Plusfinity-shaped.** §2.

**P7 — Escape hatch always open.** Ignore `GptChat`, put a `ChatScope` in your own
page, use the exported widgets à la carte.

## 2. Default look (the "ChatGPT schema")

- Centered reading column, `maxWidth` ~760, generous horizontal gutters.
- **User message**: right-aligned, rounded filled bubble, tight to content.
- **Assistant message**: full column width, no bubble, plain markdown body.
- Answer footer row: copy / regenerate / thumbs, revealed on hover or always on
  touch.
- App bar floats over the transcript: menu button, model picker as the title,
  actions on the right.
- Composer floats at the bottom: rounded container, growing multiline field,
  attach button leading, send ⇄ stop trailing.
- Session drawer: search field, grouped list (Today / Yesterday / Previous 7
  days), new-chat button pinned.
- Empty state: centered greeting + suggestion chips.
- Typing state: three-dot pulse where the answer will appear.
- Streaming: token-level updates, auto-follow that yields the moment the user
  scrolls up, "jump to latest" pill while scrolled away.

## 3. Message interface

Package `ChatMessage` is immutable; Plusfinity's is a mutable `ChangeNotifier`.
No concrete class is both, so the seam is an interface:

```dart
abstract interface class ChatMessage {
  String get id;
  ChatRole get role;
  String get content;
  DateTime get createdAt;
  ChatMessageStatus get status;   // sending | streaming | done | error
  String? get error;
}

/// The package's own implementation, and the one StreamingChatAdapter uses.
final class SimpleChatMessage implements ChatMessage { … copyWith … }
```

Host implements it on its own type. One extension kills the casts:

```dart
extension PfSlot on ChatMessageSlot {
  PfMessage get msg => message as PfMessage;
}
// answerText: (s) => Text(s.msg.thoughts)
```

### Streaming rebuilds

Transcript wraps each item in a `ListenableBuilder` when the message *is* a
`Listenable`. Hosts whose messages are `ChangeNotifier`s get per-message rebuilds
for free. Adapters whose messages are immutable can override
`Listenable? messageListenable(String id)`. Structural change (message added,
session switched) still goes through the adapter's own `notifyListeners`.

## 4. Slot system

### One signature

```dart
typedef ChatBuild<S extends ChatSlot> = Widget Function(S slot);
```

### Base slot

```dart
class ChatSlot {
  final BuildContext context;
  final ChatController controller;
  final Widget child;      // the fully assembled default — always present
}
```

`child` handles "decorate". The subtypes below handle "recompose" — each carries
the pieces that produced `child`, already built. **That is P3.**

### Slot types

```dart
class ChatScaffoldSlot extends ChatSlot {
  Widget appBar, background, body, composer, errorBar, jumpToLatest;
  Widget? drawer;
}

class ChatBodySlot extends ChatSlot {
  Widget list, empty;
  bool isEmpty;
}

class ChatListSlot extends ChatSlot {
  List<ChatMessagePair> pairs;
  int get count;
  Widget item(int index);            // ← the built pair, yours to place
  ScrollController scrollController;
  Widget header, footer;
  bool Function(ScrollNotification) onScroll;
}

class ChatPairSlot extends ChatSlot {
  ChatMessagePair pair; int index; bool isLast;
  Widget question, answer, separator;
}

class ChatMessageSlot extends ChatSlot {
  ChatMessage message; bool isLast;
  Widget text, attachments, actions;
}

class ChatAnswerSlot extends ChatMessageSlot {
  Widget status, reasoning, error;
  List<Widget> above, below;         // host sections, already built & ordered
}

class ChatComposerSlot extends ChatSlot {
  Widget field, send, stop, attachments, suggestions, above;
  List<Widget> leading, trailing;    // attach, tools, mic …
  bool canSend, isResponding;
}

class ChatAppBarSlot extends ChatSlot {
  Widget leading, title, subtitle, modelSelector;
  List<Widget> actions;
}

class ChatDrawerSlot extends ChatSlot {
  List<ChatSession> sessions;
  Widget tile(int index);
  Widget header, footer, newSessionButton, list, loadMore;
}

class ChatSessionSlot extends ChatSlot { ChatSession session; bool isActive; }
class ChatModelSlot   extends ChatSlot { ChatModelOption model; bool isSelected; }
class ChatErrorSlot   extends ChatSlot { String message; }
class ChatIndexSlot   extends ChatSlot { int index; }
class ChatAttachSlot  extends ChatSlot { ChatAttachment attachment; int index; }
```

Hiding anything = return `const SizedBox.shrink()`. No nullable-return rule.

### The slot list (~32, flat)

```dart
ChatBuilders(
  // frame
  scaffold,            // ChatScaffoldSlot
  background, loading, jumpToLatest,   // ChatSlot
  errorBar,            // ChatErrorSlot

  // app bar
  appBar,              // ChatAppBarSlot
  appBarTitle, appBarLeading,          // ChatSlot
  modelSelector,       // ChatSlot
  modelTile,           // ChatModelSlot

  // drawer
  drawer,              // ChatDrawerSlot
  drawerHeader, drawerFooter, newSessionButton,   // ChatSlot
  sessionTile,         // ChatSessionSlot

  // transcript
  body,                // ChatBodySlot
  messageList,         // ChatListSlot
  pair,                // ChatPairSlot
  separator,           // ChatIndexSlot
  listHeader, listFooter, empty, typingIndicator, // ChatSlot

  // question
  question, questionText, questionAttachments, questionActions,  // ChatMessageSlot
  questionAttachmentTile,              // ChatAttachSlot

  // answer
  answer,                              // ChatAnswerSlot
  answerText, answerStatus, answerReasoning,
  answerAttachments, answerError, answerActions,  // ChatMessageSlot
  answerAbove, answerBelow,            // List<ChatBuild<ChatMessageSlot>>

  // composer
  composer,                            // ChatComposerSlot
  composerField, composerSend, composerStop,
  composerAttachments, composerSuggestions, composerAbove,  // ChatSlot
  composerLeading, composerTrailing,   // List<ChatBuild<ChatSlot>>
  composerAttachmentTile,              // ChatAttachSlot

  // markdown content
  codeBlock, latex, link, image,       // content slots
)
```

`copyWith` + `merge` on the flat class. No nested group constructors.

### Progressive path, concretely

```dart
// 0% — theme only
GptChat(adapter: a, theme: ChatTheme(userBubble: …, radius: 20))

// 10% — one leaf
ChatBuilders(composerSend: (s) => MySend(onTap: s.controller.onSend))

// 30% — recompose the answer, keep every part
ChatBuilders(answer: (s) => Column(children: [...s.above, s.text, MyCite(), s.actions]))

// 50% — own list, package bubbles
ChatBuilders(messageList: (s) => AnimatedList(
  controller: s.scrollController, itemBuilder: (_, i, __) => s.item(i)))

// 80% — own shell, package everything inside
ChatBuilders(scaffold: (s) => MyShell(bar: s.appBar, body: s.body, input: s.composer))

// 100% — no GptChat at all
ChatScope(adapter: a, child: MyCompletelyOwnPage())
```

## 5. ChatAdapter

```dart
abstract class ChatAdapter extends ChangeNotifier {
  ChatSnapshot get snapshot;          // sessions, activeSessionId, messages,
                                      // isLoading, isResponding, error
  ChatCapabilities get capabilities;  // which chrome to show

  Future<void> send(ChatDraft draft);
  Future<void> stop();
  Future<void> retryLast();
  Future<void> newSession();
  Future<void> selectSession(String id);
  Future<void> deleteSession(String id);
  Future<void> loadMoreSessions() async {}
  void clearError();

  Listenable? messageListenable(String id) => null;
}
```

- `ChatDraft` = `{ String text, List<ChatAttachment> attachments, Object? tool }`.
- `ChatAttachment` = `{ id, kind, name, uri, Object? payload }` — carries a host's
  images/materials without the package knowing their types.
- `ChatCapabilities` = `{ sessions, sessionPaging, delete, models, stop, retry,
  attachments, tools, suggestions }` — replaces `showSessions` /
  `showModelSelector`; chrome follows the adapter, not the call site.

**`StreamingChatAdapter`** — package base implementing all of the above on top of
one hook, for hosts with no state layer of their own:

```dart
abstract class StreamingChatAdapter extends ChatAdapter {
  Stream<ChatDelta> streamReply(List<ChatMessage> history);
  ChatSessionStore get store => InMemorySessionStore();
}
```

Today's `ChatViewModel` + `SessionRepository` move inside it unchanged.
`ChatDelta = {String text, List<ValArtifact> artifacts}`.

**`ChatModelSource`** is separate, since not every host has a model list:

```dart
abstract class ChatModelSource extends ChangeNotifier {
  List<ChatModelOption> get models;   // {id, label, description, icon}
  String get selected;
  bool get isLoading;
  Future<void> load();
  void select(String id);
}
```

## 6. ChatController

The single object every slot exposes. Loses state ownership, keeps:

- reads delegated to `adapter.snapshot` (`messages`, `pairs`, `sessions`, `error`)
- `scrollController`, `input`, `inputFocusNode`, `canSend`, `isFollowingLatest`,
  `canJumpToLatest`, `onScrollNotification`, `scrollToLatest`
- actions (`onSend` builds the `ChatDraft`, `onStop`, `onRetry`, …)
- draft state: `attachments`, `selectedTool`, `addAttachment`, `removeAttachment`,
  `setTool`

## 7. ChatTheme

`ThemeExtension<ChatTheme>`: per-role bubble color/radius/padding/alignment,
transcript spacing, max content width, composer decoration and elevation,
typography, action-bar style, plus the `GptMarkdownConfig` used by the answer
body. Must be rich enough that a normal rebrand needs no builders (P1).

## 8. Package layout

```
lib/gpt_chat.dart             # UI + adapter. No http, no gateway, no Plusfinity types.
lib/gpt_chat_gateway.dart     # PlusfinityConfig, GatewayClient, GatewayChatAdapter,
                              # ArtifactRepository, ModelRepository
lib/gpt_chat/src/
  adapter/     chat_adapter.dart, streaming_chat_adapter.dart, chat_snapshot.dart,
               chat_capabilities.dart, chat_draft.dart, chat_message.dart,
               chat_model_source.dart, session_store.dart
  controller/  chat_controller.dart, chat_message_pair.dart
  theme/       chat_theme.dart
  builders/    chat_builders.dart, chat_slots.dart
  widgets/     defaults, each one public and exported
  gateway/     today's data/, gateway-only parts
```

```dart
GptChat({required ChatAdapter adapter, ChatModelSource? models,
         ChatBuilders builders, ChatTheme? theme, GenUiRegistry? genUi})
GptChat.gateway({required PlusfinityConfig config, …})   // today's behaviour
```

## 9. Phases

1. ~~**Package refactor.**~~ **Done.** Interface, adapter, slot system, theme,
   entrypoint split, redrawn defaults. `GptChat(config:)` became
   `GatewayChat(config:)`. `flutter analyze` clean, 353 tests green.
2. ~~**Plusfinity adapter.**~~ **Done.** `PlusfinityChatAdapter` projects
   `ChatSessionViewModel`; `PfChatMessage` presents our message to the package.
   `SessionAppBar`, `SessionTextField`, `QuestionMessage` and `AnswerMessage`
   are dropped into slots unchanged.

   One deviation from §3: the host does **not** implement `ChatMessage` on its
   own type. Plusfinity's `ChatMessage` already has a `role` (a `String`) and a
   `status` (the analysing label), and both collide with the interface. A
   wrapper was the only option, and it still forwards `addListener` so
   per-bubble streaming repaints work.

3. ~~**Consolidate.**~~ **Done as far as the flag allows.** The generic shell
   already moved in phase 1; the dead duplicate in `_SessionBodyState` is gone
   and `SessionBody` is marked fallback-only. Deleting it outright is step 4's
   business — see the checklist in plusfinity's `MIGRATION.md`.

4. ~~**Cutover.**~~ **Done.** `GptChatSessionPage` is a drop-in replacement for
   `ChatSessionPage`, and the five call sites name it instead. The old page and
   body are untouched and stay as the reference for one release, as planned —
   reverting is a find-and-replace.

### Verified in the running app (2026-08-14)

Driven over CDP against the real signed-in web build:

- The session screen renders through the package shell — question bubble,
  `AnswerMessage` with its actions bar and related questions, composer, app bar.
- Three sends went host composer → `askQuestion` → stream → transcript, with
  markdown lists rendering.
- **Anchoring works**: the newest exchange pins to the top of the viewport with
  the answer growing beneath it.
- Model picker opens, selects, and persists.

Also checked at a phone viewport (390x844): app bar, bubble, actions row,
composer and the anchoring all hold.

**One open observation.** With the viewport squeezed to 380px so the
conversation overflowed, the transcript held where a wheel scroll left it, then
drifted back toward the latest a few seconds later with no input. The package
is not the cause — `test/gpt_chat/chat_scroll_test.dart` pins the rule that a
wheel scroll disarms following and that an adapter notify does not move the
viewport. The likely candidates are app-side: `sessionVm.scrollToBottom`, or an
`AnimatedSize` section changing the extent under a position already at the end.
Worth characterising on a genuinely long conversation.

## 9b. Can the package own state for a Plusfinity-shaped app?

It can now, though Plusfinity itself still shouldn't — its state layer already
exists and works. What changed is that the three blockers are gone:

| Was | Now |
| --- | --- |
| `newMessage` returned `SimpleChatMessage`, so a host model could not exist | Returns `ChatMessage`; override `updateMessage` and your own type flows through |
| `ChatDelta` was text-only | `ChatDelta.payload` + `applyDelta` route structured chunks into your fields |
| Metrics forced a `messageList` override | `ChatTheme.scrollPhysics`, `ChatTheme.transcriptPadding` |

Persistence is still whole-session (`ChatSessionStore.save`). A host with
per-message or paginated writes should keep owning its own state and implement
`ChatAdapter` directly, as Plusfinity does.

## 10. Open items

- **Threads vs sessions.** Plusfinity threads are paginated Firebase docs.
  `loadMoreSessions` + `capabilities.sessionPaging` cover the list; the drawer
  still needs loading / end-of-list states.
- **Artifacts / gen-UI.** `ChatDelta.artifacts` decouples the stream, but
  `ArtifactViewModel` stays in the gateway half. Plusfinity likely renders its own
  via an `answerBelow` section.
- **Error surface.** Plusfinity splits `hasError` / `limitReached` / `tokensLimit`;
  package has one `error`. Leaning: keep one, host owns the section.
- **Jaspr.** Keep adapter/snapshot/message types free of `dart:ui` so
  `gpt_markdown_jaspr` can reuse them later.
- **Answer ratings.** The default action row is copy + regenerate. Thumbs
  up/down needs a feedback channel the adapter does not have; a host adds it
  today through the `answerActions` slot. Add `ChatAdapter.rate` if a second
  customer wants it.
- **Versioning.** Git dep used by `ui_shared`, `ui_mobile`, `ui_desktop`,
  `ui_adaptive`. Phase 1 is breaking → tag and bump all four together.
