import { beforeEach, describe, expect, it, vi } from "vitest";
import { generateRecipes, recognizeIngredients } from "../../src/services/cooking.js";
import { LLMError } from "../../src/services/llm.js";

const { mockCreate } = vi.hoisted(() => ({ mockCreate: vi.fn() }));
vi.mock("openai", () => ({
  default: vi.fn().mockImplementation(() => ({
    chat: { completions: { create: mockCreate } },
  })),
}));
vi.mock("../../src/utils/config.js", () => ({ config: { openaiApiKey: "test-key", logLevel: "silent" } }));

describe("kitchen model integration", () => {
  beforeEach(() => mockCreate.mockReset());

  it("sends multiple photos to Luna and merges duplicate ingredient candidates", async () => {
    mockCreate.mockResolvedValueOnce({ choices: [{ message: { content: JSON.stringify({
      ingredients: [{ name: "tomato" }, { name: "Tomato" }, { name: "egg" }],
    }) } }] });
    const photos = [Buffer.from("first-photo"), Buffer.from("second-photo")];
    const ingredients = await recognizeIngredients(photos);
    expect(ingredients.map(item => item.name)).toEqual(["Tomato", "egg"]);
    const request = mockCreate.mock.calls[0][0];
    expect(request).toMatchObject({
      model: "gpt-6-luna", reasoning_effort: "low", max_completion_tokens: 10000,
      response_format: { type: "json_object" },
    });
    expect(request).not.toHaveProperty("temperature");
    expect(request).not.toHaveProperty("max_tokens");
    expect(request.messages[1].content).toEqual(photos.map(photo => ({
      type: "image_url", image_url: { url: `data:image/jpeg;base64,${photo.toString("base64")}` },
    })));
  });

  it("sends confirmed inventory as text and preserves snapshots when no suitable recipe exists", async () => {
    mockCreate.mockResolvedValueOnce({ choices: [{ message: { content: '{"recipes":[]}' } }] });
    const inventory = [{ id: crypto.randomUUID(), name: "egg" }];
    const result = await generateRecipes(inventory, []);
    expect(result).toMatchObject({ cookNow: [], shopping: [], inventorySnapshot: inventory, profileSnapshot: [] });
    const request = mockCreate.mock.calls[0][0];
    expect(request.model).toBe("gpt-6-luna");
    expect(request.messages[1].content).toEqual([
      { type: "text", text: JSON.stringify({ inventory, members: [] }) },
    ]);
  });

  it("rejects malformed and off-schema provider responses", async () => {
    mockCreate.mockResolvedValueOnce({ choices: [{ message: { content: "invalid JSON" } }] });
    await expect(recognizeIngredients([Buffer.from("photo")])).rejects.toThrow(LLMError);
    mockCreate.mockResolvedValueOnce({ choices: [{ message: { content: '{"recipes":[{"name":"Incomplete"}]}' } }] });
    await expect(generateRecipes([], [])).rejects.toThrow(LLMError);
  });
});
