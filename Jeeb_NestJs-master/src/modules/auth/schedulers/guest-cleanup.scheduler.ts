import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../../database/entities/user.entity';

@Injectable()
export class GuestCleanupScheduler {
  private readonly logger = new Logger(GuestCleanupScheduler.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  /**
   * Run every day at 3:00 AM to sweep inactive guest accounts.
   */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async handleGuestGarbageCollection() {
    this.logger.log('Starting Guest Account Garbage Collection task...');

    // Inactivity threshold: 5 days
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 5);

    try {
      // Find guest users who haven't logged in for 5 days and have no orders.
      // We check for 'guest-%@jeeb.local' and assure they don't have orders to prevent
      // deleting accidental true guest-linked orders (though guests shouldn't normally order without conversion).
      const usersToDelete = await this.userRepository
        .createQueryBuilder('user')
        .leftJoin('user.orders', 'order')
        .where('user.email LIKE :emailPattern', {
          emailPattern: 'guest-%@jeeb.local',
        })
        .andWhere(
          '(user.last_login_at < :cutoffDate OR (user.last_login_at IS NULL AND user.createdAt < :cutoffDate))',
          { cutoffDate },
        )
        .andWhere('order.id IS NULL')
        .getMany();

      if (usersToDelete.length === 0) {
        this.logger.log('No inactive guest accounts found for cleanup.');
        return;
      }

      // Perform deletion. Since Cart has onDelete: 'CASCADE' to User,
      // deleting the user directly removes their carts and cart items seamlessly.
      await this.userRepository.remove(usersToDelete);

      this.logger.log(
        `Successfully deleted ${usersToDelete.length} inactive guest accounts and their associated carts.`,
      );
    } catch (error) {
      this.logger.error('Failed to cleanup guest accounts', error);
    }
  }
}
