import { Module, forwardRef } from '@nestjs/common';

import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { TokenService } from './token.service';
import { LoginService } from './services/login.service';
import { PasswordService } from './services/password.service';
import { RegistrationService } from './services/registration.service';
import { ProfileService } from './services/profile.service';
import { CustomerRegistrationFlowService } from './services/customer-registration-flow.service';
import { AuthController } from './auth.controller';
import { AuthAdminController } from './auth-admin.controller';
import { MerchantController } from './controllers/merchant.controller';
import { MerchantService } from './services/merchant.service';
import { UsersAdminController } from './controllers/users-admin.controller';
import { UsersAdminService } from './services/users-admin.service';
import { OfficeOwnersController } from './controllers/office-owners.controller';
import { OfficeOwnersService } from './services/office-owners.service';
import { AdminSecurityController } from './controllers/admin-security.controller';
import { GuestCleanupScheduler } from './schedulers/guest-cleanup.scheduler';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuthGuard } from '../../common/guards/auth.guard';
import { CustomerRegistrationStrategy } from './strategies/customer-registration.strategy';
import { Token } from '../../database/entities/token.entity';
import { User } from '../../database/entities/user.entity';
import { Merchant } from '../../database/entities/merchant.entity';
import { Image } from '../../database/entities/image.entity';
import { DeliveryAssignment } from '../../database/entities/delivery-assignment.entity';
import { Order } from '../../database/entities/order.entity';
import { Review } from '../../database/entities/review.entity';
import { Product } from '../../database/entities/product.entity';
import { LoginBlock } from '../../database/entities/login-block.entity';
import { Area } from '../../database/entities/area.entity';

import { CountriesModule } from '../countries/countries.module';
import { CitiesModule } from '../cities/cities.module';
import { AreasModule } from '../areas/areas.module';
import { MerchantsModule } from '../merchants/merchants.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { GuestRedisService } from './services/guest-redis.service';

@Module({
  imports: [
    ConfigModule,
    forwardRef(() => UsersModule),
    NotificationsModule,
    CountriesModule,
    CitiesModule,
    forwardRef(() => AreasModule),
    MerchantsModule,
    FirebaseModule,
    TypeOrmModule.forFeature([
      Token,
      User,
      Merchant,
      Image,
      DeliveryAssignment,
      Order,
      Review,
      Product,
      LoginBlock,
      Area,
    ]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: '1d' },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [
    AuthController,
    AuthAdminController,
    MerchantController,
    UsersAdminController,
    OfficeOwnersController,
    AdminSecurityController,
  ],
  providers: [
    AuthService,
    TokenService,
    LoginService,
    PasswordService,
    RegistrationService,
    ProfileService,
    AuthGuard,
    CustomerRegistrationStrategy,
    CustomerRegistrationFlowService,
    MerchantService,
    UsersAdminService,
    OfficeOwnersService,
    GuestCleanupScheduler,
    GuestRedisService,
  ],
  exports: [
    AuthService,
    TokenService,
    JwtModule,
    MerchantService,
    UsersAdminService,
    OfficeOwnersService,
    LoginService,
    PasswordService,
    RegistrationService,
    ProfileService,
    CustomerRegistrationFlowService,
  ],
})
export class AuthModule {}
