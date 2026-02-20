import { describe, it, expect, vi, beforeEach } from "vitest";
import { LLMError } from "../../src/services/llm.js";

const mockCreate = vi.fn();

vi.mock("openai", () => {
  return {
    default: vi.fn().mockImplementation(() => ({
      chat: {
        completions: {
          create: mockCreate,
        },
      },
    })),
  };
});

vi.mock("../../src/utils/logger.js", () => ({
  logger: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

const validResponse = {
  ingredients: [
    { id: "550e8400-e29b-41d4-a716-446655440000", name: "Eggs", category: "Protein", confidence: 0.95 },
    { id: "550e8400-e29b-41d4-a716-446655440001", name: "Milk", category: "Dairy", confidence: 0.88 },
  ],
  recipes: [
    {
      id: "550e8400-e29b-41d4-a716-446655440010",
      name: "Quick Scrambled Eggs",
      summary: "Simple, fast scrambled eggs",
      cookTimeMinutes: 5,
      difficulty: "easy" as const,
      ingredients: [
        { id: "550e8400-e29b-41d4-a716-446655440020", name: "Eggs", isDetected: true, substitution: null },
        { id: "550e8400-e29b-41d4-a716-446655440021", name: "Butter", isDetected: false, substitution: "Use oil instead" },
      ],
      steps: ["Crack eggs into bowl", "Whisk", "Cook in pan"],
      makeItFasterTip: "Use the microwave for 90 seconds",
    },
  ],
};

describe("LLM service", () => {
  beforeEach(() => {
    mockCreate.mockReset();
  });

  it("parses valid structured JSON correctly", async () => {
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: JSON.stringify(validResponse) } }],
    });

    const { analyzeImage } = await import("../../src/services/llm.js");
    const result = await analyzeImage(Buffer.from("test"), "test-key");
    expect(result.ingredients).toHaveLength(2);
    expect(result.recipes).toHaveLength(1);
    expect(result.recipes[0].name).toBe("Quick Scrambled Eggs");
  });

  it("throws LLMError for malformed JSON", async () => {
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: "not valid json {{{" } }],
    });

    const { analyzeImage } = await import("../../src/services/llm.js");
    await expect(analyzeImage(Buffer.from("test"), "test-key")).rejects.toThrow(LLMError);
  });

  it("throws LLMError for off-schema JSON", async () => {
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: JSON.stringify({ ingredients: "not an array" }) } }],
    });

    const { analyzeImage } = await import("../../src/services/llm.js");
    await expect(analyzeImage(Buffer.from("test"), "test-key")).rejects.toThrow(LLMError);
  });

  it("throws LLMError for empty response", async () => {
    mockCreate.mockResolvedValueOnce({
      choices: [{ message: { content: null } }],
    });

    const { analyzeImage } = await import("../../src/services/llm.js");
    await expect(analyzeImage(Buffer.from("test"), "test-key")).rejects.toThrow(LLMError);
  });
});
