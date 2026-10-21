# Goal-aware kitchen — implementation scope

Kiwi's product promise is to help people cook toward their dietary goals with what is already in their fridge. Photo recognition stocks the fridge; recipe generation is a separate action that can happen later.

## Delivered behavior

- Native Cook, Fridge and Family navigation, account settings and shopping checklist.
- Up to three camera/library photos per recognition batch, orientation normalization, metadata removal and compression off the main actor. Editable ingredient review before saving; normalized-name deduplication and account-owned inventory merge.
- Family profiles: name; unrestricted/vegetarian/vegan/pescatarian diet; allergies and custom restrictions; liked/disliked ingredients; cuisines; spice; balanced eating/weight management/muscle gain goal; optional user-chosen kcal and protein targets **per meal**.
- One shared recipe with individual portion multipliers and additions. All family restrictions apply to the base and additions. Targets are never prescribed. Estimated totals and shortfalls are calculated from ingredient estimates, not model-provided totals.
- Up to four cook-now recipes and two requiring one or two extra ingredients. Pantry staples and personal additions count toward missing items. Optional substitutions must already be in the inventory and pass restriction checks.
- Ingredient quantities, servings, steps, speed tips, base nutrition and per-member nutrition/target comparisons. Nutrition comparisons use the original recipe, not optional swaps.
- Recipe results retain the inventory and profile snapshot used for generation; a stale-results prompt appears after either changes.
- Separate, account-scoped on-device shopping checklist; existing grocery data is copied once without deleting the original. Purchased items enter inventory only through the explicit In fridge action.

## API

All new routes are behind the existing bearer-token auth middleware, under `/v1/kitchen`.

| Method | Resource | Input / output |
| --- | --- | --- |
| GET | `/identity` | Authenticated account ID for scoping local checklist state |
| GET | `/family` | `{ members }` |
| POST | `/family` | Profile fields without ID; returns saved profile with server UUID |
| PUT | `/family/:id` | Replacement profile; only owned members may be updated |
| DELETE | `/family/:id` | Removes an owned profile |
| GET | `/inventory` | `{ ingredients: [{ id, name }] }` |
| PATCH | `/inventory` | `{ upserts: [{ id, name }], removedIDs: [] }`; returns merged inventory |
| POST | `/recognize` | Repeated multipart `images` fields, 1–3 JPEGs, max 2 MB each and 7 MB total request; returns ingredient candidates without persisting them |
| POST | `/recipes` | Uses server-owned inventory/profiles; returns `cookNow`, `shopping`, snapshots and generation timestamp |
| GET | `/quota` | Existing scan quota fields plus `generationRemaining` and `generationLimit` |

A multi-photo batch consumes one scan allowance. Recipe generation uses a separate daily counter with the same configured `DAILY_SCAN_LIMIT`. New operations reserve allowance atomically before calling the model and release it on provider failures. The legacy `/v1/scan` and `/v1/quota` interfaces remain compatible.

## Persistence and privacy

`002_kitchen.sql` adds family profiles, normalized fridge items and generation quotas. The actual startup migration runner applies the same DDL. All records reference users with `ON DELETE CASCADE`. Inventory edits serialize per account. Profiles and fridge data sync through PostgreSQL; shopping remains local to the account/device. Sign-out clears kitchen state; account deletion also clears the local checklist.

Photos are not saved by Kiwi. Profile text, raw model replies and images are not logged by the new flow; legacy model response logging is redacted too. Output schema validation and conservative ingredient-name checks supplement the model's restriction instructions. These checks are not an exhaustive allergen database or medical certification. The UI asks users to check labels and suitability. Nutrition is model-estimated, not obtained from a verified nutrition database.

## Defaults and future work

Inventory records presence, not stock quantities or expiry. Cooking does not automatically deduct items. No daily food logging, daily budget prescription, clinical diet treatment, full-day meal planning, retailer ordering, Swiggy integration or automatic stock deduction. No hosting or App Store deployment is included.

## Verification

Backend: `npm test` and `npm run typecheck` from `services/api`. Backup `* (1).test.ts` files are excluded from the canonical suite; the files remain untouched.

iOS: build and test the Kiwi scheme with Xcode 26.6 on the installed iOS 26.5 iPhone 17 simulator. Backup Swift files are explicitly excluded from target membership without deleting them. New unit coverage exercises persistence, inventory corrections, profile snapshots, checklist isolation and legacy migration. UI tests launch with `--kitchen-ui-tests`, a **DEBUG-only**, network-free fixture mode. Optional `--generation-fails` and `--generation-limited` cover error states; no fixtures or authentication bypass are compiled into Release.

UI tests save screenshot attachments for representative screens and large-text/dark appearance. There is no snapshot comparison library or approved baseline in the project, so screenshot review is used instead of claiming automated visual-diff coverage. Live provider quality and PostgreSQL migration/cascade behavior require a configured local API/database and are separate from mocked route tests.

Design references: [Crouton recipes](https://mobbin.com/screens/38a3c6aa-f92a-4011-b35a-8301f311e8fc), [Julienne dietary preferences](https://mobbin.com/screens/f1da5252-f651-46dd-b7b4-4cbc9b6b44b8). References guide information hierarchy; screenshots and branding are not shipped as product assets.

### Verified in this change (2026-10-21)

- Backend: type check and all 45 tests passed.
- iOS: simulator build, 29 unit tests and 14 UI/launch checks passed on iPhone 17 / iOS 26.5. The photo-review and explicit dark/large-text tests also passed in a targeted rerun after final fixes.
- Reviewed exported screenshots for family profiles, saved inventory, recipes, portions/nutrition, editable ingredient review and dark accessibility text sizes.
- Live model calls and PostgreSQL migrations/cascades were not exercised; provider calls were mocked and UI tests used DEBUG fixtures. No deployment performed.
