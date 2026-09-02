import {
  Controller,
  Get,
  Param,
  Query,
  Post,
  Body,
  Patch,
  BadRequestException,
  ParseIntPipe,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { Express } from 'express';
import { OrdersService } from './services/orders.service';
import { OrdersQueryDto } from './dto/orders-query.dto';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { UserRole } from '../../common/enums/user-role.enum';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order-items.dto';
import { UpdateOrderStatusDto } from './dto/update-order.dto';
import { UploadPaidReceiptDto } from './dto/upload-paid.dto';
import { UnassignDriverDto } from './dto/unassign-driver.dto';
import { UnassignDriverService } from './services/unassign-driver.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { UserPayload } from '../../common/interfaces/user-payload.interface';
import { ORDERS_ROUTES } from '../../common/constants/api-routes.constants';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiResponse,
  ApiQuery,
  ApiConsumes,
} from '@nestjs/swagger';
import { UseGuards } from '@nestjs/common';
import { AuthGuard } from '../../common/guards/auth.guard';
// Status validation mapping using enum values
const STATUS_MAP: Record<string, OrderStatus> = {
  // PENDING variations
  [OrderStatus.PENDING.toLowerCase()]: OrderStatus.PENDING,
  pending: OrderStatus.PENDING,

  // CONFIRMED variations
  [OrderStatus.CONFIRMED.toLowerCase()]: OrderStatus.CONFIRMED,
  confirmed: OrderStatus.CONFIRMED,
  confirm: OrderStatus.CONFIRMED,

  // SEARCHING variations
  [OrderStatus.SEARCHING.toLowerCase()]: OrderStatus.SEARCHING,
  searching: OrderStatus.SEARCHING,
  search: OrderStatus.SEARCHING,

  // PREPARING variations
  [OrderStatus.PREPARING.toLowerCase()]: OrderStatus.PREPARING,
  preparing: OrderStatus.PREPARING,
  prepare: OrderStatus.PREPARING,

  // READY_FOR_PICKUP variations
  [OrderStatus.READY_FOR_PICKUP.toLowerCase()]: OrderStatus.READY_FOR_PICKUP,
  ready_for_pickup: OrderStatus.READY_FOR_PICKUP,
  'ready-for-pickup': OrderStatus.READY_FOR_PICKUP,
  readyforpickup: OrderStatus.READY_FOR_PICKUP,
  ready: OrderStatus.READY_FOR_PICKUP,

  // ASSIGNED variations
  [OrderStatus.ASSIGNED.toLowerCase()]: OrderStatus.ASSIGNED,
  assigned: OrderStatus.ASSIGNED,
  assign: OrderStatus.ASSIGNED,

  // PICKED_UP variations
  [OrderStatus.PICKED_UP.toLowerCase()]: OrderStatus.PICKED_UP,
  picked_up: OrderStatus.PICKED_UP,
  pickedup: OrderStatus.PICKED_UP,
  'picked-up': OrderStatus.PICKED_UP,
  picked: OrderStatus.PICKED_UP,

  // ON_THE_WAY variations
  [OrderStatus.ON_THE_WAY.toLowerCase()]: OrderStatus.ON_THE_WAY,
  on_the_way: OrderStatus.ON_THE_WAY,
  'on-the-way': OrderStatus.ON_THE_WAY,
  ontheway: OrderStatus.ON_THE_WAY,

  // DELIVERED variations
  [OrderStatus.DELIVERED.toLowerCase()]: OrderStatus.DELIVERED,
  delivered: OrderStatus.DELIVERED,
  deliver: OrderStatus.DELIVERED,

  // CANCELLED variations
  [OrderStatus.CANCELLED.toLowerCase()]: OrderStatus.CANCELLED,
  cancelled: OrderStatus.CANCELLED,
  canceled: OrderStatus.CANCELLED,
  cancel: OrderStatus.CANCELLED,

  // REJECTED variations
  [OrderStatus.REJECTED.toLowerCase()]: OrderStatus.REJECTED,
  rejected: OrderStatus.REJECTED,
  reject: OrderStatus.REJECTED,

  // COMPLETE variations
  [OrderStatus.COMPLETE.toLowerCase()]: OrderStatus.COMPLETE,
  complete: OrderStatus.COMPLETE,

  // PAID variations
  [OrderStatus.PAID.toLowerCase()]: OrderStatus.PAID,
  paid: OrderStatus.PAID,
};

