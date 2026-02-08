const MAX_IMAGE_SIZE = 2 * 1024 * 1024; // 2 MB
const JPEG_MAGIC_BYTES = [0xff, 0xd8, 0xff];

export class ImageValidationError extends Error {
  constructor(
    message: string,
    public readonly code: "INVALID_TYPE" | "TOO_LARGE" | "EMPTY" | "INVALID_BYTES"
  ) {
    super(message);
    this.name = "ImageValidationError";
  }
}

export function validateImage(
  data: ArrayBuffer | Uint8Array,
  contentType: string | undefined
): void {
  const bytes = data instanceof Uint8Array ? data : new Uint8Array(data);

  // Check empty
  if (bytes.length === 0) {
    throw new ImageValidationError("Image file is empty", "EMPTY");
  }

  // Check content type
  if (contentType && !contentType.includes("image/jpeg")) {
    throw new ImageValidationError(
      `Invalid content type: ${contentType}. Only image/jpeg is accepted.`,
      "INVALID_TYPE"
    );
  }

  // Check file size
  if (bytes.length > MAX_IMAGE_SIZE) {
    throw new ImageValidationError(
      `Image size ${bytes.length} exceeds maximum of ${MAX_IMAGE_SIZE} bytes`,
      "TOO_LARGE"
    );
  }

  // Check JPEG magic bytes
  if (
    bytes.length < 3 ||
    bytes[0] !== JPEG_MAGIC_BYTES[0] ||
    bytes[1] !== JPEG_MAGIC_BYTES[1] ||
    bytes[2] !== JPEG_MAGIC_BYTES[2]
  ) {
    throw new ImageValidationError(
      "File does not appear to be a valid JPEG (invalid magic bytes)",
      "INVALID_BYTES"
    );
  }
}
