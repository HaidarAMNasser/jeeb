import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiProperty,
} from '@nestjs/swagger';
import {
  LoginAttemptService,
  BlockInfo,
} from '../../../common/services/login-attempt.service';
import {
  IPBlockService,
  BlockedIP,
} from '../../../common/services/ip-block.service';
import { SecurityNotificationService } from '../../notifications/security-notification.service';
import { AuthGuard } from '../../../common/guards/auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { UserRole } from '../../../common/enums/user-role.enum';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LoginBlock } from '../../../database/entities/login-block.entity';

class PaginationQueryDto {
  page: number = 1;
  limit: number = 20;
}

class BlockUserDto {
  @ApiProperty({ required: true })
  reason: string;

  @ApiProperty()
  permanent?: boolean;
}

class UnblockDto {
  @ApiProperty()
  note?: string;
}

@ApiTags('Admin Security Management')
@Controller('api/v1/admin/security')
@ApiBearerAuth('JWT-auth')
@UseGuards(AuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminSecurityController {
  constructor(
    private readonly loginAttemptService: LoginAttemptService,
    private readonly ipBlockService: IPBlockService,
    private readonly securityNotificationService: SecurityNotificationService,
    @InjectRepository(LoginBlock)
    private loginBlockRepo: Repository<LoginBlock>,
  ) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get security statistics' })
  async getStats() {
    const activeBlocks = await this.loginAttemptService.getActiveBlocksCount();
    const todayBlocks = await this.loginAttemptService.getTodayBlocksCount();
    const blockedIPs = await this.ipBlockService.getBlockedIPsCount();

    return {
      statusCode: HttpStatus.OK,
      message: 'Security stats retrieved successfully',
      data: {
        activeBlocks,
        todayBlocks,
        blockedIPs,
      },
      timestamp: new Date().toISOString(),
    };
  }

  @Get('blocks')
  @ApiOperation({ summary: 'Get all login blocks' })
  async getBlocks(@Query() query: PaginationQueryDto) {
    const result = await this.loginAttemptService.getActiveBlocks({
      page: query.page,
      limit: query.limit,
    });

    return {
      statusCode: HttpStatus.OK,
      message: 'Blocks retrieved successfully',
      data: result.data,
      meta: {
        page: query.page,
        limit: query.limit,
        total: result.total,
        totalPages: Math.ceil(result.total / query.limit),
      },
      timestamp: new Date().toISOString(),
    };
  }

  @Get('blocks/email/:email')
  @ApiOperation({ summary: 'Get blocks by email' })
  @ApiParam({ name: 'email', description: 'User email' })
  async getBlocksByEmail(@Param('email') email: string) {
    const blocks = await this.loginAttemptService.getBlockHistory(email);

    return {
      statusCode: HttpStatus.OK,
      message: 'User blocks retrieved successfully',
      data: blocks,
      timestamp: new Date().toISOString(),
    };
  }

  @Get('blocks/user/:userId')
  @ApiOperation({ summary: 'Get blocks by user ID' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  async getBlocksByUserId(@Param('userId', ParseIntPipe) userId: number) {
    const blocks = await this.loginBlockRepo.find({
      where: { userId },
      order: { blockedAt: 'DESC' },
    });

    return {
      statusCode: HttpStatus.OK,
      message: 'User blocks retrieved successfully',
      data: blocks,
      timestamp: new Date().toISOString(),
    };
  }

  @Post('blocks/:blockId/unblock')
  @ApiOperation({ summary: 'Unblock a user by block ID' })
  @ApiParam({ name: 'blockId', description: 'Block ID' })
  async unblockUser(
    @Param('blockId', ParseIntPipe) blockId: number,
    @Body() body: UnblockDto,
  ) {
    const block = await this.loginBlockRepo.findOne({
      where: { id: blockId },
    });

    if (!block) {
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: 'Block not found',
        timestamp: new Date().toISOString(),
      };
    }

    await this.loginAttemptService.unblockByEmail(
      block.email,
      block.userId || undefined,
      body.note,
    );

    if (block.userId) {
      await this.securityNotificationService.sendAccountUnlockedNotification(
        block.userId,
      );
    }

    return {
      statusCode: HttpStatus.OK,
      message: 'User unblocked successfully',
      data: { blockId, email: block.email },
      timestamp: new Date().toISOString(),
    };
  }

  @Post('unblock-email/:email')
  @ApiOperation({ summary: 'Unblock user by email' })
  @ApiParam({ name: 'email', description: 'User email' })
  async unblockByEmail(
    @Param('email') email: string,
    @Body() body: UnblockDto,
  ) {
    await this.loginAttemptService.unblockByEmail(email, undefined, body.note);

    const user = await this.loginBlockRepo.findOne({
      where: { email: email.toLowerCase() },
    });

    if (user?.userId) {
      await this.securityNotificationService.sendAccountUnlockedNotification(
        user.userId,
      );
    }

    return {
      statusCode: HttpStatus.OK,
      message: `User ${email} unblocked successfully`,
      timestamp: new Date().toISOString(),
    };
  }

  @Post('block-user/:userId')
  @ApiOperation({ summary: 'Manually block a user' })
  @ApiParam({ name: 'userId', description: 'User ID' })
  async blockUser(
    @Param('userId', ParseIntPipe) userId: number,
    @Body() body: BlockUserDto,
  ) {
    const block = await this.loginAttemptService.createBlock(
      '',
      userId,
      'manual',
      0,
    );

    await this.loginBlockRepo.update(
      { id: block.id },
      {
        reason: body.reason,
        isPermanent: body.permanent || false,
        expiresAt: body.permanent
          ? null
          : new Date(Date.now() + 24 * 60 * 60 * 1000),
      },
    );

    return {
      statusCode: HttpStatus.OK,
      message: `User ${userId} has been blocked`,
      data: { userId, blockId: block.id, permanent: body.permanent },
      timestamp: new Date().toISOString(),
    };
  }

  @Post('reset-attempts/:email')
  @ApiOperation({ summary: 'Reset login attempts for an email' })
  @ApiParam({ name: 'email', description: 'User email' })
  async resetAttempts(@Param('email') email: string) {
    await this.loginAttemptService.resetAttempts(email.toLowerCase());

    return {
      statusCode: HttpStatus.OK,
      message: 'Login attempts reset successfully',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('blocked-ips')
  @ApiOperation({ summary: 'Get all blocked IPs' })
  async getBlockedIPs() {
    const blockedIPs = await this.ipBlockService.getBlockedIPs();

    return {
      statusCode: HttpStatus.OK,
      message: 'Blocked IPs retrieved successfully',
      data: blockedIPs,
      timestamp: new Date().toISOString(),
    };
  }

  @Delete('blocked-ips/:ip')
  @ApiOperation({ summary: 'Unblock an IP address' })
  @ApiParam({ name: 'ip', description: 'IP address' })
  async unblockIP(@Param('ip') ip: string) {
    await this.ipBlockService.unblockIP(ip);

    return {
      statusCode: HttpStatus.OK,
      message: `IP ${ip} has been unblocked`,
      timestamp: new Date().toISOString(),
    };
  }

  @Post('block-ip')
  @ApiOperation({ summary: 'Manually block an IP address' })
  async blockIP(@Body() body: { ip: string; duration?: number }) {
    await this.ipBlockService.blockIP(body.ip, body.duration || 3600);

    return {
      statusCode: HttpStatus.OK,
      message: `IP ${body.ip} has been blocked`,
      timestamp: new Date().toISOString(),
    };
  }
}
