import { SearchStrategy } from './search-strategy.interface';

export class CaseInsensitiveSearchStrategy implements SearchStrategy {
  buildSearchCondition(
    field: string,
    searchValue: string,
    paramName: string,
  ): string {
    this.formatSearchValue(searchValue);
    if (field.includes('->>') || field.includes('->')) {
      return `(${field})::text ILIKE :${paramName}`;
    }
    return `${field} ILIKE :${paramName}`;
  }

  formatSearchValue(searchValue: string): string {
    return `%${searchValue}%`;
  }
}

export class CaseSensitiveSearchStrategy implements SearchStrategy {
  buildSearchCondition(
    field: string,
    searchValue: string,
    paramName: string,
  ): string {
    this.formatSearchValue(searchValue);
    if (field.includes('->>') || field.includes('->')) {
      return `(${field})::text LIKE :${paramName}`;
    }
    return `${field} LIKE :${paramName}`;
  }

  formatSearchValue(searchValue: string): string {
    return `%${searchValue}%`;
  }
}
