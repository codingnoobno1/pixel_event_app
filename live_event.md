# Live Event Integration: Flutter & Next.js

This document outlines how "Live Modes" (Quiz, Voting, Treasure Hunt) are managed in the Next.js backend and consumed by the Flutter mobile app.

## 1. Backend Data Structure (Next.js)

The `Event` model in MongoDB contains two critical fields for live interaction:

- `modes`: An array of available interactive modes for the event.
  - `type`: One of `quiz`, `voting`, `treasure-hunt`, or `custom`.
  - `config`: A flexible JSON object containing mode-specific settings (e.g., question timer, voting topics).
- `activeMode`: A string matching one of the `modes.type`. If this is set, the event is considered "Live" in the mobile app.

### Example Event Document:
```json
{
  "_id": "65f...",
  "title": "Annual Tech Symposium",
  "activeMode": "quiz",
  "modes": [
    {
      "type": "quiz",
      "config": {
        "subModes": [
          {"id": "rapid-fire", "name": "Rapid Fire", "description": "10s per question"}
        ]
      }
    }
  ]
}
```

## 2. Flutter Consumption Logic

The Flutter app's `Live Event` tab performs a scan when opened:

1. **Get Registrations**: Calls `GET /api/events/register?email=user@email.com`.
2. **Scan Events**: For each registered event, it calls `GET /api/events/[eventId]`.
3. **Detection**: If `event.activeMode != null`, the app immediately displays the **Live Lobby** for that event.
4. **Resilience**: If an event query fails (404), the app skips it and continues scanning other registrations.

## 3. Implementation of Admin Controls

To make an event live, the Admin must:
1. Create/Update an Event.
2. Add a mode to the `modes` array.
3. Set the `activeMode` field to the desired mode type.

The Next.js `/admin` panel (under development) provides a dedicated "Live Event" tab to toggle these modes in real-time.
