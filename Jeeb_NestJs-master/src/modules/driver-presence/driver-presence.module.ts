import { Module, OnModuleInit, Logger } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../../database/entities/user.entity';
import { FirebaseModule } from '../firebase/firebase.module';
import { DriverPresenceListenerService } from './services/driver-presence-listener.service';
import { DriverPresenceSyncService } from './services/driver-presence-sync.service';
import { DriverPresenceReconciliationService } from './services/driver-presence-reconciliation.service';

@Module({
  imports: [TypeOrmModule.forFeature([User]), FirebaseModule],
  providers: [
    DriverPresenceListenerService,
    DriverPresenceSyncService,
    DriverPresenceReconciliationService,
  ],
  exports: [
    DriverPresenceListenerService,
    DriverPresenceSyncService,
  ],
})
export class DriverPresenceModule implements OnModuleInit {
  private readonly logger = new Logger(DriverPresenceModule.name);

  constructor(
    private readonly reconciliationService: DriverPresenceReconciliationService,
    private readonly listenerService: DriverPresenceListenerService,
    private readonly syncService: DriverPresenceSyncService,
  ) {}

  async onModuleInit() {
    this.logger.log('Initializing DriverPresenceModule...');

    const { cache, syncUpdates } =
      await this.reconciliationService.runReconciliation();

    for (const [id, data] of cache) {
      this.listenerService.getRawCache().set(id, data);
    }

    this.syncService.enqueueBatch(syncUpdates);

    this.listenerService.startListening();
    this.syncService.start();
  }
}