function validateOrderStatus(status: string): OrderStatus {
  const normalizedStatus = STATUS_MAP[status.toLowerCase()];
  if (!normalizedStatus) {
    throw new BadRequestException(`Invalid status: ${status}`);
  }
  return normalizedStatus;
}

@ApiTags('Orders')
@ApiBearerAuth('JWT-auth')
@Controller(ORDERS_ROUTES.BASE)
@UseGuards(AuthGuard)
export class OrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly unassignDriverService: UnassignDriverService,
  ) {}

  @Post()
  @ApiOperation({
    summary: 'إنشاء طلب جديد',
    description: 'إنشاء طلب جديد مع المنتجات والعروض',
  })
  @ApiBody({ type: CreateOrderDto })
  @ApiResponse({ status: 201, description: 'تم إنشاء الطلب بنجاح' })
  @ApiResponse({ status: 400, description: 'بيانات الطلب غير صحيحة' })
  create(
    @Body() createOrderDto: CreateOrderDto,
    @CurrentUser() user: UserPayload,
  ) {
    const userId = user ? user.id : 1;
    return this.ordersService.create(createOrderDto, userId);
  }

  @Get()
  @ApiOperation({
    summary: 'جلب جميع الطلبات',
    description: 'جلب جميع الطلبات مع إمكانية التصفية والبحث',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'رقم الصفحة',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'عدد العناصر',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    description: 'حالة الطلب (مفردة)',
  })
  @ApiQuery({
    name: 'statuses',
    required: false,
    description: 'حالات الطلب (متعددة مفصولة بفواصل)',
  })
  @ApiQuery({
    name: 'merchantId',
    required: false,
    type: Number,
    description: 'معرف التاجر',
  })
  @ApiQuery({
    name: 'startDate',
    required: false,
    description: 'تاريخ البداية',
  })
  @ApiQuery({ name: 'endDate', required: false, description: 'تاريخ النهاية' })
  @ApiQuery({ name: 'search', required: false, description: 'بحث' })
  @ApiQuery({
    name: 'categoryId',
    required: false,
    type: Number,
    description: 'معرف التصنيف',
  })
  @ApiResponse({ status: 200, description: 'تم جلب الطلبات بنجاح' })
  @ApiResponse({ status: 401, description: 'غير مصرح' })
  findAll(@Query() query: OrdersQueryDto, @CurrentUser() user: UserPayload) {
    return this.ordersService.findAll(query, user.id, user.role, query.status);
  }

  @Get(ORDERS_ROUTES.GET_ONE)
  @ApiOperation({
    summary: 'جلب طلب واحد',
    description: 'جلب تفاصيل طلب حسب المعرف',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiResponse({ status: 200, description: 'تم جلب الطلب بنجاح' })
  @ApiResponse({ status: 404, description: 'الطلب غير موجود' })
  @ApiResponse({ status: 403, description: 'ليس لديك صلاحية' })
  findOne(@Param('id') id: string, @CurrentUser() user: UserPayload) {
    return this.ordersService.findOne(+id, user.id, user.role);
  }

  @Patch(ORDERS_ROUTES.PAID)
  @ApiOperation({
    summary: 'رفع إيصال دفع',
    description: 'رفع إيصال دفع للطلبات (للمندوب فقط)',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    description: 'معرفات الطلبات والصور',
    schema: {
      type: 'object',
      properties: {
        orderIds: {
          type: 'string',
          description: 'معرفات الطلبات (JSON array أو comma-separated)',
          example: '[1, 2]',
        },
        images: {
          type: 'array',
          items: { type: 'string', format: 'binary' },
          description: 'صور الإيصالات (حد أقصى 5)',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'تم رفع الإيصال بنجاح' })
  @ApiResponse({ status: 400, description: 'بيانات غير صحيحة' })
  @ApiResponse({ status: 403, description: 'للمندوب فقط' })
  @UseInterceptors(FilesInterceptor('images', 5))
  uploadPaid(
    @Body() body: any,
    @UploadedFiles() files: Array<Express.Multer.File>,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    if (user.role !== UserRole.DELIVERY) {
      return { message: 'Only delivery drivers can upload payment receipts' };
    }

    const orderIds = Array.isArray(body.orderIds)
      ? body.orderIds
      : typeof body.orderIds === 'string'
        ? JSON.parse(body.orderIds)
        : [body.orderIds];

    return this.ordersService.uploadPaid(
      orderIds.map(Number),
      files,
      user.id,
      user.role,
    );
  }

  @Patch(':id/:status')
  @ApiOperation({
    summary: 'Update order status dynamically',
    description: 'Update order status with proper validation and notifications',
  })
  @ApiParam({ name: 'id', description: 'Order ID' })
  @ApiParam({
    name: 'status',
    description:
      'New status (confirm, confirmed, search, ready, picked, delivered, cancel, reject)',
  })
  @ApiBody({
    description: 'بيانات تحديث الحالة',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'سبب تغيير الحالة',
          example: 'تم تجهيز الطلب',
        },
        finalLocation: {
          type: 'object',
          description: 'الموقع النهائي للتوصيل',
          properties: {
            lat: { type: 'number', example: 33.5138 },
            lng: { type: 'number', example: 36.2767 },
          },
        },
        mealPreparationTime: {
          type: 'number',
          description: 'وقت التحضير (دقائق)',
          example: 20,
        },
        deliveryTime: {
          type: 'number',
          description: 'وقت التوصيل (دقائق)',
          example: 30,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'تم تحديث حالة الطلب بنجاح',
    schema: {
      example: {
        message: 'Order status updated successfully',
        order: {
          id: 1,
          status: 'CONFIRMED',
        },
      },
    },
  })
  @ApiResponse({ status: 400, description: 'حالة غير صالحة' })
  @ApiResponse({ status: 403, description: 'المصادقة مطلوبة' })
  @ApiResponse({ status: 404, description: 'الطلب غير موجود' })
  async updateOrderStatus(
    @Param('id', ParseIntPipe) id: number,
    @Param('status') status: string,
    @Body() body: UpdateOrderStatusDto,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    const validStatus = validateOrderStatus(status);

    // Get current order to check status transition
    const currentOrder = await this.ordersService.findOne(
      id,
      user.id,
      user.role,
    );

    // Update order status
    const result = await this.ordersService.updateOrderStatus(
      id,
      validStatus,
      user.id,
      user.role,
      body?.reason,
      body?.finalLocation,
      body?.mealPreparationTime,
      body?.deliveryTime,
    );

    // Trigger notifications for specific status changes
    if (
      validStatus === OrderStatus.READY_FOR_PICKUP &&
      currentOrder.status !== OrderStatus.READY_FOR_PICKUP
    ) {
      // Send notifications to delivery drivers
      await this.ordersService.sendDeliveryNotifications(id);
    }

    return result;
  }

  @Patch(ORDERS_ROUTES.UPDATE)
  @ApiOperation({
    summary: 'تحديث الطلب',
    description: 'تحديث منتجات وعروض الطلب',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({ type: UpdateOrderDto })
  @ApiResponse({ status: 200, description: 'تم تحديث الطلب بنجاح' })
  @ApiResponse({ status: 400, description: 'بيانات غير صحيحة' })
  updateOrder(
    @Param('id') id: string,
    @Body() updateOrderDto: UpdateOrderDto,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrder(
      +id,
      user.id,
      user.role,
      updateOrderDto,
    );
  }

  @Patch(ORDERS_ROUTES.CONFIRM)
  @ApiOperation({
    summary: 'تأكيد الطلب',
    description: 'تأكيد الطلب من قبل التاجر أو المدير',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'بيانات التأكيد',
    schema: {
      type: 'object',
      properties: {
        mealPreparationTime: {
          type: 'number',
          description: 'وقت التحضير (دقائق)',
          example: 20,
        },
        deliveryTime: {
          type: 'number',
          description: 'وقت التوصيل (دقائق)',
          example: 30,
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'تم تأكيد الطلب بنجاح' })
  @ApiResponse({ status: 400, description: 'لا يمكن تأكيد الطلب' })
  confirmOrder(
    @Param('id') id: string,
    @Body() body: { mealPreparationTime?: number; deliveryTime?: number },
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.CONFIRMED,
      user.id,
      user.role,
      'Order confirmed by merchant/admin',
      undefined,
      body?.mealPreparationTime,
      body?.deliveryTime,
    );
  }

  @Patch(ORDERS_ROUTES.CANCEL)
  @ApiOperation({
    summary: 'إلغاء الطلب',
    description: 'إلغاء الطلب مع إمكانية إضافة سبب',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'سبب الإلغاء',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'سبب الإلغاء',
          example: 'الزبون ألغى الطلب',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'تم إلغاء الطلب بنجاح' })
  @ApiResponse({ status: 400, description: 'لا يمكن إلغاء الطلب' })
  cancelOrder(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.CANCELLED,
      user.id,
      user.role,
      reason || 'Order cancelled',
    );
  }

  @Patch(ORDERS_ROUTES.REJECT)
  @ApiOperation({
    summary: 'رفض الطلب',
    description: 'رفض الطلب مع إمكانية إضافة سبب',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'سبب الرفض',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'سبب الرفض',
          example: 'الطلب غير متوفر',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'تم رفض الطلب بنجاح' })
  @ApiResponse({ status: 400, description: 'لا يمكن رفض الطلب' })
  rejectOrder(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.REJECTED,
      user.id,
      user.role,
      reason || 'Order rejected',
    );
  }

  @Patch(ORDERS_ROUTES.PREPARING)
  @ApiOperation({
    summary: 'بدء التحضير',
    description: 'تحديث حالة الطلب إلى قيد التحضير',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'ملاحظات',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'ملاحظات',
          example: 'جاري تحضير الطلب',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'تم بدء التحضير' })
  @ApiResponse({ status: 400, description: 'لا يمكن بدء التحضير' })
  startPreparing(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.PREPARING,
      user.id,
      user.role,
      reason || 'Order is being prepared',
    );
  }

  @Patch(ORDERS_ROUTES.READY_FOR_PICKUP)
  @ApiOperation({
    summary: 'جاهز للاستلام',
    description: 'تحديث حالة الطلب إلى جاهز للاستلام',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'ملاحظات',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'ملاحظات',
          example: 'الطلب جاهز للاستلام',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'تم تحديث الحالة إلى جاهز للاستلام',
  })
  @ApiResponse({ status: 400, description: 'لا يمكن تحديث الحالة' })
  readyForPickup(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.READY_FOR_PICKUP,
      user.id,
      user.role,
      reason || 'Order ready for pickup',
    );
  }

  @Patch(ORDERS_ROUTES.PICKED_UP)
  @ApiOperation({
    summary: 'تم الاستلام',
    description: 'تحديث حالة الطلب إلى تم الاستلام من قبل المندوب',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'ملاحظات',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'ملاحظات',
          example: 'تم استلام الطلب',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'تم تحديث الحالة إلى تم الاستلام' })
  @ApiResponse({ status: 400, description: 'لا يمكن تحديث الحالة' })
  pickedUp(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.PICKED_UP,
      user.id,
      user.role,
      reason || 'Order picked up by delivery',
    );
  }

  @Patch(ORDERS_ROUTES.ON_THE_WAY)
  @ApiOperation({
    summary: 'في الطريق',
    description: 'تحديث حالة الطلب إلى في الطريق للتوصيل',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'ملاحظات',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'ملاحظات',
          example: 'الطلب في الطريق',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'تم تحديث الحالة إلى في الطريق' })
  @ApiResponse({ status: 400, description: 'لا يمكن تحديث الحالة' })
  onTheWay(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.ON_THE_WAY,
      user.id,
      user.role,
      reason || 'Order on the way',
    );
  }

  @Patch(ORDERS_ROUTES.DELIVERED)
  @ApiOperation({
    summary: 'تم التوصيل',
    description:
      'تحديث حالة الطلب إلى تم التوصيل مع إمكانية إضافة الموقع النهائي',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'بيانات التوصيل',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'ملاحظات',
          example: 'تم التوصيل بنجاح',
        },
        finalLocation: {
          type: 'object',
          description: 'الموقع النهائي',
          properties: {
            lat: { type: 'number', example: 33.5138 },
            lng: { type: 'number', example: 36.2767 },
          },
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'تم تحديث الحالة إلى تم التوصيل' })
  @ApiResponse({ status: 400, description: 'لا يمكن تحديث الحالة' })
  delivered(
    @Param('id') id: string,
    @Body()
    body: { reason?: string; finalLocation?: { lat: number; lng: number } },
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.DELIVERED,
      user.id,
      user.role,
      body?.reason || 'Order delivered',
      body?.finalLocation,
    );
  }

  @Patch(ORDERS_ROUTES.PENDING)
  @ApiOperation({
    summary: 'إعادة إلى Pending',
    description: 'إعادة الطلب إلى حالة Pending',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiResponse({ status: 200, description: 'تم إعادة الطلب إلى Pending' })
  @ApiResponse({ status: 400, description: 'لا يمكن إعادة الطلب' })
  @ApiResponse({ status: 403, description: 'ليس لديك صلاحية' })
  restoreToPending(@Param('id') id: string, @CurrentUser() user: UserPayload) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.PENDING,
      user.id,
      user.role,
      'Order restored to pending',
    );
  }

  @Patch(ORDERS_ROUTES.COMPLETE)
  @ApiOperation({
    summary: 'إكمال الطلب',
    description: 'إكمال الطلب (للمدير فقط)',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiResponse({ status: 200, description: 'تم إكمال الطلب بنجاح' })
  @ApiResponse({ status: 400, description: 'لا يمكن إكمال الطلب' })
  @ApiResponse({ status: 403, description: 'للمدير فقط' })
  @ApiResponse({ status: 404, description: 'الطلب غير موجود' })
  completeOrder(@Param('id') id: string, @CurrentUser() user: UserPayload) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    if (user.role !== UserRole.ADMIN) {
      return { message: 'Only admins can complete orders' };
    }

    return this.ordersService.updateOrderStatus(
      +id,
      OrderStatus.COMPLETE,
      user.id,
      user.role,
      'Order completed by admin',
    );
  }

  @Patch(ORDERS_ROUTES.UNASSIGN_DRIVER)
  @ApiOperation({
    summary: 'إزالة مندوب من الطلب (أدمن فقط)',
    description: 'إزالة المندوب الحالي مع خيار auto_search أو manual_assign',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiResponse({ status: 200, description: 'تم إزالة المندوب بنجاح' })
  @ApiResponse({ status: 400, description: 'لا يوجد تعيين نشط' })
  @ApiResponse({ status: 403, description: 'للمدير فقط' })
  @ApiResponse({ status: 404, description: 'الطلب غير موجود' })
  unassignDriver(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UnassignDriverDto,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }
    if (user.role !== UserRole.ADMIN) {
      return { message: 'Only admins can unassign drivers' };
    }
    return this.unassignDriverService.execute(id, dto, user);
  }

  // Delivery Assignment Endpoints

  @Post(ORDERS_ROUTES.SEND_NOTIFICATIONS)
  @ApiOperation({
    summary: 'إرسال إشعارات للمندوبين',
    description: 'إرسال إشعارات للمندوبين بوجود طلب جديد',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiResponse({ status: 201, description: 'تم إرسال الإشعارات بنجاح' })
  @ApiResponse({ status: 400, description: 'فشل إرسال الإشعارات' })
  sendDeliveryNotifications(
    @Param('id') id: string,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    return this.ordersService.sendDeliveryNotifications(+id);
  }

  @Post(ORDERS_ROUTES.ACCEPT_DELIVERY)
  @ApiOperation({
    summary: 'قبول التوصيل',
    description: 'قبول مهمة التوصيل من قبل المندوب',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'بيانات القبول',
    schema: {
      type: 'object',
      properties: {
        deliveryTime: {
          type: 'number',
          description: 'وقت التوصيل المتوقع (دقائق)',
          example: 25,
        },
      },
    },
  })
  @ApiResponse({ status: 201, description: 'تم قبول التوصيل بنجاح' })
  @ApiResponse({ status: 400, description: 'لا يمكن قبول التوصيل' })
  @ApiResponse({ status: 403, description: 'للمندوب فقط' })
  acceptDeliveryAssignment(
    @Param('id') id: string,
    @Body() body: { deliveryTime?: number },
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    // Only delivery drivers can accept assignments
    if (user.role !== UserRole.DELIVERY) {
      return { message: 'Only delivery drivers can accept assignments' };
    }

    return this.ordersService.acceptDeliveryAssignment(
      +id,
      user.id,
      body.deliveryTime,
    );
  }

  @Post(ORDERS_ROUTES.REJECT_DELIVERY)
  @ApiOperation({
    summary: 'رفض التوصيل',
    description: 'رفض مهمة التوصيل من قبل المندوب',
  })
  @ApiParam({ name: 'id', description: 'معرف الطلب', type: Number })
  @ApiBody({
    description: 'سبب الرفض',
    schema: {
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          description: 'سبب الرفض',
          example: 'الطلب بعيد جداً',
        },
      },
    },
  })
  @ApiResponse({ status: 201, description: 'تم رفض التوصيل' })
  @ApiResponse({ status: 400, description: 'لا يمكن رفض التوصيل' })
  @ApiResponse({ status: 403, description: 'للمندوب فقط' })
  rejectDeliveryAssignment(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentUser() user: UserPayload,
  ) {
    if (!user) {
      return { message: 'Authentication required' };
    }

    // Only delivery drivers can reject assignments
    if (user.role !== UserRole.DELIVERY) {
      return { message: 'Only delivery drivers can accept assignments' };
    }

    return this.ordersService.rejectDeliveryAssignment(+id, user.id, reason);
  }
}
