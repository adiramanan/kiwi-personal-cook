import { Hono } from "hono";
import type postgres from "postgres";
import { validateImage, ImageValidationError } from "../services/imageValidator.js";
import { analyzeImage, LLMServiceError } from "../services/llm.js";
import { logger, anonymizeUserId } from "../utils/logger.js";
import type { Config } from "../utils/config.js";

export function scanRoutes(sql: postgres.Sql, config: Config) {
  const router = new Hono();

  router.post("/", async (c) => {
    const userId = c.get("userId") as string;
    const startTime = Date.now();

    try {
      // Parse multipart form data
      const formData = await c.req.formData();
      const imageFile = formData.get("image");

      if (!imageFile || !(imageFile instanceof File)) {
        return c.json(
          { error: "bad_request", message: "Missing image field in form data" },
          400
        );
      }

      // Validate image
      const imageBuffer = await imageFile.arrayBuffer();
      const contentType = imageFile.type;

      try {
        validateImage(imageBuffer, contentType);
      } catch (error) {
        if (error instanceof ImageValidationError) {
          return c.json(
            { error: "bad_request", message: error.message },
            400
          );
        }
        throw error;
      }

      // Convert to base64 for the LLM
      const imageBase64 = Buffer.from(imageBuffer).toString("base64");

      // Call LLM service
      let scanResponse;
      try {
        scanResponse = await analyzeImage(imageBase64, config.openaiApiKey);
      } catch (error) {
        if (error instanceof LLMServiceError) {
          logger.error(
            { code: error.code, userId: anonymizeUserId(userId) },
            "LLM service error"
          );
          return c.json(
            { error: "invalid_model_response" },
            502
          );
        }
        throw error;
      }

      // Increment scan quota
      await sql`
        INSERT INTO scan_quota (user_id, scan_date, scan_count)
        VALUES (${userId}, CURRENT_DATE, 1)
        ON CONFLICT (user_id, scan_date)
        DO UPDATE SET scan_count = scan_quota.scan_count + 1
      `;

      const latencyMs = Date.now() - startTime;
      logger.info(
        {
          userId: anonymizeUserId(userId),
          latencyMs,
          ingredientCount: scanResponse.ingredients.length,
          recipeCount: scanResponse.recipes.length,
        },
        "Scan completed successfully"
      );

      return c.json(scanResponse);
    } catch (error) {
      const latencyMs = Date.now() - startTime;
      logger.error(
        { error, userId: anonymizeUserId(userId), latencyMs },
        "Scan route error"
      );
      return c.json({ error: "internal_error" }, 500);
    }
  });

  return router;
}
