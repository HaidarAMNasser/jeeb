import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { TokenService } from '../../../../src/modules/auth/token.service';
import { Token } from '../../../../src/database/entities/token.entity';
import { User } from '../../../../src/database/entities/user.entity';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { Repository } from 'typeorm';

describe('TokenService', () => {
  let service: TokenService;
  let jwtService: jest.Mocked<JwtService>;
  let configService: jest.Mocked<ConfigService>;
  let tokenRepository: jest.Mocked<Repository<Token>>;

  const mockUser: Partial<User> = {
    id: 1,
    email: 'test@example.com',
    role: UserRole.CUSTOMER,
  };

  const mockJwtPayload = {
    sub: 1,
    email: 'test@example.com',
    role: 'CUSTOMER',
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TokenService,
        {
          provide: JwtService,
          useValue: {
            signAsync: jest.fn(),
            decode: jest.fn(),
          },
        },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Token),
          useValue: {
            save: jest.fn(),
            update: jest.fn(),
            findOne: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<TokenService>(TokenService);
    jwtService = module.get(JwtService);
    configService = module.get(ConfigService);
    tokenRepository = module.get(getRepositoryToken(Token));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('generateAccessToken', () => {
    it('يولد JWT صحيح ويلغي التوكنات السابقة ويحفظ الجديد', async () => {
      const fakeToken = 'jwt.token.here';
      const expiresAt = new Date(Date.now() + 86400000);
      const decodedToken = {
        sub: 1,
        email: 'test@example.com',
        role: 'CUSTOMER',
        exp: Math.floor(expiresAt.getTime() / 1000),
      };

      jwtService.signAsync.mockResolvedValue(fakeToken);
      jwtService.decode.mockReturnValue(decodedToken);
      configService.get.mockReturnValue('1d');

      const result = await service.generateAccessToken(mockUser as User);

      expect(result).toBe(fakeToken);
      expect(configService.get).toHaveBeenCalledWith('JWT_EXPIRATION_CUSTOMER');
      expect(jwtService.signAsync).toHaveBeenCalledWith(mockJwtPayload, {
        expiresIn: '1d',
      });
      expect(tokenRepository.update).toHaveBeenCalledWith(
        { userId: 1, isRevoked: false },
        { isRevoked: true },
      );
      expect(tokenRepository.save).toHaveBeenCalledWith({
        token: fakeToken,
        userId: 1,
        expiresAt: expect.any(Date),
        isRevoked: false,
      });
    });

    it('يستخدم JWT_EXPIRATION_VENDOR لدور MERCHANT', async () => {
      const merchantUser = { ...mockUser, role: UserRole.MERCHANT };
      jwtService.signAsync.mockResolvedValue('token');
      jwtService.decode.mockReturnValue({
        exp: Math.floor(Date.now() / 1000) + 3600,
      });
      configService.get.mockReturnValue('7d');

      await service.generateAccessToken(merchantUser as User);

      expect(configService.get).toHaveBeenCalledWith('JWT_EXPIRATION_VENDOR');
      expect(jwtService.signAsync).toHaveBeenCalledWith(
        { sub: 1, email: 'test@example.com', role: 'MERCHANT' },
        { expiresIn: '7d' },
      );
    });

    it('يستخدم JWT_EXPIRATION_DELIVERY لدور DELIVERY', async () => {
      const deliveryUser = { ...mockUser, role: UserRole.DELIVERY };
      jwtService.signAsync.mockResolvedValue('token');
      jwtService.decode.mockReturnValue({
        exp: Math.floor(Date.now() / 1000) + 3600,
      });
      configService.get.mockReturnValue('30d');

      await service.generateAccessToken(deliveryUser as User);

      expect(configService.get).toHaveBeenCalledWith('JWT_EXPIRATION_DELIVERY');
    });

    it('يستخدم JWT_EXPIRATION_ADMIN لدور ADMIN', async () => {
      const adminUser = { ...mockUser, role: UserRole.ADMIN };
      jwtService.signAsync.mockResolvedValue('token');
      jwtService.decode.mockReturnValue({
        exp: Math.floor(Date.now() / 1000) + 3600,
      });
      configService.get.mockReturnValue('1h');

      await service.generateAccessToken(adminUser as User);

      expect(configService.get).toHaveBeenCalledWith('JWT_EXPIRATION_ADMIN');
    });

    it('يستخدم القيمة الافتراضية 1d إذا لم يوجد إعداد', async () => {
      jwtService.signAsync.mockResolvedValue('token');
      jwtService.decode.mockReturnValue({
        exp: Math.floor(Date.now() / 1000) + 3600,
      });
      configService.get.mockReturnValue(undefined);

      await service.generateAccessToken(mockUser as User);

      expect(jwtService.signAsync).toHaveBeenCalledWith(expect.anything(), {
        expiresIn: '1d',
      });
    });
  });

  describe('revokeToken', () => {
    it('يلغي توكن معين', async () => {
      await service.revokeToken('some-token');

      expect(tokenRepository.update).toHaveBeenCalledWith(
        { token: 'some-token' },
        { isRevoked: true },
      );
    });
  });

  describe('revokeAllUserTokens', () => {
    it('يلغي كل التوكنات النشطة لمستخدم', async () => {
      await service.revokeAllUserTokens(1);

      expect(tokenRepository.update).toHaveBeenCalledWith(
        { userId: 1, isRevoked: false },
        { isRevoked: true },
      );
    });
  });

  describe('isTokenRevoked', () => {
    it('يعيد false للتوكن النشط', async () => {
      tokenRepository.findOne.mockResolvedValue({ isRevoked: false } as Token);

      const result = await service.isTokenRevoked('active-token');

      expect(result).toBe(false);
      expect(tokenRepository.findOne).toHaveBeenCalledWith({
        where: { token: 'active-token' },
      });
    });

    it('يعيد true للتوكن الملغي', async () => {
      tokenRepository.findOne.mockResolvedValue({ isRevoked: true } as Token);

      const result = await service.isTokenRevoked('revoked-token');

      expect(result).toBe(true);
    });

    it('يعيد true للتوكن غير الموجود', async () => {
      tokenRepository.findOne.mockResolvedValue(null);

      const result = await service.isTokenRevoked('unknown-token');

      expect(result).toBe(true);
    });
  });
});
