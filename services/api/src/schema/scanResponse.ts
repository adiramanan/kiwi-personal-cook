import { z } from "zod";

export const IngredientSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1).max(100),
  category: z.string().min(1).max(50),
  confidence: z.number().min(0).max(1),
});

export const RecipeIngredientSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1).max(100),
  isDetected: z.boolean(),
  substitution: z.string().max(200).nullable(),
});

export const RecipeSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1).max(200),
  summary: z.string().min(1).max(500),
  cookTimeMinutes: z.number().int().positive().max(120),
  difficulty: z.enum(["easy", "medium"]),
  ingredients: z.array(RecipeIngredientSchema).min(1).max(20),
  steps: z.array(z.string().min(1).max(500)).min(1).max(15),
  makeItFasterTip: z.string().max(300).nullable(),
});

export const ScanResponseSchema = z.object({
  ingredients: z.array(IngredientSchema).max(30),
  recipes: z.array(RecipeSchema).min(0).max(4),
});

export type ScanResponseType = z.infer<typeof ScanResponseSchema>;
