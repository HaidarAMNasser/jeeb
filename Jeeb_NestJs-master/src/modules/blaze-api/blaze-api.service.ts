import { Injectable, Logger } from '@nestjs/common';
import { OpenAI } from 'openai';
import { blazeConfig } from '../../config/blaze.config';

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant' | 'tool';
  content: string | null;
  tool_call_id?: string;
  tool_calls?: any[];
}

export interface ChatCompletionOptions {
  model?: string;
  maxTokens?: number;
  temperature?: number;
  stream?: boolean;
  tools?: any[];
}

export interface ToolCall {
  id: string;
  type: string;
  function: {
    name: string;
    arguments: string;
  };
}

@Injectable()
export class BlazeApiService {
  private readonly client: OpenAI | null;
  private readonly logger = new Logger(BlazeApiService.name);

  constructor() {
    const config = blazeConfig();

    if (!config.apiKey) {
      this.logger.warn(
        'BlazeAPI key not configured. Please set BLAZE_API_KEY in your environment variables.',
      );
      this.client = null;
      return;
    }

    this.client = new OpenAI({
      baseURL: config.baseUrl,
      apiKey: config.apiKey,
    });
  }

  private getClient(): OpenAI {
    if (!this.client) {
      throw new Error(
        'BlazeAPI client not initialized. Please configure BLAZE_API_KEY.',
      );
    }
    return this.client;
  }

  async createChatCompletion(
    messages: ChatMessage[],
    options: ChatCompletionOptions = {},
  ) {
    try {
      const {
        model = 'anthropic/claude-sonnet-4-6',
        maxTokens = 1024,
        temperature = 0.7,
        stream = false,
        tools = undefined,
      } = options;

      const params: any = {
        model,
        messages,
        max_tokens: maxTokens,
        temperature,
        stream,
      };

      if (tools && tools.length > 0) {
        params.tools = tools;
      }

      if (stream) {
        return this.getClient().chat.completions.create(params);
      }

      const response = await this.getClient().chat.completions.create(params);
      return response;
    } catch (error) {
      this.logger.error('Error creating chat completion:', error);
      throw error;
    }
  }

  async createStreamingChatCompletion(
    messages: ChatMessage[],
    options: Omit<ChatCompletionOptions, 'stream'> = {},
  ) {
    return this.createChatCompletion(messages, { ...options, stream: true });
  }

  async listModels() {
    try {
      const response = await this.getClient().models.list();
      return response;
    } catch (error) {
      this.logger.error('Error listing models:', error);
      throw error;
    }
  }

  async createChatCompletionWithTools(
    messages: ChatMessage[],
    tools: any[],
    options: Omit<ChatCompletionOptions, 'tools'> = {},
  ) {
    return this.createChatCompletion(messages, { ...options, tools });
  }

  async handleToolCalls(response: any): Promise<ToolCall[]> {
    const toolCalls: ToolCall[] = [];

    if (response.choices && response.choices[0]?.message?.tool_calls) {
      for (const toolCall of response.choices[0].message.tool_calls) {
        toolCalls.push({
          id: toolCall.id,
          type: toolCall.type,
          function: {
            name: toolCall.function.name,
            arguments: toolCall.function.arguments,
          },
        });
      }
    }

    return toolCalls;
  }

  async createMessageWithToolResult(
    messages: ChatMessage[],
    toolCall: ToolCall,
    toolResult: any,
    options: ChatCompletionOptions = {},
  ) {
    const newMessages = [
      ...messages,
      {
        role: 'assistant' as const,
        content: null,
        tool_calls: [
          {
            id: toolCall.id,
            type: toolCall.type,
            function: {
              name: toolCall.function.name,
              arguments: toolCall.function.arguments,
            },
          },
        ],
      },
      {
        role: 'tool' as const,
        tool_call_id: toolCall.id,
        content: JSON.stringify(toolResult),
      },
    ];

    return this.createChatCompletion(newMessages, options);
  }
}
