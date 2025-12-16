import {setGlobalOptions} from "firebase-functions";
import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";

admin.initializeApp();

setGlobalOptions({maxInstances: 10});

// =============================================================================
// TypeScript Interfaces - Matching Swift OFFAProduct data model
// =============================================================================

interface ProductNutriments {
  addedSugars: number | null;
  addedSugarsUnit: string | null;
  energyKcal: number | null;
  energyKcalUnit: string | null;
  fat: number | null;
  fatUnit: string | null;
  saturatedFat: number | null;
  saturatedFatUnit: string | null;
  carbohydrates: number | null;
  carbohydratesUnit: string | null;
  sugars: number | null;
  sugarsUnit: string | null;
  fiber: number | null;
  proteins: number | null;
  proteinsUnit: string | null;
  salt: number | null;
  saltUnit: string | null;
  sodium: number | null;
  sodiumUnit: string | null;
}

interface ProductIngredient {
  id: string;
  text: string;
  percentEstimate: number | null;
  vegan: string | null;
  vegetarian: string | null;
}

interface NutrientComponent {
  nutrientId: string;
  value: number | null;
  points: number | null;
  pointsMax: number | null;
  unit: string | null;
}

interface NutriscoreData {
  negativeComponents: NutrientComponent[] | null;
  positiveComponents: NutrientComponent[] | null;
}

interface Product {
  id: string;
  code: string;
  productName: string | null;
  brands: string | null;
  quantity: string | null;
  imageURL: string | null;
  imageFrontURL: string | null;
  imageIngredientsURL: string | null;
  imageNutritionURL: string | null;
  allergens: string | null;
  allergensTags: string[] | null;
  labelsTags: string[] | null;
  ecoScoreGrade: string | null;
  ecoScoreScore: number | null;
  ingredientsText: string | null;
  ingredients: ProductIngredient[] | null;
  novaGroup: number | null;
  nutriments: ProductNutriments | null;
  nutriscoreGrade: string | null;
  nutriscoreScore: number | null;
  nutriscoreData: NutriscoreData | null;
  servingSize: string | null;
  cachedAt: admin.firestore.Timestamp;
}

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Check if product exists in Firestore cache
 * @param {string} barcode - The product barcode to lookup
 * @return {Promise<Product | null>} The cached product or null if not found
 */
async function checkCache(barcode: string): Promise<Product | null> {
  const db = admin.firestore();
  const docRef = db.collection("products").doc(barcode);
  const doc = await docRef.get();

  if (doc.exists) {
    return doc.data() as Product;
  }
  return null;
}

/**
 * Fetch product from Open Food Facts API v2
 * @param {string} barcode - The product barcode to fetch
 * @return {Promise<unknown | null>} The product data or null if not found
 */
async function fetchFromOFF(barcode: string): Promise<unknown | null> {
  const fields = [
    "_id",
    "code",
    "product_name",
    "brands",
    "quantity",
    "image_url",
    "image_front_url",
    "image_ingredients_url",
    "image_nutrition_url",
    "allergens",
    "allergens_tags",
    "labels_tags",
    "ecoscore_grade",
    "ecoscore_score",
    "ingredients_text",
    "ingredients",
    "nova_group",
    "nutriments",
    "nutriscore_grade",
    "nutriscore_score",
    "nutriscore_data",
    "serving_size",
  ].join(",");

  const url =
    `https://world.openfoodfacts.net/api/v2/product/${barcode}?fields=${fields}`;

  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": "ShelfSmart iOS App - Firebase Cloud Functions",
      },
    });

    if (!response.ok) {
      console.error(`OFF API error: ${response.status}`);
      return null;
    }

    const data = await response.json();

    // Check if product was found (status: 1 means found)
    if (data.status !== 1 || !data.product) {
      return null;
    }

    return data.product;
  } catch (error) {
    console.error("Error fetching from OFF:", error);
    return null;
  }
}

