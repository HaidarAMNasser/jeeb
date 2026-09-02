import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { VersioningType, Logger, ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import express from 'express';
import helmet from 'helmet';
import { RequestTimeoutMiddleware } from './common/middleware/request-timeout.middleware';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Security: CORS Configuration for Flutter Mobile Apps
  app.enableCors({
    origin: [
      'app://*',
      'capacitor://*',
      'io.ionic*',
      'com.jeeb*',
      'http://localhost',
      'http://localhost:*',
    ],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    credentials: true,
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept',
      'Origin',
      'X-Requested-With',
      'X-Custom-Header',
    ],
  });

  // Security: Helmet headers (XSS protection, clickjacking prevention, etc.)
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          'script-src': ["'self'", "'unsafe-inline'", 'cdn.tailwindcss.com'],
          'script-src-attr': ["'self'", "'unsafe-inline'"],
          'style-src': [
            "'self'",
            "'unsafe-inline'",
            'fonts.googleapis.com',
            'fonts.gstatic.com',
          ],
          'style-src-elem': [
            "'self'",
            "'unsafe-inline'",
            'fonts.googleapis.com',
            'fonts.gstatic.com',
            'cdn.tailwindcss.com',
          ],
          'img-src': ["'self'", 'data:', 'https:'],
          'connect-src': ["'self'", 'https:'],
          'font-src': ["'self'", 'fonts.gstatic.com', 'fonts.googleapis.com'],
        },
      },
    }),
  );

  // Security: Body size limits (prevent large payload attacks)
  app.use(express.json({ limit: '100kb' }));
  app.use(express.urlencoded({ extended: true, limit: '100kb' }));

  // Security: Request timeout (30 seconds)
  app.use(new RequestTimeoutMiddleware().use);

  // Request logging middleware (minimal)
  app.use((req, res, next) => {
    next();
  });

  // Raw body logging for Offers endpoints (before validation)
  app.use(
    (
      req: express.Request,
      res: express.Response,
      next: express.NextFunction,
    ) => {
      if (
        req.path.startsWith('/api/') &&
        (req.path.includes('/offers') || req.path.includes('/orders'))
      ) {
      }
      next();
    },
  );

  // Serve front-end static files (Orders Panel) - BEFORE global prefix
  app.use(
    '/orders-panel',
    express.static('/root/var/www/src_v1/Jeeb_NestJs/front-end', {
      index: 'index.html',
    }),
  );

  // Set Global Prefix FIRST (e.g., /api/route)
  app.setGlobalPrefix('api');

  // Enable URI Versioning AFTER global prefix (e.g., /api/v1/route)
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Serve static files (favicon, robots.txt, etc.)
  app.useStaticAssets(join(process.cwd(), 'public'), {
    prefix: '/',
  });

  // Serve uploaded files
  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads',
  });

  // Throttler (Rate Limiting) - DOS Protection
  // Note: ThrottlerModule is now imported in AppModule
  // Guard is applied globally via APP_GUARD provider

  // Swagger Documentation Setup
  const config = new DocumentBuilder()
    .setTitle('Delivery Jeeb API')
    .setDescription(
      'Complete API documentation for Delivery Jeeb food delivery platform',
    )
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT token',
        in: 'header',
      },
      'JWT-auth',
    )
    .addTag('Auth', 'Authentication endpoints')
    .addTag('Merchants', 'Merchant management (Admin only)')
    .addTag('Customers', 'Customer management')
    .addTag('Restaurants', 'Restaurant management')
    .addTag('Products', 'Product management')
    .addTag('Orders', 'Order management')
    .addTag('Coupons', 'Coupon management')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
    },
    customSiteTitle: 'Delivery Jeeb API Docs',
  });

  logger.log('Swagger documentation available at: /api/docs');

  // Global Pipes
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: false,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global Interceptors
  app.useGlobalInterceptors(new TransformInterceptor());

  // Global Filters
  app.useGlobalFilters(new AllExceptionsFilter());

  const port = process.env.PORT || 3000;
  await app.listen(port);
  logger.log(`Application is running on: http://localhost:${port}/api/v1`);
  logger.log(`API Documentation: http://localhost:${port}/api/docs`);
}
void bootstrap();
