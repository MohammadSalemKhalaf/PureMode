# AI Chat Assistant API Documentation

## Overview
The AI Chat Assistant provides supportive, non-diagnostic conversational support to users in Arabic and English using OpenAI.

**Important Safety Notes:**
- Never provides medical diagnosis or treatment advice
- Detects crisis keywords and provides immediate emergency support resources
- All responses include disclaimer about general support nature
- Requires user authentication via JWT token

---

## Endpoints

### 1. POST `/api/ai/chat`
Start or continue a chat conversation with the AI assistant.

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "sessionId": "optional_session_id",
  "language": "ar",
  "messages": [
    {"role": "user", "content": "بحس بقلق قبل النوم"}
  ],
  "context": {
    "source_screen": "results",
    "scores": {
      "phq9": 12,
      "gad7": 10,
      "who5": 9
    }
  },
  "consent": true
}
```

**Response:**
```json
{
  "sessionId": 123,
  "reply": "جرّبي تمرين تنفّس 4-7-8 لمدة دقيقتين قبل النوم...",
  "safetyFlags": [],
  "disclaimer": "هذا دعم عام وليس نصيحة طبية. استشر مختصًا للتقييم الدقيق."
}
```

**Notes:**
- If `sessionId` is omitted, creates a new session
- `language` can be `ar` or `en` (default: `ar`)
- `context` is optional but recommended for personalized responses
- `consent` controls whether messages are saved (default: `true`)

---

### 2. GET `/api/ai/sessions`
Retrieve all chat sessions for the authenticated user.

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response:**
```json
{
  "sessions": [
    {
      "session_id": 123,
      "title": "بحس بقلق قبل النوم",
      "language": "ar",
      "created_at": "2024-11-07T18:30:00.000Z",
      "updated_at": "2024-11-07T19:15:00.000Z"
    }
  ]
}
```

---

### 3. GET `/api/ai/sessions/:id/messages`
Retrieve all messages for a specific session.

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response:**
```json
{
  "session": {
    "session_id": 123,
    "title": "بحس بقلق قبل النوم",
    "language": "ar"
  },
  "messages": [
    {
      "message_id": 456,
      "role": "user",
      "content": "بحس بقلق قبل النوم",
      "safety_flags": [],
      "created_at": "2024-11-07T18:30:00.000Z"
    },
    {
      "message_id": 457,
      "role": "assistant",
      "content": "جرّبي تمرين تنفّس 4-7-8...",
      "safety_flags": [],
      "created_at": "2024-11-07T18:30:05.000Z"
    }
  ]
}
```

---

### 4. DELETE `/api/ai/sessions/:id`
Delete a chat session and all its messages (manual delete).

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response:**
```json
{
  "message": "Session deleted successfully"
}
```

---

## Database Schema

### `chat_sessions`
| Column      | Type         | Description                          |
|-------------|--------------|--------------------------------------|
| session_id  | INT          | Primary key, auto-increment          |
| user_id     | INT          | Foreign key to users.user_id         |
| title       | VARCHAR(255) | First message preview                |
| language    | ENUM         | 'ar' or 'en'                         |
| consent     | BOOLEAN      | User consent to save history         |
| archived    | BOOLEAN      | Soft delete flag                     |
| created_at  | DATETIME     | Session creation timestamp           |
| updated_at  | DATETIME     | Last message timestamp               |

### `chat_messages`
| Column       | Type    | Description                          |
|--------------|---------|--------------------------------------|
| message_id   | INT     | Primary key, auto-increment          |
| session_id   | INT     | Foreign key to chat_sessions         |
| role         | ENUM    | 'user', 'assistant', 'system'        |
| content      | TEXT    | Message content                      |
| safety_flags | JSON    | Array of safety warnings             |
| created_at   | DATETIME| Message timestamp                    |

---

## Setup Instructions

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and add your OpenAI API key:
```env
OPENAI_API_KEY=sk-your-openai-api-key-here
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=500
```

### 3. Run Database Migrations
Ensure the new tables are created:
```bash
# Using Sequelize CLI (if configured)
npx sequelize-cli db:migrate

# Or manually create tables using the model definitions
```

### 4. Start Server
```bash
npm run dev
```

---

## Safety Features

### Crisis Detection
The system detects keywords indicating crisis situations:
- Arabic: انتحار, قتل نفسي, إيذاء نفسي, أريد أن أموت, لا أريد العيش
- English: suicide, kill myself, self-harm, want to die, don't want to live

When detected, immediately returns emergency helpline information.

### Guardrails
- System prompts prevent medical diagnosis and treatment advice
- Responses are supportive and general only
- All responses include clear disclaimers
- PII filtering and secure logging (no sensitive data in logs)

---

## Usage Example (Flutter)

```dart
// Start new chat
final response = await http.post(
  Uri.parse('$baseUrl/api/ai/chat'),
  headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
  body: jsonEncode({
    'language': 'ar',
    'messages': [{'role': 'user', 'content': 'نصيحة للاسترخاء؟'}],
    'consent': true
  })
);

// Continue existing chat
final continueResponse = await http.post(
  Uri.parse('$baseUrl/api/ai/chat'),
  headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
  body: jsonEncode({
    'sessionId': 123,
    'language': 'ar',
    'messages': [{'role': 'user', 'content': 'شكراً، في اقتراحات ثانية؟'}]
  })
);

// Load sessions
final sessionsResponse = await http.get(
  Uri.parse('$baseUrl/api/ai/sessions'),
  headers: {'Authorization': 'Bearer $token'}
);

// Delete session
await http.delete(
  Uri.parse('$baseUrl/api/ai/sessions/123'),
  headers: {'Authorization': 'Bearer $token'}
);
```

---

## Troubleshooting

**Error: "OPENAI_API_KEY not configured"**
- Ensure `.env` file exists and contains valid `OPENAI_API_KEY`

**Error: "Chat service unavailable"**
- Check OpenAI API status
- Verify API key is valid and has credits
- Check network connectivity

**High Response Times**
- OpenAI API typically responds in 2-5 seconds
- Consider showing loading indicator in UI
- Adjust `OPENAI_MAX_TOKENS` for faster responses

---

## Future Enhancements
- Streaming responses for real-time display
- Voice input/output support
- Multilingual expansion beyond AR/EN
- Advanced safety classification models
- Analytics dashboard for conversation insights
