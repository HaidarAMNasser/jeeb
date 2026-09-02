import { Injectable, Logger } from '@nestjs/common';
import { User } from '../../database/entities/user.entity';
import { LoginService } from './services/login.service';
import { PasswordService } from './services/password.service';
import { RegistrationService } from './services/registration.service';
import { ProfileService } from './services/profile.service';
import { CustomerRegistrationFlowService } from './services/customer-registration-flow.service';
import { TokenService } from './token.service';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GuestLoginDto } from './dto/guest-login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { CustomerInitDto } from './dto/customer-init.dto';
import { CustomerCompleteRegistrationDto } from './dto/customer-complete-registration.dto';
import { FirebaseService } from '../firebase/firebase.service';
import { UserRole } from '../../common/enums/user-role.enum';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly registrationService: RegistrationService,
    private readonly loginService: LoginService,
    private readonly passwordService: PasswordService,
    private readonly profileService: ProfileService,
    private readonly customerRegistrationFlowService: CustomerRegistrationFlowService,
    private readonly tokenService: TokenService,
    private readonly firebaseService: FirebaseService,
  ) {}

  async register(registerDto: RegisterDto, files?: Express.Multer.File[]) {
    return this.registrationService.register(registerDto, files);
  }

  async createAdminOrMerchant(createUserDto: CreateUserDto) {
    return this.registrationService.createAdminOrMerchant(createUserDto);
  }

  async verifyAccount(identifier: string, otp: string) {
    return this.registrationService.verifyAccount(identifier, otp);
  }

  async login(loginDto: LoginDto, ip?: string) {
    return this.loginService.login(loginDto, ip);
  }

  async loginGuest(guestLoginDto: GuestLoginDto, ip?: string, ua?: string) {
    // firebaseToken ignored for backward compatibility
    return this.loginService.handleGuestLogin(ip, ua);
  }

  async forgotPassword(forgotPasswordDto: ForgotPasswordDto) {
    return this.passwordService.forgotPassword(forgotPasswordDto);
  }

  async resendOtp(identifier: string) {
    return this.passwordService.resendOtp(identifier);
  }

  async resetPassword(resetPasswordDto: ResetPasswordDto) {
    return this.passwordService.resetPassword(resetPasswordDto);
  }

  async customerInit(initDto: CustomerInitDto) {
    return this.customerRegistrationFlowService.init(initDto);
  }

  async customerVerifyPhone(phone: string, otp: string) {
    return this.customerRegistrationFlowService.verifyPhone(phone, otp);
  }

  async customerCompleteRegistration(
    userId: number,
    dto: CustomerCompleteRegistrationDto,
    files?: Express.Multer.File[],
  ) {
    return this.customerRegistrationFlowService.completeRegistration(
      userId,
      dto,
      files,
    );
  }

  async logout(_user: User, token: string) {
    await this.tokenService.revokeToken(token);
    return { message: 'Logged out successfully' };
  }

  async getProfile(user: User) {
    return this.profileService.getProfile(user);
  }

  async updateProfile(
    user: User,
    updateProfileDto: UpdateProfileDto,
    files?: Express.Multer.File[],
  ) {
    return this.profileService.updateProfile(user, updateProfileDto, files);
  }

  async deleteProfile(user: User) {
    return this.profileService.deleteProfile(user);
  }

  async updateFirebaseToken(user: User, firebaseToken: string) {
    await this.loginService.updateFirebaseToken(user.id, firebaseToken);

    const userRole = (user as any).role;
    const isDelivery =
      userRole === UserRole.DELIVERY || String(userRole) === 'DELIVERY';

    if (!isDelivery) {
      return {
        message: 'Firebase token updated successfully',
        fcmTokenUpdated: true,
      };
    }

    try {
      const tokenData = await this.firebaseService.createCustomTokenForDelivery(
        {
          id: user.id,
          role: UserRole.DELIVERY,
        },
      );

      return {
        message: 'Firebase token and custom token generated successfully',
        fcmTokenUpdated: true,
        firebaseUid: tokenData.uid,
        customToken: tokenData.customToken,
      };
    } catch (error) {
      throw error;
    }
  }
}
