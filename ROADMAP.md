# Alarmin Roadmap

This document describes the planned implementation of the alarm, calendar, timer, stopwatch, and settings features.

## Confirmed Product Decisions

- Use the device's local timezone for alarm recurrence. Store the recurrence rule separately from the next calculated occurrence; timezone migration support is out of scope for the first version.
- A one-time alarm with `deleteAfterUse` enabled is deleted only after it has been dismissed, not immediately after it fires.
- Reincarnation begins only after the first snooze. This trigger policy is fixed and is not user-configurable.
- Categories are user-editable and deletable. Deleting a category leaves its alarms intact and clears their `categoryId`.
- Saved stopwatch sessions cannot be edited; they can only be deleted.
- Timer state and an in-progress stopwatch do not survive an app restart. Saved completed stopwatch history does survive.

The remaining product behavior should follow the defaults defined in this roadmap unless a later decision changes it.

## Recommended Architecture

Use a layered local-first architecture:

```text
Screens/widgets
    -> Riverpod providers and controllers
        -> repositories
            -> local database and alarm scheduler adapter
```

The UI should not call the database or the native alarm package directly. Repositories own persistence, while a scheduler service translates an enabled `AlarmModel` into native scheduled alarms. Providers expose streams or state notifiers so a change made on one screen is reflected on every other screen.

Suggested folders after implementation:

```text
lib/
  app/
    app.dart
    providers.dart
    theme.dart
  core/
    time/
    result/
  data/
    database/
    models/
    repositories/
    services/
  features/
    alarms/
    calendar/
    timer/
    stopwatch/
    settings/
  main.dart
```

## 1. Data Architecture

### Alarm

An alarm needs both its user-facing configuration and enough recurrence information to calculate the next occurrence. Do not store recurrence as a display string such as `Every Monday`; store normalized fields and derive the label in the UI.

Proposed fields:

| Field | Type | Purpose |
| --- | --- | --- |
| `id` | `String` or database id | Stable identity for editing, deleting, and rescheduling |
| `title` | `String` | User-visible alarm title |
| `categoryId` | `String?` | Reference to a category; nullable for uncategorized alarms |
| `timeOfDay` | minutes since midnight | Daily firing time without duplicating a date |
| `scheduleType` | enum | `once`, `daily`, `weekly`, or `intervalDays` |
| `scheduledDate` | local date nullable | Required for a one-time alarm |
| `daysOfWeek` | set/list of weekday values | Required for weekly schedules, such as Monday and Wednesday |
| `intervalDays` | integer nullable | Required for schedules such as every 2 days |
| `scheduleStartDate` | local date nullable | Anchor date for recurring interval schedules |
| `scheduleEndDate` | local date nullable | Optional recurrence end date |
| `isEnabled` | boolean | Whether the alarm is active and scheduled |
| `deleteAfterUse` | boolean | Whether a one-time alarm is removed after its completion policy is met |
| `ringtone` | string | Built-in ringtone id or local asset identifier, not a display label |
| `vibration` | boolean or enum | Whether and how vibration is used |
| `snoozeDuration` | duration | Duration of one ordinary snooze |
| `reincarnationCount` | integer | Maximum additional firings after the first snooze; the trigger itself is not configurable |
| `reincarnationInterval` | duration | Delay between reincarnated firings |
| `createdAt` | timestamp | Audit and sorting support |
| `updatedAt` | timestamp | Detect changes that require rescheduling |
| `nextOccurrenceAt` | timestamp nullable | Cached next firing for list/calendar queries; recomputed from the schedule |

Use a recurrence value object or separate recurrence table if the selected database favors normalization. `daysOfWeek` must be stored in a queryable form, such as a child table or serialized list supported by the database, rather than as a localized string. Calculate occurrences in the device's local timezone and handle daylight-saving transitions with an explicit test policy; do not convert recurring wall-clock times into fixed UTC timestamps.

#### Reincarnation runtime state

Keep configuration on the alarm, but keep an active firing chain separate from the saved schedule. A runtime record should contain:

- `id`
- `alarmId`
- `originOccurrenceAt`
- `remainingCount`
- `nextFireAt`
- `status`: `active`, `completed`, `cancelled`

This prevents a snooze from corrupting the recurring alarm definition. The runtime chain is created only when the first snooze action occurs, and its trigger rule is fixed rather than configurable. Every scheduled native alarm must have an app-owned identifier so cancellation and rescheduling are deterministic.

### Category

Use a separate category entity rather than storing emoji directly on every alarm:

| Field | Type | Purpose |
| --- | --- | --- |
| `id` | `String` or database id | Stable category reference |
| `name` | `String` | Category label used for grouping |
| `emoji` | `String` | User-selected emoji displayed with the category/alarm |
| `createdAt` | timestamp | Ordering and auditing |
| `updatedAt` | timestamp | Detect edits |

When a category is deleted, keep all alarms and set their `categoryId` to null. Category edits update the shared category record, so grouped alarms and calendar data receive the change without rewriting alarm records.

### Stopwatch session

Represent a stopwatch run as one session with ordered laps. Store elapsed values as integer milliseconds so calculations are deterministic and independent of wall-clock changes.

