import { describe, it, expect, vi, beforeEach } from "vitest";
import { v4 as uuidv4 } from "uuid";

const mockCreate = vi.fn();

// Mock OpenAI — the default export is the class constructor
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

import { analyzeImage, LLMServiceError } from "../../src/services/llm.js";

function createValidResponse() {
  return {
    ingredients: [
      {
        id: uuidv4(),
        name: "Eggs",
        category: "Protein",
        confidence: 0.95,
      },
      {
        id: uuidv4(),
        name: "Milk",
        category: "Dairy",
        confidence: 0.88,
      },
    ],
    recipes: [
      {
        id: uuidv4(),
        name: "Quick Omelette",
        summary: "A fast protein-rich meal.",
        cookTimeMinutes: 10,
        difficulty: "easy",
        ingredients: [
          {
            id: uuidv4(),
            name: "Eggs",
            isDetected: true,
            substitution: null,
          },
        ],
        steps: ["Crack eggs", "Cook in pan"],
        makeItFasterTip: "Use non-stick pan",
      },
    ],
  };
}

describe("LLM Service", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should parse valid structured JSON response correctly", async () => {
    const validResponse = createValidResponse();
    mockCreate.mockResolvedValue({
      choices: [
        {
          message: {
            content: JSON.stringify(validResponse),
          },
        },
      ],
    });

    const result = await analyzeImage("base64data", "sk-test");

    expect(result.ingredients).toHaveLength(2);
    expect(result.ingredients[0].name).toBe("Eggs");
    expect(result.recipes).toHaveLength(1);
    expect(result.recipes[0].name).toBe("Quick Omelette");
  });

  it("should throw PARSE_ERROR for malformed JSON", async () => {
    mockCreate.mockResolvedValue({
      choices: [
        {
          message: {
            content: "This is not valid JSON at all {{{",
          },
        },
      ],
    });

    try {
      await analyzeImage("base64data", "sk-test");
      expect.fail("Should have thrown");
    } catch (error) {
      expect(error).toBeInstanceOf(LLMServiceError);
      expect((error as LLMServiceError).code).toBe("PARSE_ERROR");
    }
  });

  it("should throw VALIDATION_ERROR for off-schema JSON", async () => {
    mockCreate.mockResolvedValue({
      choices: [
        {
          message: {
            content: JSON.stringify({
              ingredients: [
                {
                  id: "not-a-uuid",
                  name: "Eggs",
                  category: "Protein",
                  confidence: 2.0, // Out of range
                },
              ],
              recipes: [],
            }),
          },
        },
      ],
    });

    try {
      await analyzeImage("base64data", "sk-test");
      expect.fail("Should have thrown");
    } catch (error) {
      expect(error).toBeInstanceOf(LLMServiceError);
      expect((error as LLMServiceError).code).toBe("VALIDATION_ERROR");
    }
  });

  it("should throw PARSE_ERROR for empty response content", async () => {
    mockCreate.mockResolvedValue({
      choices: [
        {
          message: {
            content: null,
          },
        },
      ],
    });

    try {
      await analyzeImage("base64data", "sk-test");
      expect.fail("Should have thrown");
    } catch (error) {
      expect(error).toBeInstanceOf(LLMServiceError);
      expect((error as LLMServiceError).code).toBe("PARSE_ERROR");
    }
  });

  it("should throw API_ERROR when OpenAI call fails", async () => {
    mockCreate.mockRejectedValue(new Error("API rate limit exceeded"));

    try {
      await analyzeImage("base64data", "sk-test");
      expect.fail("Should have thrown");
    } catch (error) {
      expect(error).toBeInstanceOf(LLMServiceError);
      expect((error as LLMServiceError).code).toBe("API_ERROR");
    }
  });
});
