import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { CartService } from './cart.service';
import { CreateCartDto } from './dto/create-cart.dto';
import { UpdateCartActionsDto } from './dto/update-cart.dto';
import { AuthGuard } from '../../common/guards/auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AllowGuest } from '../../common/decorators/allow-guest.decorator';
import type { UserPayload } from '../../common/interfaces/user-payload.interface';
import { ApiOperation, ApiResponse } from '@nestjs/swagger';

@Controller('cart')
@UseGuards(AuthGuard)
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Get()
  @ApiOperation({ summary: 'Get current cart' })
  @ApiResponse({
    status: 200,
    description: 'Returns the current cart with all items and offers',
  })
  async getCart(@CurrentUser() user: UserPayload) {
    const cart = await this.cartService.getCart(user.id, !!(user as any).is_guest);
    if (!cart) {
      return {
        statusCode: 200,
        message: 'Cart is empty',
        data: null,
      };
    }
    return {
      statusCode: 200,
      message: 'Operation successful',
      data: cart,
    };
  }

  @Post()
  @AllowGuest()
  @ApiOperation({ summary: 'Create or replace cart' })
  @ApiResponse({
    status: 201,
    description: 'Creates or replaces the entire cart',
  })
  async createCart(
    @Body() createCartDto: CreateCartDto,
    @CurrentUser() user: UserPayload,
  ) {
    const cart = await this.cartService.createCart(user.id, createCartDto, !!(user as any).is_guest);
    return {
      statusCode: 201,
      message: 'Operation successful',
      data: cart,
    };
  }

  @Patch()
  @AllowGuest()
  @ApiOperation({ summary: 'Update cart (add, update, or remove items)' })
  @ApiResponse({
    status: 200,
    description: 'Updates the cart with add/update/remove actions',
  })
  async updateCart(
    @Body() updateCartDto: UpdateCartActionsDto,
    @CurrentUser() user: UserPayload,
  ) {
    const cart = await this.cartService.updateCart(user.id, updateCartDto, !!(user as any).is_guest);
    return {
      statusCode: 200,
      message: 'Operation successful',
      data: cart,
    };
  }

  @Delete()
  @AllowGuest()
  @ApiOperation({ summary: 'Clear cart' })
  @ApiResponse({
    status: 200,
    description: 'Removes all items and offers from the cart',
  })
  async clearCart(@CurrentUser() user: UserPayload) {
    await this.cartService.clearCart(user.id, !!(user as any).is_guest);
    return {
      statusCode: 200,
      message: 'Cart cleared successfully',
      data: null,
    };
  }
}
