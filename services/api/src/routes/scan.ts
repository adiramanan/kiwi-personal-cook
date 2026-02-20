import { Hono } from "hono";
import type { AppEnv } from "../types.js";
import { validateImage } from "../services/imageValidator.js";
import { analyzeImage, LLMError } from "../services/llm.js";
import { incrementScanCount } from "../models/quota.js";
import { logger } from "../utils/logger.js";

const scan = new Hono<AppEnv>();

scan.post("/", async (c) => {
  const userId = c.get("userId");

  const formData = await c.req.formData();
  const file = formData.get("image");

  if (!file || !(file instanceof File)) {
    return c.json({ error: "missing_image" }, 400);
  }

  const arrayBuffer = await file.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);

  const validation = validateImage(buffer, file.type);
  if (!validation.valid) {
    return c.json({ error: "invalid_image", message: validation.error }, 400);
  }

  try {
    const apiKey = process.env.OPENAI_API_KEY!;
    const result = await analyzeImage(buffer, apiKey);

    await incrementScanCount(userId);

    logger.info(
      {
        userId: userId.substring(0, 8),
        ingredientCount: result.ingredients.length,
        recipeCount: result.recipes.length,
      },
      "Scan completed"
    );

    return c.json(result);
  } catch (error) {
    if (error instanceof LLMError) {
      logger.error({ error: error.message }, "LLM processing failed");
      return c.json({ error: "invalid_model_response" }, 502);
    }
    throw error;
  }
});

export default scan;
