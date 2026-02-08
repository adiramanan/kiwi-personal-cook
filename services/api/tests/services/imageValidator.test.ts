import { describe, it, expect } from "vitest";
import { validateImage, ImageValidationError } from "../../src/services/imageValidator.js";

function createJpegData(size: number): Uint8Array {
  const data = new Uint8Array(size);
  // JPEG magic bytes
  data[0] = 0xff;
  data[1] = 0xd8;
  data[2] = 0xff;
  return data;
}

describe("Image Validator", () => {
  it("should accept valid JPEG under 2MB", () => {
    const jpegData = createJpegData(1024);
    expect(() => validateImage(jpegData, "image/jpeg")).not.toThrow();
  });

  it("should accept valid JPEG at exactly 2MB", () => {
    const jpegData = createJpegData(2 * 1024 * 1024);
    expect(() => validateImage(jpegData, "image/jpeg")).not.toThrow();
  });

  it("should reject PNG file", () => {
    const pngData = new Uint8Array([0x89, 0x50, 0x4e, 0x47]);

    expect(() => validateImage(pngData, "image/png")).toThrow(ImageValidationError);

    try {
      validateImage(pngData, "image/png");
    } catch (error) {
      expect((error as ImageValidationError).code).toBe("INVALID_TYPE");
    }
  });

  it("should reject JPEG over 2MB", () => {
    const largeJpeg = createJpegData(3 * 1024 * 1024);

    expect(() => validateImage(largeJpeg, "image/jpeg")).toThrow(ImageValidationError);

    try {
      validateImage(largeJpeg, "image/jpeg");
    } catch (error) {
      expect((error as ImageValidationError).code).toBe("TOO_LARGE");
    }
  });

  it("should reject empty file", () => {
    const emptyData = new Uint8Array(0);

    expect(() => validateImage(emptyData, "image/jpeg")).toThrow(ImageValidationError);

    try {
      validateImage(emptyData, "image/jpeg");
    } catch (error) {
      expect((error as ImageValidationError).code).toBe("EMPTY");
    }
  });

  it("should reject file with wrong magic bytes", () => {
    const badData = new Uint8Array([0x00, 0x00, 0x00, 0x00]);

    expect(() => validateImage(badData, "image/jpeg")).toThrow(ImageValidationError);

    try {
      validateImage(badData, "image/jpeg");
    } catch (error) {
      expect((error as ImageValidationError).code).toBe("INVALID_BYTES");
    }
  });

  it("should accept when no content type is provided but magic bytes are valid", () => {
    const jpegData = createJpegData(1024);
    expect(() => validateImage(jpegData, undefined)).not.toThrow();
  });
});
