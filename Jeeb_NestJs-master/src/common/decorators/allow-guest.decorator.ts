import { SetMetadata } from '@nestjs/common';

export const ALLOW_GUEST_KEY = 'allowGuest';

/**
 * Decorator to explicitly allow a Guest user to perform a mutating (non-GET) operation.
 * By default, guests are restricted to GET operations only.
 */
export const AllowGuest = () => SetMetadata(ALLOW_GUEST_KEY, true);
