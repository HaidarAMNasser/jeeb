import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditService } from './audit.service';
import { AuditLog } from '../../database/entities/audit-log.entity';
import { ScheduleModule } from '@nestjs/schedule';

@Module({
  imports: [
    TypeOrmModule.forFeature([AuditLog]),
    ScheduleModule.forRoot(), // Ensure ScheduleModule is available
  ],
  providers: [AuditService],
  exports: [AuditService],
})
export class AuditModule {}
