const JPEG_MAGIC_BYTES = Buffer.from([0xff, 0xd8, 0xff]);
const MAX_SIZE_BYTES = 2 * 1024 * 1024; // 2 MB

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

export function validateImage(
  data: Buffer | ArrayBuffer,
  contentType?: string
): ValidationResult {
  const buffer = Buffer.isBuffer(data) ? data : Buffer.from(data);

  if (buffer.length === 0) {
    return { valid: false, error: "Empty file" };
  }

  if (buffer.length > MAX_SIZE_BYTES) {
    return {
      valid: false,
      error: `Image exceeds maximum size of ${MAX_SIZE_BYTES / 1024 / 1024}MB`,
    };
  }

  if (contentType && contentType !== "image/jpeg") {
    return { valid: false, error: "Only JPEG images are accepted" };
  }

  if (buffer.length >= 3 && !buffer.subarray(0, 3).equals(JPEG_MAGIC_BYTES)) {
    return { valid: false, error: "File does not appear to be a valid JPEG" };
  }

  return { valid: true };
}
