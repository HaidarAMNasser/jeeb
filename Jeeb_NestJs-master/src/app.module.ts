import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { APP_GUARD } from '@nestjs/core';
// import { BullModule } from '@nestjs/bullmq';
import { LocationModule } from './modules/location/location.module';
import { ProductsModule } from './modules/products/products.module';
import { OrdersModule } from './modules/orders/orders.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CouponsModule } from './modules/coupons/coupons.module';
import { AuditModule } from './modules/audit/audit.module';
import { CommonModule } from './common/common.module';
import { BullModule } from '@nestjs/bullmq';
import { RedisModule } from './common/redis/redis.module';
// import { RedisModule } from './common/redis/redis.module';
import { CountriesModule } from './modules/countries/countries.module';
import { CitiesModule } from './modules/cities/cities.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { SettingsModule } from './modules/settings/settings.module';
import { LoyaltyModule } from './modules/loyalty/loyalty.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { OffersModule } from './modules/offers/offers.module';
import { RolePermissionsModule } from './modules/role-permissions/role-permissions.module';
import { MerchantsModule } from './modules/merchants/merchants.module';
import { GlobalSearchModule } from './modules/global-search/global-search.module';
import { CartModule } from './modules/cart/cart.module';
import { BlazeApiModule } from './modules/blaze-api/blaze-api.module';
import { DistanceModule } from './modules/distance/distance.module';
import { TrackingModule } from './modules/tracking/tracking.module';
import { StatisticsModule } from './modules/statistics/statistics.module';
import { AreasModule } from './modules/areas/areas.module';
import { DriverPresenceModule } from './modules/driver-presence/driver-presence.module';
import { AuthGuard } from './common/guards/auth.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { CustomThrottlerGuard } from './common/guards/custom-throttler.guard';
import { GuestRestrictionGuard } from './common/guards/guest-restriction.guard';
import { MaintenanceGuard } from './common/guards/maintenance.guard';

const envFilePath =
  process.env.NODE_ENV === 'development'
    ? '.env.development'
    : process.env.NODE_ENV === 'production'
      ? '.env.production'
      : '.env';

// Environment file path selected

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '.env.production'],
    }),
    ScheduleModule.forRoot(),
    // ThrottlerModule - Global rate limiting (configurable via env vars)
    // THROTTLER_DEFAULT_LIMIT / THROTTLER_GET_LIMIT / THROTTLER_LONG_LIMIT
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        throttlers: [
          {
            name: 'default',
            ttl: 60000,
            limit: configService.get<number>('THROTTLER_DEFAULT_LIMIT', 30),
          },
          {
            name: 'get',
            ttl: 60000,
            limit: configService.get<number>('THROTTLER_GET_LIMIT', 50),
          },
          {
            name: 'long',
            ttl: 60000 * 60,
            limit: configService.get<number>('THROTTLER_LONG_LIMIT', 600),
          },
        ],
      }),
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST'),
        port: configService.get<number>('DB_PORT'),
        username: configService.get<string>('DB_USERNAME'),
        password: configService.get<string>('DB_PASSWORD'),
        database: configService.get<string>('DB_DATABASE'),
        autoLoadEntities: true,
        extra: { max: 50 },
        synchronize: true,
      }),
      inject: [ConfigService],
    }),
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        connection: {
          host: configService.get<string>('REDIS_HOST', 'localhost'),
          port: configService.get<number>('REDIS_PORT', 6379),
          password: configService.get<string>('REDIS_PASSWORD'),
          db: configService.get<number>('REDIS_DB', 0),
        },
      }),
      inject: [ConfigService],
    }),
    RedisModule,
    LocationModule,
    ProductsModule,
    OrdersModule,
    NotificationsModule,
    AuthModule,
    UsersModule,
    CouponsModule,
    AuditModule,
    CommonModule,
    CountriesModule,
    CitiesModule,
    CategoriesModule,
    SettingsModule,
    LoyaltyModule,
    ReviewsModule,
    FavoritesModule,
    OffersModule,
    RolePermissionsModule,
    MerchantsModule,
    GlobalSearchModule,
    CartModule,
    BlazeApiModule,
    DistanceModule,
    TrackingModule,
    StatisticsModule,
    AreasModule,
    DriverPresenceModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: CustomThrottlerGuard,
    },
    {
      provide: APP_GUARD,
      useClass: AuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: MaintenanceGuard,
    },
    {
      provide: APP_GUARD,
      useClass: GuestRestrictionGuard,
    },
    {
      provide: APP_GUARD,
      useClass: RolesGuard,
    },
  ],
})
export class AppModule {}
