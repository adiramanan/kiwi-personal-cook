export class ImageValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ImageValidationError";
  }
}

export const MAX_IMAGE_BYTES = 2 * 1024 * 1024;

export function validateImage(contentType: string | null, buffer: Buffer) {
  if (contentType !== "image/jpeg") {
    throw new ImageValidationError("invalid_content_type");
  }
  if (!buffer || buffer.length === 0) {
    throw new ImageValidationError("empty_file");
  }
  if (buffer.length > MAX_IMAGE_BYTES) {
    throw new ImageValidationError("file_too_large");
  }
  const isJpeg = buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  if (!isJpeg) {
    throw new ImageValidationError("invalid_magic_bytes");
  }
}
