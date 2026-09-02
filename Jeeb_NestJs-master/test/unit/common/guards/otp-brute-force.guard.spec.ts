import { Test, TestingModule } from '@nestjs/testing';
import { HttpException } from '@nestjs/common';
import { OtpBruteForceGuard } from '../../../../src/common/guards/otp-brute-force.guard';
import { OtpAttemptService } from '../../../../src/common/services/otp-attempt.service';

describe('OtpBruteForceGuard', () => {
  let guard: OtpBruteForceGuard;
  let otpAttemptService: jest.Mocked<OtpAttemptService>;

  const mockContext = (body: any) =>
    ({
      switchToHttp: () => ({
        getRequest: () => ({ body }),
      }),
    }) as any;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OtpBruteForceGuard,
        {
          provide: OtpAttemptService,
          useValue: {
            isBlocked: jest.fn(),
            getBlockInfo: jest.fn(),
          },
        },
      ],
    }).compile();

    guard = module.get<OtpBruteForceGuard>(OtpBruteForceGuard);
    otpAttemptService = module.get(OtpAttemptService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('يسمح بالمرور إذا phone غير محظور', async () => {
    otpAttemptService.isBlocked.mockResolvedValue(false);

    const result = await guard.canActivate(
      mockContext({ phone: '+963900000001', otp: '123456' }),
    );

    expect(result).toBe(true);
    expect(otpAttemptService.isBlocked).toHaveBeenCalledWith('+963900000001');
  });

  it('يسمح بالمرور إذا email غير محظور', async () => {
    otpAttemptService.isBlocked.mockResolvedValue(false);

    const result = await guard.canActivate(
      mockContext({ email: 'user@test.com', otp: '123456' }),
    );

    expect(result).toBe(true);
    expect(otpAttemptService.isBlocked).toHaveBeenCalledWith('user@test.com');
  });

  it('يمنع الوصول ويرمي 429 إذا phone محظور', async () => {
    otpAttemptService.isBlocked.mockResolvedValue(true);
    otpAttemptService.getBlockInfo.mockResolvedValue({
      attempts: 5,
      maxAttempts: 5,
      blockTtl: 800,
    });

    await expect(
      guard.canActivate(mockContext({ phone: '+963900000001', otp: '123456' })),
    ).rejects.toThrow(HttpException);

    await expect(
      guard.canActivate(mockContext({ phone: '+963900000001', otp: '123456' })),
    ).rejects.toMatchObject({
      response: {
        statusCode: 429,
        error: 'ERROR_1107',
        details: { retryAfter: 800 },
      },
    });
  });

  it('يسمح بالمرور إذا لا يوجد identifier في الـ body', async () => {
    const result = await guard.canActivate(mockContext({}));

    expect(result).toBe(true);
    expect(otpAttemptService.isBlocked).not.toHaveBeenCalled();
  });
});
