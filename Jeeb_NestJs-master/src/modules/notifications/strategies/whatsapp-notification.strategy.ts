import { Injectable, Logger, HttpException, HttpStatus, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Inject } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../../common/redis/redis.constants';
import { NotificationStrategy } from '../interfaces/notification-strategy.interface';
import { normalizePhone } from '../../../common/utils/phone.util';

const wasenderapi = require('wasenderapi');
const Wasender = wasenderapi.Wasender;

interface TemplateVariant {
  build: (...args: string[]) => string;
}

@Injectable()
export class WhatsappNotificationStrategy implements NotificationStrategy {
  private readonly logger = new Logger(WhatsappNotificationStrategy.name);
  private readonly wasenderApiKey: string;
  private wasender: any = null;
  private readonly twilioAccountSid: string;
  private readonly twilioAuthToken: string;
  private readonly twilioFromNumber: string;

  private static readonly OTP_GLOBAL_MAX = 50;
  private static readonly OTP_GLOBAL_WINDOW = 60;
  private static readonly OTP_PER_NUMBER_MAX = 3;
  private static readonly OTP_PER_NUMBER_WINDOW = 300;

  private otpTemplates: TemplateVariant[];
  private welcomeTemplates: TemplateVariant[];
  private orderStatusTemplates: Record<string, TemplateVariant[]>;

