import { describe, expect, it, vi } from "vitest";
import { createAnalyzeImage } from "../../src/services/llm";

const validResponse = {
  ingredients: [
    {
      id: "11111111-1111-4111-8111-111111111111",
      name: "Eggs",
      category: "Protein",
      confidence: 0.9,
    },
  ],
  recipes: [
    {
      id: "22222222-2222-4222-8222-222222222222",
      name: "Fast Eggs",
      summary: "Quick egg dish",
      cookTimeMinutes: 8,
      difficulty: "easy",
      ingredients: [
        {
          id: "33333333-3333-4333-8333-333333333333",
          name: "Eggs",
          isDetected: true,
          substitution: null,
        },
      ],
      steps: ["Cook."],
      makeItFasterTip: "Prep pan first.",
    },
  ],
};

describe("llm service", () => {
  it("parses valid structured JSON", async () => {
    const createMock = vi.fn().mockResolvedValue({
      output_text: JSON.stringify(validResponse),
    });

    const analyzeImage = createAnalyzeImage({
      responses: {
        create: createMock,
      },
    });

    const result = await analyzeImage("base64-image");

    expect(result.recipes[0].name).toBe("Fast Eggs");
    expect(createMock).toHaveBeenCalledTimes(1);
  });

  it("throws on malformed JSON", async () => {
    const analyzeImage = createAnalyzeImage({
      responses: {
        create: vi.fn().mockResolvedValue({
          output_text: "{not-json",
        }),
      },
    });

    await expect(analyzeImage("base64-image")).rejects.toMatchObject({
      message: "invalid_json",
    });
  });

  it("throws on off-schema JSON", async () => {
    const analyzeImage = createAnalyzeImage({
      responses: {
        create: vi.fn().mockResolvedValue({
          output_text: JSON.stringify({ ingredients: [], recipes: [{ name: 1 }] }),
        }),
      },
    });

    await expect(analyzeImage("base64-image")).rejects.toMatchObject({
      message: "schema_validation_failed",
    });
  });
});
