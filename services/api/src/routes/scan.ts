import { Hono } from "hono";
import { analyzeImage } from "../services/llm";
import { validateImage } from "../services/imageValidator";
import { incrementQuota } from "../middleware/rateLimit";

export const scanRoutes = new Hono();

scanRoutes.post("/v1/scan", async (c) => {
  const formData = await c.req.formData();
  const file = formData.get("image");
  if (!(file instanceof File)) {
    return c.json({ error: "invalid_image" }, 400);
  }

  const arrayBuffer = await file.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  try {
    validateImage(file.type, buffer);
  } catch {
    return c.json({ error: "invalid_image" }, 400);
  }

  const base64Image = buffer.toString("base64");
  try {
    const result = await analyzeImage(base64Image);
    const userId = c.get("userId") as string;
    await incrementQuota(userId);
    return c.json(result);
  } catch {
    return c.json({ error: "invalid_model_response" }, 502);
  }
});
