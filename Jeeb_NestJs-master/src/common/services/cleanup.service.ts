// import { Injectable, Logger } from '@nestjs/common';
// import { Repository, LessThan, ObjectLiteral } from 'typeorm';

// @Injectable()
// export class CleanupService {
//   private readonly logger = new Logger(CleanupService.name);

//   /**
//    * Cleans up old records from a given repository based on a date column.
//    *
//    * @param repository The TypeORM repository to clean
//    * @param dateColumn The name of the date column to check (e.g., 'createdAt')
//    * @param retentionDays The number of days to keep records
//    * @param additionalCriteria Optional object for additional filtering (e.g., { type: 'OTP' })
//    */
//   async cleanupOldRecords<T extends ObjectLiteral>(
//     repository: Repository<T>,
//     dateColumn: keyof T,
//     retentionDays: number,
//     additionalCriteria: object = {},
//   ): Promise<number> {
//     const cutoffDate = new Date();
//     cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

//     this.logger.log(
//       `Starting cleanup for ${repository.metadata.tableName}: deleting records older than ${cutoffDate.toISOString()}`,
//     );

//     try {
//       // Create a dynamic where clause with additional criteria
//       const where: any = { ...additionalCriteria };
//       where[dateColumn] = LessThan(cutoffDate);

//       const result = await repository.delete(where);
//       const deletedCount = result.affected || 0;

//       this.logger.log(
//         `Cleanup complete for ${repository.metadata.tableName}. Deleted ${deletedCount} records.`,
//       );

//       return deletedCount;
//     } catch (error) {
//       this.logger.error(
//         `Failed to cleanup records for ${repository.metadata.tableName}: ${error.message}`,
//         error.stack,
//       );
//       throw error;
//     }
//   }
// }

import { Injectable, Logger } from '@nestjs/common';
import { Repository, LessThan, ObjectLiteral, FindOptionsWhere } from 'typeorm';

@Injectable()
export class CleanupService {
  private readonly logger = new Logger(CleanupService.name);

  async cleanupOldRecords<T extends ObjectLiteral>(
    repository: Repository<T>,
    dateColumn: keyof T,
    retentionDays: number,
    additionalCriteria: FindOptionsWhere<T> = {},
  ): Promise<number> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    this.logger.log(
      `Starting cleanup for ${repository.metadata.tableName}: deleting records older than ${cutoffDate.toISOString()}`,
    );

    try {
      const where: FindOptionsWhere<T> = {
        ...additionalCriteria,
      };

      (where as Record<string, unknown>)[dateColumn as string] =
        LessThan(cutoffDate);

      const result = await repository.delete(where);
      const deletedCount = result.affected ?? 0;

      this.logger.log(
        `Cleanup complete for ${repository.metadata.tableName}. Deleted ${deletedCount} records.`,
      );

      return deletedCount;
    } catch (error: unknown) {
      if (error instanceof Error) {
        this.logger.error(
          `Failed to cleanup records for ${repository.metadata.tableName}: ${error.message}`,
          error.stack,
        );
      } else {
        this.logger.error(
          `Failed to cleanup records for ${repository.metadata.tableName}`,
        );
      }

      throw error;
    }
  }
}
