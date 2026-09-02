import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import {
  SendToUserDto,
  SendToAllDto,
  SendToCustomersDto,
  MarkNotificationsReadDto,
} from './dto/send-notification.dto';
import { AuthGuard } from '../../common/guards/auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';
import { NOTIFICATIONS_ROUTES } from '../../common/constants/api-routes.constants';
import { NotificationTopic } from '../../common/enums/notification-topic.enum';
import { NotificationType } from '../../common/enums/notification-type.enum';
import { NotificationChannel } from '../../common/enums/notification-channel.enum';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller(NOTIFICATIONS_ROUTES.BASE)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post(NOTIFICATIONS_ROUTES.SEND_TO_USER)
  @ApiOperation({ summary: 'Send notification to a specific user' })
  @ApiResponse({ status: 200, description: 'Notification sent successfully' })
  async sendToUser(@Body() dto: SendToUserDto) {
    const notification = await this.notificationsService.sendToUser(
      dto.userId,
      dto.type,
      dto.title,
      dto.body,
      dto.channel,
      dto.metadata,
    );
    return { success: true, data: notification };
  }

  @Post(NOTIFICATIONS_ROUTES.SEND_TO_ALL)
  @ApiOperation({ summary: 'Send notification to all users in a topic' })
  @ApiResponse({ status: 200, description: 'Notification sent successfully' })
  async sendToAll(@Body() dto: SendToAllDto) {
    const { notification } = await this.notificationsService.sendToAll(
      dto.topic,
      dto.type,
      dto.title,
      dto.body,
      dto.channel,
      dto.metadata,
      dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
    );
    return { success: true, data: notification };
  }

  @Get()
  @ApiOperation({ summary: 'Get notifications for current user' })
  @ApiResponse({
    status: 200,
    description: 'Notifications retrieved successfully',
  })
  async getNotifications(
    @CurrentUser() user: User,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    const result = await this.notificationsService.getNotificationsForUser(
      user.id,
      page,
      limit,
    );
    return { success: true, ...result };
  }

  @Get(NOTIFICATIONS_ROUTES.GET_ONE)
  @ApiOperation({ summary: 'Get a specific notification' })
  @ApiResponse({
    status: 200,
    description: 'Notification retrieved successfully',
  })
  async getNotification(@Param('id') id: number, @CurrentUser() user: User) {
    const notification = await this.notificationsService.getNotificationById(
      id,
      user.id,
    );
    return { success: true, data: notification };
  }

  @Post(NOTIFICATIONS_ROUTES.SEND_TO_CUSTOMERS)
  @ApiOperation({ summary: 'Send notification to all customers' })
  @ApiResponse({
    status: 200,
    description: 'Notification sent to all customers successfully',
  })
  async sendToCustomers(@Body() dto: SendToCustomersDto) {
    const { notification, totalTargeted, deliveredCount, undeliveredCount } =
      await this.notificationsService.sendToAll(
        NotificationTopic.ALL_CUSTOMERS,
        NotificationType.CUSTOM,
        dto.title,
        dto.body,
        NotificationChannel.FIREBASE,
      );
    return {
      success: true,
      data: {
        id: notification.id,
        channel: notification.channel,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        topic: notification.topic,
        sentAt: notification.sentAt,
        createdAt: notification.createdAt,
        totalTargeted,
        deliveredCount,
        undeliveredCount,
      },
    };
  }

  @Post(NOTIFICATIONS_ROUTES.MARK_READ)
  @ApiOperation({ summary: 'Mark multiple notifications as read' })
  @ApiResponse({ status: 200, description: 'Notifications marked as read' })
  async markAsRead(
    @Body() dto: MarkNotificationsReadDto,
    @CurrentUser() user: User,
  ) {
    await this.notificationsService.markAsRead(dto.notificationIds, user.id);
    return { success: true, message: 'Notifications marked as read' };
  }
}