`StopwatchSession` fields:

- `id`
- `startedAt` timestamp
- `endedAt` timestamp nullable while running
- `totalTimeMs`
- `status`: `running`, `paused`, `completed`, `discarded`
- `createdAt` timestamp

`StopwatchLap` fields:

- `id`
- `sessionId`
- `sequence`
- `elapsedAtLapMs`: total elapsed time when the lap was flagged
- `lapDurationMs`: duration since the previous lap or session start
- `recordedAt` timestamp

The live stopwatch remains in memory while active and is intentionally discarded on app restart. Save a completed session and its laps transactionally; only completed sessions are part of persistent history.

### Stopwatch history

History is the list of completed `StopwatchSession` records, sorted by `startedAt` descending. It should support:

- opening a session to inspect laps;
- deleting a session or clearing history with confirmation;
- excluding discarded sessions from normal history.

Saved sessions are read-only. There is no edit workflow.

### Settings

Store lightweight preferences separately from domain records:

- `timePickerStyle`: `materialClock` or `cupertinoWheel`;
- `isGroupedView`: default alarm list presentation;
- optional default ringtone;
- optional default vibration behavior;
- optional default snooze duration.

A settings repository should expose typed values, so screens do not depend on raw preference keys.

## 2. Required Flutter Packages

### Initial package set

| Package | Decision | Use |
| --- | --- | --- |
| `alarm` | Recommended | Native alarm scheduling, background delivery, ringtone, and vibration integration. Wrap it behind an `AlarmScheduler` service so package APIs do not leak into feature code. Verify Android/iOS support and lifecycle behavior before committing to it. |
| `flutter_riverpod` | Recommended | App-wide state and dependency injection. Providers can expose alarm/category streams, settings, calendar events, and stopwatch state consistently across tabs. |
| `table_calendar` | Recommended | Month/week/day calendar presentation and selected-day/event-marker rendering. |
| `shared_preferences` | Recommended | Small settings only, such as time picker style and grouped-view default. |
| `drift` | Selected | Relational local domain persistence for alarms, categories, recurrence data, and stopwatch history. |
| `intl` | Recommended | Localized date/time formatting and weekday labels. |

### Database choice

For the first version, use **Drift**. The project needs relational constraints, migrations, and reliable joins between alarms, categories, recurrence data, and stopwatch history. Drift also keeps the persistence contract explicit while the UI and provider layers are developed incrementally.

Drift compatibility has been verified against Flutter 3.47.5 and Dart 3.13.4, and the initial schema is implemented. The alarm scheduler remains a separate concern regardless of database choice.

### Packages to defer until needed

- `permission_handler` only if platform permission flows cannot be handled by `alarm`.
- `timezone` if the scheduler must explicitly calculate across timezones or daylight-saving transitions.
- `audio_session` or a dedicated audio package only if `alarm` cannot provide the required ringtone behavior.
- `freezed` and `json_serializable` if immutable models, unions, or serialization volume justify code generation.

Avoid adding packages for UI controls that Flutter already provides: `showTimePicker`, `CupertinoTimerPicker`, `CupertinoDatePicker`, `Timer`, and `Stopwatch` are built in.

## 3. Screen And Feature Mapping

The existing five-tab shell maps to the following feature work. The original request labels Settings as Screen 4; it is the fifth tab after Stopwatch.

### Screen 1: Alarms

State and behavior:

- `isGroupedView` comes from the settings provider and can be changed locally or persisted as the user's default.
- When false, render a standard `ListView` sorted by the next occurrence, with disabled alarms consistently placed according to the final UX decision.
- When true, group alarms by `categoryId`, resolve category names and emoji, and render category headers with alarms underneath.
- Allow creating, editing, enabling/disabling, deleting, and duplicating alarms.
- The add/edit form must support one-time, daily, weekly, and interval schedules.
- Saving or toggling an alarm writes through the repository and then calls the scheduler service.
- Deleting or disabling an alarm cancels its native schedule and any active reincarnation chain.
- The alarm ringing flow must handle dismiss, snooze, reincarnation count/interval, `deleteAfterUse`, ringtone, and vibration as separate policies. A one-time alarm is removed only after dismissal when `deleteAfterUse` is enabled; reincarnation is created only after the first snooze.

Milestones:

1. [x] Alarm/category models and repositories.
2. [x] Alarm list and grouped list.
3. [x] Add/edit form and recurrence editor.
4. Scheduler adapter and enable/disable synchronization.
5. [x] Ringing, snooze, reincarnation, and delete-after-use service flow.

### Screen 2: Calendar

- Integrate `table_calendar`.
- Add daily and weekly display modes; keep the selected date independent from the currently selected bottom tab.
- Map `AlarmModel` recurrence into an event loader that returns alarms occurring on each date.
- Show markers/dots for dates with scheduled alarms and a list of that day's alarms below the calendar.
- Recompute events when alarms are added, edited, toggled, or deleted.
- Define behavior for recurring alarms across the visible date range rather than loading only `nextOccurrenceAt`.

Milestones:

1. Calendar provider derives occurrences for a bounded visible date range.
2. Event markers and selected-day alarm list.
3. Daily/weekly mode toggle.
4. Shared live updates with the Alarms screen.

### Screen 3: Timer

- Start with Flutter's `CupertinoTimerPicker` or a custom radial dial only if the desired UX requires it.
- Keep timer state in a timer controller with `duration`, `remaining`, `status`, and `startedAt`.
- Define whether timers continue in the background and whether completion uses the same ringtone/vibration preferences as alarms.
- Keep timer state in memory only; an app restart resets an unfinished timer.
- Add start, pause, resume, and reset behavior before adding persistence.

Milestones:

1. Duration picker and countdown display.
2. Start/pause/resume/reset controller.
3. Completion sound/vibration and lifecycle handling.

### Screen 4: Stopwatch

- Use a monotonic elapsed-time source for accuracy; do not calculate elapsed time only from rebuild counts.
- Render a dynamic list of lap checkpoints.
- Support start, pause, resume, flag/lap, and finish/save.
- Allow flagging while paused; preserve the exact elapsed value for that checkpoint.
- The save action writes one session and its laps transactionally to local storage.
- Keep an active session in memory only; an app restart discards it. Completed saved sessions remain available in history.
- Add a history entry point or history view for previously saved sessions.

Milestones:

1. In-memory stopwatch controller and elapsed display.
2. Lap/checkpoint list with paused-state flagging.
3. Save completed session and laps.
4. History list, detail view, delete, and clear-history confirmation.

### Screen 5: Settings

- Render a list of typed settings and toggles overriding global behavior.
- Add the `Time Picker` setting with `materialClock` and `cupertinoWheel` values.
- The add/edit alarm flow reads this setting and launches either `showTimePicker` or `showCupertinoModalPopup` with a `CupertinoDatePicker`.
- Persist changes immediately and make the setting observable by the alarm form.
- Keep feature-specific defaults separate from global settings where possible.

## 4. Implementation Order

1. [x] Select Drift as the local database and verify package/platform compatibility.
2. [x] Add the foundation packages and establish the initial data-layer folders.
3. [x] Implement domain models, recurrence value objects, the initial Drift schema, and repositories.
4. [x] Add the Drift migration strategy and seed default categories/settings. Add future schema-version migrations as the schema evolves.
5. [x] Implement Riverpod providers and repository-backed state streams.
6. [x] Implement alarm persistence/scheduling synchronization service, native scheduler boundary, alarm form, and ring-event rescheduling.
7. [x] Implement Alarms list and grouped view.
8. Implement Calendar occurrence calculation and markers.
9. Implement Settings and connect the time-picker preference to the alarm form.
10. Implement Timer lifecycle behavior with in-memory-only active state.
11. Implement Stopwatch, persistence, and read-only history.
12. Add platform-specific alarm permissions, background behavior, and lifecycle recovery.
13. Add tests and perform manual device validation on Android and iOS where available.

## 5. Testing And Acceptance Gates

### Data and domain tests

- Recurrence produces the correct next occurrence for one-time, daily, weekly, and interval schedules.
- Weekly schedules support multiple weekdays.
- Date boundaries, daylight-saving transitions, and past schedules are handled according to the confirmed timezone policy.
- Reincarnation decrements exactly once per generated firing and stops at zero.
- Reincarnation is not created before the first snooze and uses the fixed trigger policy.
- `deleteAfterUse` removes a one-time alarm after dismissal, not merely after firing.
- Disabling/deleting an alarm cancels its runtime chain.
- Stopwatch lap durations and total time are correct across pauses.

### Repository and state tests

- Alarm/category CRUD persists and reloads correctly.
- A category change updates both grouped alarms and calendar data.
- Settings changes are observable without restarting the app.
- Stopwatch sessions and laps are saved atomically.

### Widget tests

- Alarms list switches between flat and grouped views.
- Toggling an alarm updates its visual state and scheduler command.
- Calendar markers reflect saved alarms.
- Time picker setting opens the correct picker.
- Stopwatch supports flag while paused and saves a session.
- Bottom navigation keeps the five screens reachable.

### Device/integration tests

- A scheduled alarm fires after the app is backgrounded or terminated where platform policy permits.
- Ringtone and vibration settings are honored.
- Snooze and reincarnation schedule the expected next firing.
- App restart resets active timer and stopwatch state while preserving saved alarm and completed stopwatch history.

## 6. Open Risks

- Background alarm behavior, exact ringtone control, and permissions vary by Android and iOS versions; validate the `alarm` package on real devices early.
- Recurrence calculations become incorrect if the model stores only a timestamp. Keep the recurrence rule and the next computed occurrence separate.
- Local-time recurrence must define behavior around daylight-saving gaps and repeated clock times; cover those cases in domain tests.
- Storing the emoji itself is fine for user-selected Unicode emoji, but category identity should remain a stable id so renaming a category does not require rewriting alarms.
- `shared_preferences` is not a domain database. Keep it limited to small preferences.
- Calendar event expansion should be bounded to the visible range to avoid generating an unbounded set of recurring occurrences.
