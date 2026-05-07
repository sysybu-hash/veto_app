export type SpecializationId =
  | "criminal"
  | "traffic"
  | "civil"
  | "family"
  | "labor"
  | "general";

export const SPECIALIZATION_IDS: readonly SpecializationId[] = [
  "criminal",
  "traffic",
  "civil",
  "family",
  "labor",
  "general",
] as const;

export const UI_TO_BACKEND_SPECIALIZATION: Record<SpecializationId, string> = {
  criminal: "פלילי",
  traffic: "תעבורה",
  civil: "מסחרי",
  family: "משפחה",
  labor: "עבודה",
  general: "",
};