  constructor(
    private readonly configService: ConfigService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {
    this.wasenderApiKey = this.configService.get<string>(
      'WASENDER_API_KEY',
      '',
    );

    this.twilioAccountSid = this.configService.get<string>(
      'TWILIO_ACCOUNT_SID',
      '',
    );
    this.twilioAuthToken = this.configService.get<string>(
      'TWILIO_AUTH_TOKEN',
      '',
    );
    this.twilioFromNumber = this.configService.get<string>(
      'TWILIO_WHATSAPP_FROM',
      '',
    );

    if (this.wasenderApiKey) {
      this.wasender = new Wasender(this.wasenderApiKey);
      this.logger.log('WasenderAPI initialized successfully');
    } else {
      this.logger.warn(
        'WasenderAPI key not configured. WhatsApp notifications may fail.',
      );
    }

    this.initOtpVariants();
    this.initWelcomeVariants();
    this.initOrderStatusVariants();
  }

  private async checkOtpRateLimit(phone: string): Promise<void> {
    const now = Date.now();
    const globalKey = 'ratelimit:otp:global';
    const perKey = `ratelimit:otp:num:${phone}`;

    const pipeline = this.redis.pipeline();
    pipeline.zremrangebyscore(globalKey, 0, now - WhatsappNotificationStrategy.OTP_GLOBAL_WINDOW * 1000);
    pipeline.zadd(globalKey, now, `${now}-${Math.random()}`);
    pipeline.zcard(globalKey);
    pipeline.expire(globalKey, WhatsappNotificationStrategy.OTP_GLOBAL_WINDOW);

    pipeline.zremrangebyscore(perKey, 0, now - WhatsappNotificationStrategy.OTP_PER_NUMBER_WINDOW * 1000);
    pipeline.zadd(perKey, now, `${now}-${Math.random()}`);
    pipeline.zcard(perKey);
    pipeline.expire(perKey, WhatsappNotificationStrategy.OTP_PER_NUMBER_WINDOW);

    const results = await pipeline.exec();
    if (!results) return;

    const globalCount = results[2]?.[1] as number;
    const perCount = results[6]?.[1] as number;

    if (globalCount > WhatsappNotificationStrategy.OTP_GLOBAL_MAX) {
      throw new HttpException({
        statusCode: 429,
        message: 'Too many OTP requests. Please try again later.',
        error: 'RATE_LIMIT_GLOBAL',
        retryAfter: WhatsappNotificationStrategy.OTP_GLOBAL_WINDOW,
      }, HttpStatus.TOO_MANY_REQUESTS);
    }

    if (perCount > WhatsappNotificationStrategy.OTP_PER_NUMBER_MAX) {
      throw new HttpException({
        statusCode: 429,
        message: 'Too many OTP requests for this number. Please try again later.',
        error: 'RATE_LIMIT_NUMBER',
        retryAfter: WhatsappNotificationStrategy.OTP_PER_NUMBER_WINDOW,
      }, HttpStatus.TOO_MANY_REQUESTS);
    }
  }

  private pickVariant(variants: TemplateVariant[]): TemplateVariant {
    return variants[Math.floor(Math.random() * variants.length)];
  }

  private initOtpVariants() {
    this.otpTemplates = [
      {
        build: (to: string, otp: string) =>
          `🔐 *كود التحقق*\n\nمرحباً!\nرمز التحقق الخاص بك: *${otp}*\n⏰ صالح لمدة 5 دقائق\n🔒 لا تشاركه مع أحد\nشكراً لاستخدامك Jeeb`,
      },
      {
        build: (to: string, otp: string) =>
          `👋 مرحباً!\n\n*كود الدخول*: ${otp}\n\n⏳ ينتهي بعد 5 دقائق\n\n🚨 لا ترسل هذا الرمز لأي شخص!\n\n- فريق Jeeb`,
      },
      {
        build: (to: string, otp: string) =>
          `رمز التحقق من Jeeb\n—————————\n\n${otp}\n\nهذا الرمز صالح لمدة 5 دقائق فقط.\nإذا لم تطلب هذا الرمز، تجاهل الرسالة.\n\nتحياتنا،\nفريق Jeeb`,
      },
      {
        build: (to: string, otp: string) =>
          `مرحباً بك 🙌\n\nلقد طلبت رمز تحقق. هذا هو الرمز الخاص بك:\n\n*${otp}*\n\nسريعاً! لديك 5 دقائق فقط ⏱️\n\nمع التحية،\nJeeb`,
      },
      {
        build: (to: string, otp: string) =>
          `[Jeeb] كود التفعيل: ${otp}\n\nصالح لمدة 5 دقائق. لا تشاركه مع أي شخص.\n\nإذا لم تطلب هذا الكود، يرجى تجاهل الرسالة.`,
      },
    ];
  }

  private initWelcomeVariants() {
    this.welcomeTemplates = [
      {
        build: (to: string, name: string) =>
          `🎉 أهلاً وسهلاً يا *${name}*!\n\nنرحب بانضمامك إلى Jeeb 🛒\n\nالآن يمكنك:\n🛍️ طلب الطعام من مطاعمك المفضلة\n📍 تتبع طلبك خطوة بخطوة\n⭐ تقييم تجربتك\n\nنحن هنا لخدمتك!\nفريق Jeeb`,
      },
      {
        build: (to: string, name: string) =>
          `*${name}*! 🙌\n\nتم إنشاء حسابك في Jeeb بنجاح ✓\n\nاستعد لتجربة طعام جديدة كلياً.\nاطلب، تتبع، واستمتع! 🚀\n\nإذا كان لديك أي استفسار، تواصل معنا.\n\nتحياتنا،\nفريق الدعم`,
      },
      {
        build: (to: string, name: string) =>
          `مرحباً ${name} 👋\n\nشكراً لانضمامك إلى Jeeb!\n\nتطبيقنا يوصلك بأشهى المطاعم في مدينتك.\nجرب الطلب الآن واستمتع بتجربة سلسة.\n\n⚡ طلب سريع\n🚚 تتبع دقيق\n💳 دفع آمن\n\nأهلاً بك في العائلة! 💙`,
      },
      {
        build: (to: string, name: string) =>
          `[Jeeb] مرحباً ${name}\n\nحسابك جاهز ✓\n\nسجل دخولك الآن وابدأ بطلب وجبتك المفضلة.\n\nرابط التحميل:\nhttps://jeeb.app\n\nفريق Jeeb`,
      },
    ];
  }

  private initOrderStatusVariants() {
    const statusLabels: Record<string, string> = {
      CONFIRMED: 'تم تأكيد الطلب',
      PREPARING: 'جاري التحضير',
      READY_FOR_PICKUP: 'الطلب جاهز',
      ASSIGNED: 'سائق قادم إليك',
      PICKED_UP: 'تم الاستلام',
      ON_THE_WAY: 'في الطريق',
      DELIVERED: 'تم التوصيل',
    };

    this.orderStatusTemplates = {};
    for (const [status, label] of Object.entries(statusLabels)) {
      this.orderStatusTemplates[status] = [
        {
          build: (to: string, orderId: string, restaurantName: string) =>
            `📋 *${label}*\n—————————\nالطلب #${orderId}\n🏪 ${restaurantName}\n\nشكراً لطلبك من Jeeb 🛒`,
        },
        {
          build: (to: string, orderId: string, restaurantName: string) =>
            `مرحباً!\n\nطلبك #${orderId} من *${restaurantName}*:\n✅ ${label}\n\nلمزيد من التفاصيل، تابع التطبيق.\n- Jeeb`,
        },
        {
          build: (to: string, orderId: string, restaurantName: string) =>
            `[Jeeb] تحديث الطلب\n—————————\n\nالطلب: #${orderId}\nالمطعم: ${restaurantName}\nالحالة: ${label}\n\nتابع طلبك لحظة بلحظة من خلال التطبيق.`,
        },
        {
          build: (to: string, orderId: string, restaurantName: string) =>
            `👋 ${label} ✓\n\nالطلب رقم ${orderId}\nمن ${restaurantName}\n\nشكراً لاختيارك Jeeb 💙\n\nفريق الدعم`,
        },
      ];
    }
  }

  private async sendViaWasender(
    to: string,
    message: string,
    context: string,
  ): Promise<void> {
    if (!this.wasender) {
      this.logger.warn(`[WhatsApp] ${context} to ${to}: ${message}`);
      return;
    }
    try {
      const phoneNumber = normalizePhone(to);
      const result = await this.wasender.sendText({
        to: phoneNumber,
        text: message,
      });
      this.logger.log(`WhatsApp ${context} sent to ${to}`);
      return;
    } catch (error) {
      this.logger.error(
        `Failed to send WhatsApp ${context}: ${error}`,
      );
      if (
        error?.name === 'WasenderAPIError' &&
        (error?.statusCode === 422 ||
          error?.message?.includes('JID does not exist'))
      ) {
        throw new BadRequestException(
          'Phone number is not registered on WhatsApp. Please use a valid WhatsApp number.',
        );
      }
      throw error;
    }
  }

  async sendOtp(to: string, otp: string): Promise<void> {
    await this.checkOtpRateLimit(to);

    const template = this.pickVariant(this.otpTemplates);
    const message = template.build(to, otp);

    if (this.wasender) {
      await this.sendViaWasender(to, message, 'OTP');
      return;
    }

    if (this.twilioAccountSid && this.twilioAuthToken) {
      this.logger.debug('Twilio configuration found (Simulation mode)');
      return;
    }

    this.logger.warn(
      `No WhatsApp provider configured. Logging message: ${message}`,
    );
  }

  async sendWelcomeMessage(to: string, name: string): Promise<void> {
    const template = this.pickVariant(this.welcomeTemplates);
    const message = template.build(to, name);

    if (this.wasender) {
      await this.sendViaWasender(to, message, 'welcome');
      return;
    }

    this.logger.log(`[WhatsApp] Welcome Message to ${to}: ${message}`);
  }

  async sendCustomMessage(to: string, message: string): Promise<void> {
    await this.sendViaWasender(to, message, 'custom');
  }

  async sendOrderNotification(
    to: string,
    orderId: number,
    status: string,
    restaurantName: string,
  ): Promise<void> {
    const variants = this.orderStatusTemplates[status];
    if (!variants) {
      this.logger.warn(`No WhatsApp template for status: ${status}`);
      return;
    }

    const template = this.pickVariant(variants);
    const message = template.build(to, String(orderId), restaurantName);

    if (this.wasender) {
      await this.sendViaWasender(to, message, `order-${status}`);
      return;
    }

    this.logger.log(
      `[WhatsApp] Order Notification to ${to}: ${message}`,
    );
  }

}
