export function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export const usesMiles = (() => {
  try {
    const locale = navigator.language || "en-US";
    const region = new Intl.Locale(locale).region ?? locale.split("-")[1] ?? "";
    return ["US", "GB", "MM", "LR"].includes(region.toUpperCase());
  } catch {
    return true;
  }
})();

export function formatDistance(km: number): string {
  if (usesMiles) {
    const mi = km * 0.621371;
    return mi < 10 ? `${mi.toFixed(1)} mi` : `${Math.round(mi)} mi`;
  }
  return km < 10 ? `${km.toFixed(1)} km` : `${Math.round(km)} km`;
}
