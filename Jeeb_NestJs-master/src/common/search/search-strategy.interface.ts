export enum SearchType {
  CONTAINS = 'CONTAINS',
  EXACT = 'EXACT',
  STARTS_WITH = 'STARTS_WITH',
  ENDS_WITH = 'ENDS_WITH',
}

export enum CaseSensitivity {
  INSENSITIVE = 'INSENSITIVE',
  SENSITIVE = 'SENSITIVE',
}

export interface SearchOptions {
  searchType?: SearchType;
  caseSensitivity?: CaseSensitivity;
  fields?: string[];
}

export interface SearchStrategy {
  buildSearchCondition(
    field: string,
    searchValue: string,
    paramName: string,
  ): string;

  formatSearchValue(searchValue: string): string;
}

export interface SearchStrategyFactory {
  getStrategy(caseSensitivity: CaseSensitivity): SearchStrategy;
}
