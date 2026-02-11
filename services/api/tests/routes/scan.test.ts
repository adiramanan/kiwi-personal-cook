import { beforeEach, describe, expect, it, vi } from "vitest";
import { Hono } from "hono";
import type { AppEnv } from "../../src/types";

const { analyzeImageMock, incrementQuotaMock } = vi.hoisted(() => ({
  analyzeImageMock: vi.fn(),
  incrementQuotaMock: vi.fn(),
}));

vi.mock("../../src/services/llm", () => ({
  analyzeImage: analyzeImageMock,
}));

vi.mock("../../src/middleware/rateLimit", () => ({
  incrementQuota: incrementQuotaMock,
}));

import { scanRoutes } from "../../src/routes/scan";
import { ScanResponseSchema } from "../../src/schema/scanResponse";

const validScanResponse = {
  ingredients: [
    {
      id: "11111111-1111-4111-8111-111111111111",
      name: "Eggs",
      category: "Protein",
      confidence: 0.95,
    },
  ],
  recipes: [
    {
      id: "22222222-2222-4222-8222-222222222222",
      name: "Quick Eggs",
      summary: "Fast eggs",
      cookTimeMinutes: 10,
      difficulty: "easy",
      ingredients: [
        {
          id: "33333333-3333-4333-8333-333333333333",
          name: "Eggs",
          isDetected: true,
          substitution: null,
        },
      ],
      steps: ["Cook eggs."],
      makeItFasterTip: "Use a non-stick pan.",
    },
  ],
};

function makeApp() {
  const app = new Hono<AppEnv>();
  app.use("*", async (c, next) => {
    c.set("userId", "user-123");
    await next();
  });
  app.route("/", scanRoutes);
  return app;
}

function makeJpegBlob(size = 16): Blob {
  const bytes = new Uint8Array(size);
  bytes[0] = 0xff;
  bytes[1] = 0xd8;
  bytes[2] = 0xff;
  return new Blob([bytes.buffer], { type: "image/jpeg" });
}

function makeScanRequest(file: File) {
  const form = new FormData();
  form.set("image", file);
  return new Request("http://localhost/v1/scan", {
    method: "POST",
    body: form,
  });
}

describe("POST /v1/scan", () => {
  beforeEach(() => {
    analyzeImageMock.mockReset();
    incrementQuotaMock.mockReset();
  });

  it("returns 200 with valid jpeg and valid LLM response", async () => {
    analyzeImageMock.mockResolvedValueOnce(validScanResponse);
    incrementQuotaMock.mockResolvedValueOnce(undefined);

    const app = makeApp();
    const file = new File([makeJpegBlob()], "fridge.jpg", { type: "image/jpeg" });
    const res = await app.fetch(makeScanRequest(file));

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(ScanResponseSchema.safeParse(body).success).toBe(true);
    expect(incrementQuotaMock).toHaveBeenCalledWith("user-123");
  });

  it("returns 400 for non-jpeg content type", async () => {
    const app = makeApp();
    const file = new File([makeJpegBlob()], "fridge.png", { type: "image/png" });
    const res = await app.fetch(makeScanRequest(file));

    expect(res.status).toBe(400);
  });

  it("returns 400 for image over 2MB", async () => {
    const app = makeApp();
    const file = new File([makeJpegBlob(2 * 1024 * 1024 + 1)], "fridge.jpg", { type: "image/jpeg" });
    const res = await app.fetch(makeScanRequest(file));

    expect(res.status).toBe(400);
  });

  it("returns 502 when LLM returns invalid JSON", async () => {
    analyzeImageMock.mockRejectedValueOnce(new Error("invalid_json"));

    const app = makeApp();
    const file = new File([makeJpegBlob()], "fridge.jpg", { type: "image/jpeg" });
    const res = await app.fetch(makeScanRequest(file));

    expect(res.status).toBe(502);
  });

  it("returns 502 when LLM returns off-schema JSON", async () => {
    analyzeImageMock.mockRejectedValueOnce(new Error("schema_validation_failed"));

    const app = makeApp();
    const file = new File([makeJpegBlob()], "fridge.jpg", { type: "image/jpeg" });
    const res = await app.fetch(makeScanRequest(file));

    expect(res.status).toBe(502);
  });
});
