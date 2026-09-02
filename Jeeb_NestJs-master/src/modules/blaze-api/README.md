# BlazeAPI Module

This module provides integration with BlazeAPI service for AI chat completions using OpenAI-compatible endpoints.

## Features

- Chat completions with various AI models (OpenAI, Anthropic, etc.)
- Tool calling support
- Streaming responses
- Model listing
- Automatic format conversion between OpenAI and Anthropic formats

## Configuration

Add these environment variables to your `.env` file:

```env
BLAZE_API_KEY=sk-blaze-your-key-here
BLAZE_BASE_URL=https://blazeai.boxu.dev/api/v1
```

## Usage

### Basic Chat Completion

```typescript
import { BlazeApiService } from './blaze-api.service';

// Inject the service
constructor(private readonly blazeApiService: BlazeApiService) {}

// Use it in your methods
async chatWithAI() {
  const messages = [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'Hello!' }
  ];
  
  const response = await this.blazeApiService.createChatCompletion(messages);
  return response.choices[0].message.content;
}
```

### Tool Calling

```typescript
const tools = [{
  type: 'function',
  function: {
    name: 'get_weather',
    description: 'Get the current weather for a location',
    parameters: {
      type: 'object',
      properties: {
        location: {
          type: 'string',
          description: 'City name, e.g. San Francisco'
        }
      },
      required: ['location']
    }
  }
}];

const response = await this.blazeApiService.createChatCompletionWithTools(
  messages, 
  tools
);

// Handle tool calls
const toolCalls = await this.blazeApiService.handleToolCalls(response);
for (const toolCall of toolCalls) {
  console.log(`Function: ${toolCall.function.name}`);
  console.log(`Args: ${toolCall.function.arguments}`);
}
```

### Streaming

```typescript
const stream = await this.blazeApiService.createStreamingChatCompletion(messages);

for await (const chunk of stream) {
  const content = chunk.choices[0]?.delta?.content;
  if (content) {
    process.stdout.write(content);
  }
}
```

## API Endpoints

The module exposes the following HTTP endpoints:

- `POST /blaze-api/chat` - Create chat completion
- `POST /blaze-api/chat/tools` - Create chat completion with tools
- `POST /blaze-api/chat/stream` - Create streaming chat completion
- `GET /blaze-api/models` - List available models

## Available Models

Some popular models available through BlazeAPI:

- `anthropic/claude-sonnet-4-6`
- `gpt-4`
- `gpt-3.5-turbo`
- And many more...

Check `/blaze-api/models` endpoint for the complete list.

## Error Handling

The service includes comprehensive error handling and logging. All errors are logged and re-thrown for proper handling by calling code.
