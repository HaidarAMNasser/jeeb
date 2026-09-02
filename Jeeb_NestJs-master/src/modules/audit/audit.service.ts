import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AuditLog } from '../../database/entities/audit-log.entity';
import { CleanupService } from '../../common/services/cleanup.service';
import { AuditAction } from '../../common/enums/audit-action.enum';

@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);
  // Retention period for audit logs (e.g., 90 days)
  private readonly AUDIT_RETENTION_DAYS = 90;

  constructor(
    @InjectRepository(AuditLog)
    private readonly auditLogRepository: Repository<AuditLog>,
    private readonly cleanupService: CleanupService,
  ) {}

  /**
   * Log an action performed by a user
   */
  async logAction(
    userId: number,
    action: AuditAction,
    entityName: string,
    entityId: number,
    oldData?: unknown,
    newData?: unknown,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<AuditLog | null> {
    try {
      const log = this.auditLogRepository.create({
        userId,
        action,
        entityName,
        entityId,
        oldData,
        newData,
        ipAddress,
        userAgent,
      });
      return await this.auditLogRepository.save(log);
    } catch (error) {
      if (error instanceof Error) {
        this.logger.error('Failed to create audit log', error.stack);
      } else {
        this.logger.error('Failed to create audit log', String(error));
      }
      // We don't want to break the main flow if audit logging fails, but we should log the error
      return null;
    }
  }

  /**
   * Cron job to clean up old audit logs
   * Runs every day at 3:00 AM
   */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async handleAuditCleanup() {
    this.logger.debug('Running audit log cleanup task...');
    await this.cleanupService.cleanupOldRecords(
      this.auditLogRepository,
      'createdAt',
      this.AUDIT_RETENTION_DAYS,
    );
  }
}
