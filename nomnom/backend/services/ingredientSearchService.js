import axios from "axios";

const OFF_BASE_URL =
  process.env.OFF_BASE_URL || "https://world.openfoodfacts.org";

export const searchIngredientsByName = async (query) => {
  if (!query || query.trim().length < 2) {
    return [];
  }

  const url = `${OFF_BASE_URL}/cgi/search.pl`;
  const resp = await axios.get(url, {
    params: {
      search_terms: query,
      search_simple: 1,
      json: 1,
      page_size: 10,
    },
  });

  const products = resp.data?.products || [];

  return products
    .map((p) => {
      const name =
        p.product_name ||
        p.generic_name ||
        p.brands ||
        p._id ||
        "Unknown product";
      const brand = p.brands || "";
      const barcode = p.code || p.id;

      if (!barcode) return null;

      return {
        name,
        brand,
        barcode,
      };
    })
    .filter(Boolean);
};
