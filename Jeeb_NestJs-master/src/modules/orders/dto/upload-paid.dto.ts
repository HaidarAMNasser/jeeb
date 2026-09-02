import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UploadPaidReceiptDto {
  @ApiProperty({
    description: 'معرفات الطلبات (array أو JSON string في form-data)',
    example: [1, 2],
  })
  orderIds: any;
}

export class UploadPaidReceiptResponseDto {
  @ApiProperty({ description: 'معرف الطلب', example: 1 })
  orderId: number;

  @ApiProperty({ description: 'الحالة', example: 'PAID' })
  status: string;

  @ApiProperty({
    description: 'إيصالات الدفع المرفوعة',
    type: 'array',
    example: [{ id: 1, imageId: 10, url: 'https://example.com/receipt.jpg' }],
  })
  paymentReceipts: {
    id: number;
    imageId: number;
    url: string;
  }[];
}
