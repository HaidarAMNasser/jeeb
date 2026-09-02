import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { UnassignAction } from '../dto/unassign-driver.dto';
import { IUnassignStrategy } from './unassign-strategy.interface';
import { AutoSearchUnassignStrategy } from './auto-search-unassign.strategy';
import { ManualAssignUnassignStrategy } from './manual-assign-unassign.strategy';

@Injectable()
export class UnassignStrategyFactory {
  private readonly logger = new Logger(UnassignStrategyFactory.name);
  private readonly strategies: Map<UnassignAction, IUnassignStrategy> = new Map();

  constructor(
    autoSearchStrategy: AutoSearchUnassignStrategy,
    manualAssignStrategy: ManualAssignUnassignStrategy,
  ) {
    this.strategies.set(UnassignAction.AUTO_SEARCH, autoSearchStrategy);
    this.strategies.set(UnassignAction.MANUAL_ASSIGN, manualAssignStrategy);
  }

  getStrategy(action: UnassignAction): IUnassignStrategy {
    const strategy = this.strategies.get(action);
    if (!strategy) {
      const available = Array.from(this.strategies.keys()).join(', ');
      throw new BadRequestException(
        `Unsupported unassign action: ${action}. Available: ${available}`,
      );
    }
    return strategy;
  }
}
