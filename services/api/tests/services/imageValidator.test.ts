import { describe, it, expect } from "vitest";
import { validateImage } from "../../src/services/imageValidator.js";

describe("imageValidator", () => {
  const validJpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, ...new Array(100).fill(0)]);

  it("accepts a valid JPEG under 2MB", () => {
    const result = validateImage(validJpeg, "image/jpeg");
    expect(result.valid).toBe(true);
  });

  it("rejects an empty file", () => {
    const result = validateImage(Buffer.from([]), "image/jpeg");
    expect(result.valid).toBe(false);
    expect(result.error).toContain("Empty");
  });

  it("rejects a PNG content type", () => {
    const result = validateImage(validJpeg, "image/png");
    expect(result.valid).toBe(false);
    expect(result.error).toContain("JPEG");
  });

  it("rejects a file over 2MB", () => {
    const largeBuffer = Buffer.alloc(2 * 1024 * 1024 + 1, 0xff);
    largeBuffer[0] = 0xff;
    largeBuffer[1] = 0xd8;
    largeBuffer[2] = 0xff;
    const result = validateImage(largeBuffer, "image/jpeg");
    expect(result.valid).toBe(false);
    expect(result.error).toContain("size");
  });

  it("rejects a file without JPEG magic bytes", () => {
    const notJpeg = Buffer.from([0x89, 0x50, 0x4e, 0x47, ...new Array(100).fill(0)]);
    const result = validateImage(notJpeg);
    expect(result.valid).toBe(false);
    expect(result.error).toContain("valid JPEG");
  });
});
