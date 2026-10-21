import { describe, expect, it } from "vitest";
import { conflictsWithFamily, prepareRecipes, sumNutrition } from "../../src/services/cooking.js";
import { MemberSchema, MemberInput, type CookingRecipe, type Member } from "../../src/schema/kitchen.js";
const id = "550e8400-e29b-41d4-a716-446655440000";
const member = (changes: Partial<Member> = {}): Member => MemberSchema.parse({ id, name: "Ada", ...changes });
const nutrient = { calories: 200, protein: 12, carbs: 20, fat: 8 };
const item = (name: string) => ({ name, quantity: "100 g", nutrition: nutrient });
function recipe(): CookingRecipe {
  return { name: "Spinach bowl", summary: "A quick bowl", cookTimeMinutes: 15, difficulty: "easy", servings: 2,
    ingredients: [item("spinach")], steps: ["Cook the spinach."], makeItFasterTip: null, goalExplanation: "A balanced meal.",
    substitutions: [], portions: [{ memberId: id, multiplier: 1.5, additions: [item("tofu")] }] };
}
describe("family-aware cooking", () => {
  it("accepts optional targets without prescribing any", () => {
    const profile = MemberInput.parse({ name: "Ada" });
    expect(profile.calorieTarget).toBeNull(); expect(profile.proteinTarget).toBeNull();
    expect(MemberInput.safeParse({ name: "Ada", calorieTarget: -1 }).success).toBe(false);
    expect(MemberInput.safeParse({ name: "Ada", proteinTarget: 500 }).success).toBe(false);
  });
  it("combines restrictions across the whole family, including additions and steps", () => {
    const meal = recipe();
    expect(conflictsWithFamily(meal, [member({ allergies: ["soy"] })])).toBe(true);
    meal.portions[0].additions = [];
    meal.steps = ["Finish with a spoon of peanut butter."];
    expect(conflictsWithFamily(meal, [member(), member({ id: crypto.randomUUID(), allergies: ["peanuts"] })])).toBe(true);
  });
  it("rejects meat for vegetarian and dairy for vegan profiles", () => {
    const meal = recipe(); meal.ingredients = [item("chicken")];
    expect(conflictsWithFamily(meal, [member({ diet: "vegetarian" })])).toBe(true);
    meal.ingredients = [item("paneer")];
    expect(conflictsWithFamily(meal, [member({ diet: "vegan" })])).toBe(true);
  });
  it("calculates base servings, scaled portions and additions consistently", () => {
    const result = prepareRecipes([recipe()], [{ id, name: "spinach" }, { id: crypto.randomUUID(), name: "tofu" }],
      [member({ calorieTarget: 500, proteinTarget: 50 })]);
    const meal = result.cookNow[0] as any;
    expect(meal.nutrition.calories).toBe(100);
    expect(meal.portions[0].nutrition.calories).toBe(350);
    expect(meal.portions[0].nutrition.protein).toBe(21);
    expect(meal.portions[0].calorieDifference).toBe(-150);
    expect(meal.portions[0].proteinShortfall).toBe(29);
    expect(meal.portions[0].targetSummary).toContain("350 of 500");
  });
  it("counts additions and pantry staples as missing, combining duplicates", () => {
    const meal = recipe(); meal.ingredients.push(item("oil"), item(" Oil "));
    const result = prepareRecipes([meal], [{ id, name: "spinach" }], [member()]);
    expect(result.cookNow).toHaveLength(0);
    expect((result.shopping[0] as any).missingIngredients).toEqual(["oil", "tofu"]);
    meal.ingredients.push(item("salt"));
    expect(prepareRecipes([meal], [{ id, name: "spinach" }], [member()]).shopping).toHaveLength(0);
  });
  it("does not trust model availability flags or incomplete family portions", () => {
    const meal = recipe();
    expect(prepareRecipes([meal], [{ id, name: "spinach" }], [member()]).shopping).toHaveLength(1);
    meal.portions = [];
    expect(prepareRecipes([meal], [{ id, name: "spinach" }], [member()]).cookNow).toHaveLength(0);
  });
  it("returns no recipes when all conflict, rather than weakening restrictions", () => {
    expect(prepareRecipes([recipe()], [{ id, name: "spinach" }], [member({ allergies: ["soy"] })])).toEqual({ cookNow: [], shopping: [] });
  });
  it("checks custom restrictions and only offers available safe swaps", () => {
    const meal = recipe(); meal.ingredients = [item("pork")];
    expect(conflictsWithFamily(meal, [member({ restrictions: ["no pork"] })])).toBe(true);
    meal.ingredients = [item("spinach")]; meal.portions[0].additions = [];
    meal.substitutions = [
      { replaces: "spinach", alternative: item("tofu") },
      { replaces: "spinach", alternative: item("peanut") },
      { replaces: "spinach", alternative: item("kale") },
    ];
    const available = ["spinach", "tofu", "peanut"].map(name => ({ id: crypto.randomUUID(), name }));
    const result = prepareRecipes([meal], available, [member({ allergies: ["peanuts"] })]);
    expect((result.cookNow[0] as any).substitutions).toHaveLength(1);
    expect((result.cookNow[0] as any).substitutions[0].alternative.name).toBe("tofu");
  });
  it("rejects recipes that do not make enough base portions for the family", () => {
    const meal = recipe(); meal.servings = 1;
    expect(prepareRecipes([meal], [{ id, name: "spinach" }], [member()]).shopping).toHaveLength(0);
  });
  it("sums ingredient estimates without relying on model totals", () => {
    expect(sumNutrition([nutrient, nutrient], 0.5)).toEqual(nutrient);
  });
});
