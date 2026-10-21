import { z } from "zod";

const label = z.string().trim().min(1).max(100);
const tags = z.array(label).max(30).default([]);
export const MemberInput = z.object({
  name: label,
  diet: z.enum(["unrestricted", "vegetarian", "vegan", "pescatarian"]).default("unrestricted"),
  allergies: tags, restrictions: tags, likes: tags, dislikes: tags, cuisines: tags,
  spice: z.enum(["mild", "medium", "hot"]).default("mild"),
  goal: z.enum(["balanced", "weightManagement", "muscleGain"]).default("balanced"),
  calorieTarget: z.number().int().min(100).max(3000).nullable().default(null),
  proteinTarget: z.number().min(1).max(250).nullable().default(null),
}).strict();
export const MemberSchema = MemberInput.extend({ id: z.string().uuid() });
export type Member = z.infer<typeof MemberSchema>;
export const InventoryItemSchema = z.object({ id: z.string().uuid(), name: label });
export type InventoryItem = z.infer<typeof InventoryItemSchema>;
export const InventoryUpdate = z.object({
  upserts: z.array(InventoryItemSchema).max(100).default([]),
  removedIDs: z.array(z.string().uuid()).max(100).default([]),
}).strict();

export const NutritionSchema = z.object({
  calories: z.number().min(0).max(30000),
  protein: z.number().min(0).max(3000),
  carbs: z.number().min(0).max(5000),
  fat: z.number().min(0).max(3000),
});
export type Nutrition = z.infer<typeof NutritionSchema>;
export const CookingIngredientSchema = z.object({
  name: label,
  quantity: z.string().trim().min(1).max(100),
  // Nutrition for the ENTIRE quantity written above, not per 100g.
  nutrition: NutritionSchema,
});
export const CookingRecipeSchema = z.object({
  name: z.string().min(1).max(200), summary: z.string().min(1).max(500),
  cookTimeMinutes: z.number().int().min(1).max(120),
  difficulty: z.enum(["easy", "medium"]),
  servings: z.number().int().min(1).max(20),
  ingredients: z.array(CookingIngredientSchema).min(1).max(25),
  steps: z.array(z.string().min(1).max(700)).min(1).max(15),
  makeItFasterTip: z.string().max(300).nullable(),
  goalExplanation: z.string().min(1).max(500),
  substitutions: z.array(z.object({ replaces: label, alternative: CookingIngredientSchema })).max(3).default([]),
  portions: z.array(z.object({
    memberId: z.string().uuid(), multiplier: z.number().min(0.25).max(3),
    additions: z.array(CookingIngredientSchema).max(3),
  })).max(20),
});
export const CookingOutputSchema = z.object({ recipes: z.array(CookingRecipeSchema).max(6) });
export type CookingRecipe = z.infer<typeof CookingRecipeSchema>;
export const normalizeName = (name: string) => name.normalize("NFKC").trim().toLocaleLowerCase("en-US").replace(/\s+/g, " ");
