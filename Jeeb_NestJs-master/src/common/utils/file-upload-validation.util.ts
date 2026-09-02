import { HttpException, HttpStatus } from '@nestjs/common';

export const ALLOWED_IMAGE_MIMETYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/gif',
  'image/webp',
];

export const ALLOWED_IMAGE_EXTENSIONS = [
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
];

export const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

export const IMAGE_SIGNATURES: Record<string, number[]> = {
  'image/jpeg': [0xff, 0xd8, 0xff],
  'image/png': [0x89, 0x50, 0x4e, 0x47],
  'image/gif': [0x47, 0x49, 0x46],
  'image/webp': [0x52, 0x49, 0x46, 0x46],
};

export function validateFileMimetype(mimetype: string): boolean {
  return ALLOWED_IMAGE_MIMETYPES.includes(mimetype.toLowerCase());
}

export function validateFileExtension(filename: string): boolean {
  const ext = filename.substring(filename.lastIndexOf('.')).toLowerCase();
  return ALLOWED_IMAGE_EXTENSIONS.includes(ext);
}

export function validateFileSignature(buffer: Buffer): boolean {
  if (!buffer || buffer.length < 4) {
    return false;
  }

  for (const [mimetype, signature] of Object.entries(IMAGE_SIGNATURES)) {
    const isMatch = signature.every((byte, index) => buffer[index] === byte);
    if (isMatch) {
      return true;
    }
  }

  return false;
}

export function validateImageFile(
  file: Express.Multer.File,
  options?: { checkSignature?: boolean },
): void {
  if (!file) {
    throw new HttpException('File is required', HttpStatus.BAD_REQUEST);
  }

  if (file.size > MAX_FILE_SIZE) {
    throw new HttpException(
      `File size exceeds maximum allowed size of 5MB`,
      HttpStatus.BAD_REQUEST,
    );
  }

  if (!validateFileMimetype(file.mimetype)) {
    throw new HttpException(
      `Invalid file type. Allowed types: ${ALLOWED_IMAGE_EXTENSIONS.join(', ')}`,
      HttpStatus.BAD_REQUEST,
    );
  }

  if (options?.checkSignature !== false && file.buffer) {
    if (!validateFileSignature(file.buffer)) {
      throw new HttpException(
        'Invalid file content. File does not appear to be a valid image.',
        HttpStatus.BAD_REQUEST,
      );
    }
  }
}

export function createFileFilter() {
  return (req: any, file: Express.Multer.File, cb: any) => {
    if (!file) {
      cb(new HttpException('No file provided', HttpStatus.BAD_REQUEST), false);
      return;
    }

    if (!validateFileMimetype(file.mimetype)) {
      cb(
        new HttpException(
          `Invalid file type: ${file.mimetype}. Allowed: ${ALLOWED_IMAGE_MIMETYPES.join(', ')}`,
          HttpStatus.BAD_REQUEST,
        ),
        false,
      );
      return;
    }

    if (!validateFileExtension(file.originalname)) {
      cb(
        new HttpException(
          `Invalid file extension. Allowed: ${ALLOWED_IMAGE_EXTENSIONS.join(', ')}`,
          HttpStatus.BAD_REQUEST,
        ),
        false,
      );
      return;
    }

    cb(null, true);
  };
}

export const FILE_UPLOAD_CONFIG = {
  limits: {
    fileSize: MAX_FILE_SIZE,
  },
  fileFilter: createFileFilter(),
};
