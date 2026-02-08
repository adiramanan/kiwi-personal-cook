import { describe, it, expect, vi, beforeEach } from "vitest";
import { Hono } from "hono";
import { v4 as uuidv4 } from "uuid";

// Mock the LLM service
vi.mock("../../src/services/llm.js", () => ({
  analyzeImage: vi.fn(),
  LLMServiceError: class LLMServiceError extends Error {
    code: string;
    constructor(message: string, code: string) {
      super(message);
      this.name = "LLMServiceError";
      this.code = code;
    }
  },
}));

import { analyzeImage, LLMServiceError } from "../../src/services/llm.js";
import { scanRoutes } from "../../src/routes/scan.js";
import type { Config } from "../../src/utils/config.js";

const mockConfig: Config = {
  port: 3000,
  databaseUrl: "postgresql://localhost/test",
  openaiApiKey: "sk-test-key",
  appleTeamId: "TEAM123",
  appleClientId: "com.kiwi.app",
  appleKeyId: "KEY123",
  logLevel: "silent",
};

function createMockSql() {
  const mockSql = vi.fn().mockResolvedValue([]) as any;
  mockSql.end = vi.fn();
  return mockSql;
}

function createTestApp(sql: any) {
  const app = new Hono();
  // Simulate auth middleware
  app.use("/*", async (c, next) => {
    c.set("userId" as any, "test-user-id");
    await next();
  });
  app.route("/", scanRoutes(sql, mockConfig));
  return app;
}

function createValidJpegBlob(sizeBytes: number = 1024): Blob {
  const data = new Uint8Array(sizeBytes);
  // JPEG magic bytes
  data[0] = 0xff;
  data[1] = 0xd8;
  data[2] = 0xff;
  return new Blob([data], { type: "image/jpeg" });
}

function createValidScanResponse() {
  return {
    ingredients: [
      {
        id: uuidv4(),
        name: "Eggs",
        category: "Protein",
        confidence: 0.95,
      },
    ],
    recipes: [
      {
        id: uuidv4(),
        name: "Quick Omelette",
        summary: "A fast omelette with whatever you have.",
        cookTimeMinutes: 10,
        difficulty: "easy" as const,
        ingredients: [
          {
            id: uuidv4(),
            name: "Eggs",
            isDetected: true,
            substitution: null,
          },
        ],
        steps: ["Crack eggs", "Cook in pan"],
        makeItFasterTip: "Use a non-stick pan",
      },
    ],
  };
}

describe("Scan Route", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should return 200 with valid JPEG and valid LLM response", async () => {
    const mockResponse = createValidScanResponse();
    vi.mocked(analyzeImage).mockResolvedValue(mockResponse);
    const sql = createMockSql();
    const app = createTestApp(sql);

    const formData = new FormData();
    formData.append("image", createValidJpegBlob(), "fridge.jpg");

    const res = await app.request("/", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ingredients).toHaveLength(1);
    expect(body.ingredients[0].name).toBe("Eggs");
    expect(body.recipes).toHaveLength(1);
    expect(body.recipes[0].name).toBe("Quick Omelette");
  });

  it("should return 400 for non-JPEG content type", async () => {
    const sql = createMockSql();
    const app = createTestApp(sql);

    const pngData = new Uint8Array([0x89, 0x50, 0x4e, 0x47]); // PNG magic bytes
    const formData = new FormData();
    formData.append("image", new Blob([pngData], { type: "image/png" }), "fridge.png");

    const res = await app.request("/", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toBe("bad_request");
  });

  it("should return 400 for image over 2MB", async () => {
    const sql = createMockSql();
    const app = createTestApp(sql);

    const formData = new FormData();
    formData.append("image", createValidJpegBlob(3 * 1024 * 1024), "fridge.jpg");

    const res = await app.request("/", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toBe("bad_request");
  });

  it("should return 502 when LLM returns invalid JSON", async () => {
    vi.mocked(analyzeImage).mockRejectedValue(
      new (LLMServiceError as any)("LLM response is not valid JSON", "PARSE_ERROR")
    );
    const sql = createMockSql();
    const app = createTestApp(sql);

    const formData = new FormData();
    formData.append("image", createValidJpegBlob(), "fridge.jpg");

    const res = await app.request("/", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(502);
    const body = await res.json();
    expect(body.error).toBe("invalid_model_response");
  });

  it("should return 502 when LLM returns JSON that fails Zod validation", async () => {
    vi.mocked(analyzeImage).mockRejectedValue(
      new (LLMServiceError as any)("LLM response does not match expected schema", "VALIDATION_ERROR")
    );
    const sql = createMockSql();
    const app = createTestApp(sql);

    const formData = new FormData();
    formData.append("image", createValidJpegBlob(), "fridge.jpg");

    const res = await app.request("/", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(502);
    const body = await res.json();
    expect(body.error).toBe("invalid_model_response");
  });

  it("should return 400 when no image field is provided", async () => {
    const sql = createMockSql();
    const app = createTestApp(sql);

    const formData = new FormData();

    const res = await app.request("/", {
      method: "POST",
      body: formData,
    });

    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toBe("bad_request");
  });
});