/**
 * Transform nutriments from OFF API format to our flattened format
 * @param {Record<string, unknown> | undefined} nutriments - Raw nutriments data
 * @return {ProductNutriments | null} Transformed nutriments or null
 */
function transformNutriments(
  nutriments: Record<string, unknown> | undefined
): ProductNutriments | null {
  if (!nutriments) return null;

  return {
    addedSugars: nutriments["added_sugars_100g"] as number ?? null,
    addedSugarsUnit: nutriments["added_sugars_unit"] as string ?? null,
    energyKcal: nutriments["energy-kcal_100g"] as number ?? null,
    energyKcalUnit: nutriments["energy-kcal_unit"] as string ?? null,
    fat: nutriments["fat_100g"] as number ?? null,
    fatUnit: nutriments["fat_unit"] as string ?? null,
    saturatedFat: nutriments["saturated-fat_100g"] as number ?? null,
    saturatedFatUnit: nutriments["saturated-fat_unit"] as string ?? null,
    carbohydrates: nutriments["carbohydrates_100g"] as number ?? null,
    carbohydratesUnit: nutriments["carbohydrates_unit"] as string ?? null,
    sugars: nutriments["sugars_100g"] as number ?? null,
    sugarsUnit: nutriments["sugars_unit"] as string ?? null,
    fiber: nutriments["fiber_100g"] as number ?? null,
    proteins: nutriments["proteins_100g"] as number ?? null,
    proteinsUnit: nutriments["proteins_unit"] as string ?? null,
    salt: nutriments["salt_100g"] as number ?? null,
    saltUnit: nutriments["salt_unit"] as string ?? null,
    sodium: nutriments["sodium_100g"] as number ?? null,
    sodiumUnit: nutriments["sodium_unit"] as string ?? null,
  };
}

/**
 * Transform ingredients array from OFF API format
 * @param {Array<Record<string, unknown>> | undefined} ingredients - Raw
 * @return {ProductIngredient[] | null} Transformed ingredients or null
 */
function transformIngredients(
  ingredients: Array<Record<string, unknown>> | undefined
): ProductIngredient[] | null {
  if (!ingredients || !Array.isArray(ingredients)) return null;

  return ingredients.map((ing) => ({
    id: ing.id as string ?? "",
    text: ing.text as string ?? "",
    percentEstimate: ing.percent_estimate as number ?? null,
    vegan: ing.vegan as string ?? null,
    vegetarian: ing.vegetarian as string ?? null,
  }));
}

/**
 * Transform nutriscore component array
 * @param {Array<Record<string, unknown>> | undefined} components - Raw
 * @return {NutrientComponent[] | null} Transformed components or null
 */
function transformNutriscoreComponents(
  components: Array<Record<string, unknown>> | undefined
): NutrientComponent[] | null {
  if (!components || !Array.isArray(components)) return null;

  return components.map((comp) => ({
    nutrientId: comp.id as string ?? "",
    value: comp.value as number ?? null,
    points: comp.points as number ?? null,
    pointsMax: comp.points_max as number ?? null,
    unit: comp.unit as string ?? null,
  }));
}

/**
 * Transform nutriscore data from OFF API format
 * @param {Record<string, unknown> | undefined} nutriscoreData - Raw data
 * @return {NutriscoreData | null} Transformed nutriscore data or null
 */
function transformNutriscoreData(
  nutriscoreData: Record<string, unknown> | undefined
): NutriscoreData | null {
  if (!nutriscoreData) return null;

  const components = nutriscoreData.components as
    Record<string, unknown> | undefined;

  if (!components) return null;

  return {
    negativeComponents: transformNutriscoreComponents(
      components.negative as Array<Record<string, unknown>> | undefined
    ),
    positiveComponents: transformNutriscoreComponents(
      components.positive as Array<Record<string, unknown>> | undefined
    ),
  };
}

/**
 * Transform OFF API product response to our Product interface
 * @param {Record<string, unknown>} offProduct - Raw product data from OFF API
 * @return {Product} Transformed product object
 */
