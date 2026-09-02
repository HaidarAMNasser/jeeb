import { Injectable } from '@nestjs/common';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../database/entities/user.entity';
import { Token } from '../../database/entities/token.entity';
import { UserRole } from '../../common/enums/user-role.enum';
import { JwtPayload } from './interfaces/jwt-payload.interface';

@Injectable()
export class TokenService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @InjectRepository(Token)
    private readonly tokenRepository: Repository<Token>,
  ) {}

  async generateAccessToken(user: User): Promise<string> {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };
    const expiresIn = this.getExpirationTime(user.role);

    const options: JwtSignOptions = {
      expiresIn: expiresIn,
    };

    const accessToken = await this.jwtService.signAsync(payload, options);

    // Decode token to get expiration time
    const decoded = this.jwtService.decode<JwtPayload>(accessToken);
    if (decoded && decoded.exp) {
      // Enforce 'Single Active Session' unless DISABLE_TOKEN_REVOCATION is set (for load testing)
      if (
        this.configService.get<string>('DISABLE_TOKEN_REVOCATION') !== 'true'
      ) {
        await this.revokeAllUserTokens(user.id);
      }

      const expiresAt = new Date(decoded.exp * 1000);
      await this.tokenRepository.save({
        token: accessToken,
        userId: user.id,
        expiresAt,
        isRevoked: false,
      });
    }

    return accessToken;
  }

  async revokeToken(token: string): Promise<void> {
    await this.tokenRepository.update({ token }, { isRevoked: true });
  }

  async revokeAllUserTokens(userId: number): Promise<void> {
    await this.tokenRepository.update(
      { userId, isRevoked: false },
      { isRevoked: true },
    );
  }

  async isTokenRevoked(token: string): Promise<boolean> {
    try {
      const decoded = this.jwtService.decode<JwtPayload>(token) as JwtPayload | null;
      if (decoded?.is_guest) return false;
    } catch {}
    const foundToken = await this.tokenRepository.findOne({ where: { token } });
    return foundToken?.isRevoked ?? true; // If token not found, consider it invalid/revoked
  }

  private getExpirationTime(role: UserRole): JwtSignOptions['expiresIn'] {
    let expiresIn: string | undefined;

    switch (role) {
      case UserRole.CUSTOMER:
        expiresIn = this.configService.get<string>('JWT_EXPIRATION_CUSTOMER');
        break;
      case UserRole.DELIVERY:
        expiresIn = this.configService.get<string>('JWT_EXPIRATION_DELIVERY');
        break;
      case UserRole.MERCHANT:
        expiresIn = this.configService.get<string>('JWT_EXPIRATION_VENDOR');
        break;
      case UserRole.ADMIN:
        expiresIn = this.configService.get<string>('JWT_EXPIRATION_ADMIN');
        break;
    }

    return (expiresIn || '1d') as JwtSignOptions['expiresIn'];
  }
}
