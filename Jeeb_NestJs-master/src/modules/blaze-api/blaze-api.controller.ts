import {
  Controller,
  Post,
  Get,
  Body,
  Logger,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { BlazeApiService, ChatMessage } from './blaze-api.service';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';

@ApiTags('BlazeAPI')
@Controller('blaze-api')
export class BlazeApiController {
  private readonly logger = new Logger(BlazeApiController.name);

  constructor(private readonly blazeApiService: BlazeApiService) {}

  @Post('chat')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Create chat completion' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        messages: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              role: { type: 'string', enum: ['system', 'user', 'assistant'] },
              content: { type: 'string' },
            },
          },
        },
        model: { type: 'string', default: 'anthropic/claude-sonnet-4-6' },
        maxTokens: { type: 'number', default: 1024 },
        temperature: { type: 'number', default: 0.7 },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Chat completion created successfully',
  })
  async createChatCompletion(
    @Body()
    body: {
      messages: ChatMessage[];
      model?: string;
      maxTokens?: number;
      temperature?: number;
    },
  ) {
    try {
      const { messages, model, maxTokens, temperature } = body;
      const response = await this.blazeApiService.createChatCompletion(
        messages,
        {
          model,
          maxTokens,
          temperature,
        },
      );

      return {
        success: true,
        data: response,
      };
    } catch (error) {
      this.logger.error('Chat completion error:', error);
      return {
        success: false,
        error: error.message || 'Failed to create chat completion',
      };
    }
  }

  @Post('chat/tools')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Create chat completion with tools' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        messages: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              role: { type: 'string', enum: ['system', 'user', 'assistant'] },
              content: { type: 'string' },
            },
          },
        },
        tools: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              type: { type: 'string' },
              function: {
                type: 'object',
                properties: {
                  name: { type: 'string' },
                  description: { type: 'string' },
                  parameters: { type: 'object' },
                },
              },
            },
          },
        },
        model: { type: 'string' },
        maxTokens: { type: 'number' },
        temperature: { type: 'number' },
      },
    },
  })
  async createChatCompletionWithTools(
    @Body()
    body: {
      messages: ChatMessage[];
      tools: any[];
      model?: string;
      maxTokens?: number;
      temperature?: number;
    },
  ) {
    try {
      const { messages, tools, model, maxTokens, temperature } = body;
      const response = await this.blazeApiService.createChatCompletionWithTools(
        messages,
        tools,
        { model, maxTokens, temperature },
      );

      return {
        success: true,
        data: response,
      };
    } catch (error) {
      this.logger.error('Chat completion with tools error:', error);
      return {
        success: false,
        error: error.message || 'Failed to create chat completion with tools',
      };
    }
  }

  @Get('models')
  @ApiOperation({ summary: 'List available models' })
  @ApiResponse({ status: 200, description: 'Models retrieved successfully' })
  async listModels() {
    try {
      const models = await this.blazeApiService.listModels();
      return {
        success: true,
        data: models,
      };
    } catch (error) {
      this.logger.error('List models error:', error);
      return {
        success: false,
        error: error.message || 'Failed to list models',
      };
    }
  }

  @Post('chat/stream')
  @ApiOperation({ summary: 'Create streaming chat completion' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        messages: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              role: { type: 'string', enum: ['system', 'user', 'assistant'] },
              content: { type: 'string' },
            },
          },
        },
        model: { type: 'string' },
        maxTokens: { type: 'number' },
        temperature: { type: 'number' },
      },
    },
  })
  async createStreamingChatCompletion(
    @Body()
    body: {
      messages: ChatMessage[];
      model?: string;
      maxTokens?: number;
      temperature?: number;
    },
  ) {
    try {
      const { messages, model, maxTokens, temperature } = body;
      const stream = await this.blazeApiService.createStreamingChatCompletion(
        messages,
        {
          model,
          maxTokens,
          temperature,
        },
      );

      return {
        success: true,
        data: stream,
      };
    } catch (error) {
      this.logger.error('Streaming chat completion error:', error);
      return {
        success: false,
        error: error.message || 'Failed to create streaming chat completion',
      };
    }
  }
}