function transformProduct(offProduct: Record<string, unknown>): Product {
  return {
    id: offProduct._id as string ?? offProduct.code as string ?? "",
    code: offProduct.code as string ?? "",
    productName: offProduct.product_name as string ?? null,
    brands: offProduct.brands as string ?? null,
    quantity: offProduct.quantity as string ?? null,
    imageURL: offProduct.image_url as string ?? null,
    imageFrontURL: offProduct.image_front_url as string ?? null,
    imageIngredientsURL: offProduct.image_ingredients_url as string ?? null,
    imageNutritionURL: offProduct.image_nutrition_url as string ?? null,
    allergens: offProduct.allergens as string ?? null,
    allergensTags: offProduct.allergens_tags as string[] ?? null,
    labelsTags: offProduct.labels_tags as string[] ?? null,
    ecoScoreGrade: offProduct.ecoscore_grade as string ?? null,
    ecoScoreScore: offProduct.ecoscore_score as number ?? null,
    ingredientsText: offProduct.ingredients_text as string ?? null,
    ingredients: transformIngredients(
      offProduct.ingredients as Array<Record<string, unknown>> | undefined
    ),
    novaGroup: offProduct.nova_group as number ?? null,
    nutriments: transformNutriments(
      offProduct.nutriments as Record<string, unknown> | undefined
    ),
    nutriscoreGrade: offProduct.nutriscore_grade as string ?? null,
    nutriscoreScore: offProduct.nutriscore_score as number ?? null,
    nutriscoreData: transformNutriscoreData(
      offProduct.nutriscore_data as Record<string, unknown> | undefined
    ),
    servingSize: offProduct.serving_size as string ?? null,
    cachedAt: admin.firestore.Timestamp.now(),
  };
}

/**
 * Store product in Firestore
 * @param {string} barcode - The product barcode (used as document ID)
 * @param {Product} product - The product data to store
 * @return {Promise<void>} Resolves when the product is stored
 */
async function storeProduct(barcode: string, product: Product): Promise<void> {
  const db = admin.firestore();
  await db.collection("products").doc(barcode).set(product);
}

// =============================================================================
// Cloud Functions
// =============================================================================

/**
 * Fetch product by barcode
 * - Checks Firestore cache first
 * - Falls back to Open Food Facts API
 * - Caches the result for future requests
 */
export const fetchProduct = onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to fetch products"
    );
  }

  // Validate barcode input
  const barcode = request.data?.barcode;
  if (!barcode || typeof barcode !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "A valid barcode string is required"
    );
  }

  // Clean the barcode (remove any whitespace)
  const cleanBarcode = barcode.trim();
  if (cleanBarcode.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Barcode cannot be empty"
    );
  }

  try {
    // Check Firestore cache first
    const cachedProduct = await checkCache(cleanBarcode);
    if (cachedProduct) {
      console.log(`Cache hit for barcode: ${cleanBarcode}`);
      return {
        product: cachedProduct,
        source: "cache",
        status: "found",
      };
    }

    // Fetch from Open Food Facts API
    console.log(`Cache miss, fetching from OFF API: ${cleanBarcode}`);
    const offProduct = await fetchFromOFF(cleanBarcode);

    if (!offProduct) {
      return {
        product: null,
        source: "api",
        status: "not_found",
      };
    }

    // Transform and store in Firestore
    const product = transformProduct(offProduct as Record<string, unknown>);
    await storeProduct(cleanBarcode, product);

    console.log(`Product cached successfully: ${cleanBarcode}`);
    return {
      product,
      source: "api",
      status: "found",
    };
  } catch (error) {
    console.error("Error in fetchProduct:", error);
    throw new HttpsError(
      "internal",
      "An error occurred while fetching the product"
    );
  }
});

/**
 * Legacy addProduct function - kept for backwards compatibility
 */
export const addProduct = onCall(async (request) => {
  // Add data to firestore
  await admin.firestore().collection("products")
    .doc(request.data.barcode)
    .set({barcode: request.data.barcode});

  // Return data directly
  return {message: "Product Added!"};
});
