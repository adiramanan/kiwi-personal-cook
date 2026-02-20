import { describe, it, expect, vi, beforeEach } from "vitest";
import { Hono } from "hono";

vi.mock("../../src/services/llm.js", () => ({
  analyzeImage: vi.fn(),
  LLMError: class LLMError extends Error {
    constructor(msg: string) {
      super(msg);
      this.name = "LLMError";
    }
  },
}));

vi.mock("../../src/models/quota.js", () => ({
  incrementScanCount: vi.fn(),
  getScanCount: vi.fn().mockResolvedValue(0),
}));

vi.mock("../../src/utils/logger.js", () => ({
  logger: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

const validScanResult = {
  ingredients: [
    { id: "550e8400-e29b-41d4-a716-446655440000", name: "Eggs", category: "Protein", confidence: 0.95 },
  ],
  recipes: [
    {
      id: "550e8400-e29b-41d4-a716-446655440010",
      name: "Scrambled Eggs",
      summary: "Quick and easy",
      cookTimeMinutes: 5,
      difficulty: "easy",
      ingredients: [
        { id: "550e8400-e29b-41d4-a716-446655440020", name: "Eggs", isDetected: true, substitution: null },
      ],
      steps: ["Crack eggs", "Cook"],
      makeItFasterTip: null,
    },
  ],
};

function createJpegBlob(sizeBytes = 1024): Blob {
  const data = new Uint8Array(sizeBytes);
  data[0] = 0xff;
  data[1] = 0xd8;
  data[2] = 0xff;
  return new Blob([data], { type: "image/jpeg" });
}

describe("POST /v1/scan", () => {
  let app: Hono;

  beforeEach(async () => {
    vi.clearAllMocks();
    process.env.OPENAI_API_KEY = "test-key";

    app = new Hono();
    app.use("/*", async (c, next) => {
      c.set("userId", "user-123");
      await next();
    });

    const scanRoutes = (await import("../../src/routes/scan.js")).default;
    app.route("/v1/scan", scanRoutes);
  });

  it("returns 200 with valid JPEG and successful LLM response", async () => {
    const { analyzeImage } = await import("../../src/services/llm.js");
    (analyzeImage as ReturnType<typeof vi.fn>).mockResolvedValueOnce(validScanResult);

    const formData = new FormData();
    formData.append("image", createJpegBlob());

    const res = await app.request("/v1/scan", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ingredients).toHaveLength(1);
    expect(body.recipes).toHaveLength(1);
  });

  it("returns 400 when no image provided", async () => {
    const formData = new FormData();

    const res = await app.request("/v1/scan", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(400);
  });

  it("returns 400 for non-JPEG content type", async () => {
    const formData = new FormData();
    formData.append("image", new Blob([new Uint8Array(100)], { type: "image/png" }));

    const res = await app.request("/v1/scan", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(400);
  });

  it("returns 502 when LLM returns invalid response", async () => {
    const { analyzeImage, LLMError } = await import("../../src/services/llm.js");
    (analyzeImage as ReturnType<typeof vi.fn>).mockRejectedValueOnce(
      new LLMError("Invalid JSON from model")
    );

    const formData = new FormData();
    formData.append("image", createJpegBlob());

    const res = await app.request("/v1/scan", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(502);
    const body = await res.json();
    expect(body.error).toBe("invalid_model_response");
  });
});
