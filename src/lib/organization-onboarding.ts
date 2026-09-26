export const ORGANIZATION_NAME_MAX_LENGTH = 160;

export function normalizeOrganizationName(value: unknown) {
  const name = String(value ?? "").trim().replace(/\s+/g, " ");
  if (!name) return { error: "Saisissez le nom de votre structure." } as const;
  if (name.length > ORGANIZATION_NAME_MAX_LENGTH) return { error: "Le nom ne peut pas dépasser 160 caractères." } as const;
  return { value: name } as const;
}

export function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

export function organizationSlug(name: string, attemptId: string) {
  const base = name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 140)
    .replace(/-+$/g, "") || "structure";
  const suffix = attemptId.replace(/-/g, "").slice(0, 8).toLowerCase();
  return `${base}-${suffix}`;
}
