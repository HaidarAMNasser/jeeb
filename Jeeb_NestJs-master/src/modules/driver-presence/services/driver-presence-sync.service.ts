import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { User } from '../../../database/entities/user.entity';

const CHUNK_SIZE = 10;

@Injectable()
export class DriverPresenceSyncService {
  private readonly logger = new Logger(DriverPresenceSyncService.name);
  private readonly queue = new Map<number, boolean>();
  private readonly intervalMs: number;
  private intervalHandle: ReturnType<typeof setInterval> | null = null;
  private disabled = false;

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly configService: ConfigService,
  ) {
    this.intervalMs =
      this.configService.get<number>('PRESENCE_SYNC_INTERVAL_MS') || 15_000;
  }

  start(): void {
    if (this.intervalHandle) return;
    this.intervalHandle = setInterval(() => this.flush(), this.intervalMs);
    this.logger.log(`Sync started every ${this.intervalMs}ms`);
  }

  stop(): void {
    if (this.intervalHandle) {
      clearInterval(this.intervalHandle);
      this.intervalHandle = null;
    }
  }

  enqueue(driverId: number, isOnline: boolean): void {
    if (this.disabled) return;
    this.queue.set(driverId, isOnline);
  }

  enqueueBatch(updates: Map<number, boolean>): void {
    if (this.disabled) return;
    for (const [id, online] of updates) {
      this.queue.set(id, online);
    }
  }

  getQueueSize(): number {
    return this.queue.size;
  }

  private async flush(): Promise<void> {
    if (this.queue.size === 0 || this.disabled) return;

    const batch = Array.from(this.queue.entries());
    this.queue.clear();

    const entries = batch.map(([driverId, isOnline]) => ({ driverId, isOnline }));
    let succeeded = 0;

    for (let i = 0; i < entries.length; i += CHUNK_SIZE) {
      const chunk = entries.slice(i, i + CHUNK_SIZE);
      const chunkPromises = chunk.map(({ driverId, isOnline }) =>
        this.userRepository.update(driverId, { isOnline }).then(() => {
          succeeded++;
        }).catch((error: any) => {
          const msg: string = error?.message || '';
          if (msg.includes('does not exist') && msg.includes('is_online')) {
            this.logger.error('isOnline column missing in database — disabling sync permanently');
            this.disabled = true;
            return;
          }
          this.logger.error(
            `Failed to sync isOnline for driver ${driverId}: ${msg}`,
          );
          this.queue.set(driverId, isOnline);
        }),
      );
      await Promise.all(chunkPromises);
    }

    this.logger.debug(
      `Synced ${succeeded}/${entries.length} driver(s) in chunks of ${CHUNK_SIZE}`,
    );
  }
}
