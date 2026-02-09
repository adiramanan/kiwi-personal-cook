import { describe, expect, it } from "vitest";
import { validateImage } from "../../src/services/imageValidator";

const jpegHeader = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01]);

describe("imageValidator", () => {
  it("accepts valid jpeg", () => {
    expect(() => validateImage("image/jpeg", jpegHeader)).not.toThrow();
  });

  it("rejects non-jpeg", () => {
    expect(() => validateImage("image/png", jpegHeader)).toThrow();
  });
});
