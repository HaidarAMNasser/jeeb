import { Test, TestingModule } from '@nestjs/testing';
import {
  BadRequestException,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { of, throwError } from 'rxjs';
import { OtpAttemptInterceptor } from '../../../../src/common/interceptors/otp-attempt.interceptor';
import { OtpAttemptService } from '../../../../src/common/services/otp-attempt.service';

describe('OtpAttemptInterceptor', () => {
  let interceptor: OtpAttemptInterceptor;
  let otpAttemptService: jest.Mocked<OtpAttemptService>;

  const mockContext = (body: any) =>
    ({
      switchToHttp: () => ({
        getRequest: () => ({ body }),
      }),
    }) as ExecutionContext;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OtpAttemptInterceptor,
        {
          provide: OtpAttemptService,
          useValue: {
            recordFailedAttempt: jest.fn(),
            recordSuccessfulAttempt: jest.fn(),
          },
        },
      ],
    }).compile();

    interceptor = module.get<OtpAttemptInterceptor>(OtpAttemptInterceptor);
    otpAttemptService = module.get(OtpAttemptService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('يسجل نجاح عند نجاح التحقق', (done) => {
    otpAttemptService.recordSuccessfulAttempt.mockResolvedValue(undefined);

    const mockNext: CallHandler = {
      handle: () => of({ message: 'verified' }),
    };

    interceptor
      .intercept(mockContext({ phone: '+963900000001' }), mockNext)
      .subscribe({
        next: (value) => {
          expect(value).toEqual({ message: 'verified' });
          expect(
            otpAttemptService.recordSuccessfulAttempt,
          ).toHaveBeenCalledWith('+963900000001');
          done();
        },
      });
  });

  it('يسجل فشل عند BadRequestException', (done) => {
    otpAttemptService.recordFailedAttempt.mockResolvedValue(3);

    const mockNext: CallHandler = {
      handle: () => throwError(() => new BadRequestException('Invalid or expired OTP')),
    };

    interceptor
      .intercept(mockContext({ email: 'user@test.com' }), mockNext)
      .subscribe({
        error: (err) => {
          expect(err).toBeInstanceOf(BadRequestException);
          expect(
            otpAttemptService.recordFailedAttempt,
          ).toHaveBeenCalledWith('user@test.com');
          done();
        },
      });
  });

  it('لا يسجل فشل لخطأ غير BadRequestException', (done) => {
    const mockNext: CallHandler = {
      handle: () => throwError(() => new Error('Internal error')),
    };

    interceptor
      .intercept(mockContext({ phone: '+963900000001' }), mockNext)
      .subscribe({
        error: (err) => {
          expect(err).toBeInstanceOf(Error);
          expect(
            otpAttemptService.recordFailedAttempt,
          ).not.toHaveBeenCalled();
          done();
        },
      });
  });

  it('يمرر الطلب بدون تعديل إذا لا يوجد identifier', (done) => {
    const mockNext: CallHandler = {
      handle: () => of({ message: 'ok' }),
    };

    interceptor
      .intercept(mockContext({}), mockNext)
      .subscribe({
        next: (value) => {
          expect(value).toEqual({ message: 'ok' });
          expect(
            otpAttemptService.recordSuccessfulAttempt,
          ).not.toHaveBeenCalled();
          done();
        },
      });
  });
});
