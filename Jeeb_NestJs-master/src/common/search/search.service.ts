import { Injectable } from '@nestjs/common';
import {
  SearchStrategy,
  SearchStrategyFactory,
  CaseSensitivity,
} from './search-strategy.interface';
import {
  CaseInsensitiveSearchStrategy,
  CaseSensitiveSearchStrategy,
} from './search-strategies';

@Injectable()
export class SearchService implements SearchStrategyFactory {
  private strategies: Map<CaseSensitivity, SearchStrategy> = new Map();

  constructor() {
    this.strategies.set(
      CaseSensitivity.INSENSITIVE,
      new CaseInsensitiveSearchStrategy(),
    );
    this.strategies.set(
      CaseSensitivity.SENSITIVE,
      new CaseSensitiveSearchStrategy(),
    );
  }

  getStrategy(caseSensitivity: CaseSensitivity): SearchStrategy {
    return (
      this.strategies.get(caseSensitivity) ??
      this.strategies.get(CaseSensitivity.INSENSITIVE)!
    );
  }

  buildSearchConditions(
    fields: string[],
    searchValue: string,
    caseSensitivity: CaseSensitivity = CaseSensitivity.INSENSITIVE,
  ): { condition: string; paramName: string; paramValue: string } {
    const strategy = this.getStrategy(caseSensitivity);
    const paramName = 'search';

    const conditions = fields.map((field) =>
      strategy.buildSearchCondition(field, searchValue, paramName),
    );

    const paramValue = strategy.formatSearchValue(searchValue);

    return {
      condition: `(${conditions.join(' OR ')})`,
      paramName,
      paramValue,
    };
  }
}
