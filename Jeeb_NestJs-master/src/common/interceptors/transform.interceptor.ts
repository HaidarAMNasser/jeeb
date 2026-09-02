import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Request, Response } from 'express';
import {
  ApiResponse,
  PaginationMeta,
} from '../interfaces/api-response.interface';
import { PaginatedResult } from '../interfaces/paginated-result.interface';

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<
  T,
  ApiResponse<T>
> {
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse<T>> {
    const request = context.switchToHttp().getRequest<Request>();
    return next.handle().pipe(
      map((data: unknown) => {
        const response = context.switchToHttp().getResponse<Response>();
        const request = context.switchToHttp().getRequest<Request>();
        const statusCode = response.statusCode;

        let responseData: unknown;
        let pagination: PaginationMeta | undefined;
        let message = 'Operation successful';

        // Helper to check if data is a non-null object
        const isObject = (val: unknown): val is Record<string, unknown> =>
          val !== null && typeof val === 'object';

        if (this.isPaginatedResult(data)) {
          // Case 1: Paginated Result
          responseData = data.data;
          pagination = {
            total: data.total,
            page: data.page,
            limit: data.limit,
            totalPages: Math.ceil(data.total / data.limit),
            hasNextPage: data.page < Math.ceil(data.total / data.limit),
            hasPreviousPage: data.page > 1,
          };
          // Try to extract message if present in paginated result wrapper (though usually not standard)
          if ('message' in data && typeof data.message === 'string') {
            message = data.message;
          }
        } else if (isObject(data)) {
          // Case 2: Object response

          // Extract message if present
          if ('message' in data && typeof data.message === 'string') {
            message = data.message;
          }

          // Extract pagination if present
          if (
            'pagination' in data &&
            typeof data.pagination === 'object' &&
            data.pagination !== null
          ) {
            pagination = data.pagination as PaginationMeta;
          }

          // Determine responseData
          if ('data' in data) {
            // If data is explicitly wrapped in 'data' property
            responseData = data.data;
          } else {
            // If it's a plain object, use it as data, but exclude 'message' and 'pagination'
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            const { message: _, pagination: __, ...rest } = data;
            // If the object becomes empty after removing message (e.g. { message: "Deleted" }), responseData becomes {}
            responseData = rest;
          }
        } else {
          // Case 3: Primitive value (string, number, boolean, null, undefined)
          responseData = data;
        }

        // Ensure data is always an object if it's null/undefined/empty
        // User explicitly asked for empty data object if no data
        if (responseData === undefined || responseData === null) {
          responseData = {};
        }

        // Recursively convert nulls to empty objects/strings if needed?
        // User said: "لا اريد قيمة null في ال response... انا اريد على سبيل المثال من اجل data هنا ان تكون {}"
        // This implies if responseData ITSELF is null, make it {}.
        // The check above handles responseData === null -> {}.
        // But what if responseData has properties that are null?
        // "لا اريد قيمة null في ال response" is quite broad.
        // Usually means top-level data field should not be null.
        // Let's ensure top-level is handled first.

        return {
          statusCode,
          message,
          data: responseData as T,
          pagination,
          timestamp: new Date().toISOString(),
          path: request.url,
        };
      }),
    );
  }

  private isPaginatedResult(data: unknown): data is PaginatedResult<unknown> {
    if (!data || typeof data !== 'object') {
      return false;
    }

    const castedData = data as Partial<PaginatedResult<unknown>>;

    return (
      'data' in castedData &&
      Array.isArray(castedData.data) &&
      'total' in castedData &&
      typeof castedData.total === 'number' &&
      'page' in castedData &&
      typeof castedData.page === 'number' &&
      'limit' in castedData &&
      typeof castedData.limit === 'number'
    );
  }
}
