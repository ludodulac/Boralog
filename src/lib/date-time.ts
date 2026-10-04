export const BORALOG_TIME_ZONE = "Europe/Paris";

export function formatBoralogDateTime(
  value: string | Date,
  dateStyle: "short" | "medium" = "medium"
) {
  const date = value instanceof Date ? value : new Date(value);

  return new Intl.DateTimeFormat("fr-FR", {
    dateStyle,
    timeStyle: "short",
    timeZone: BORALOG_TIME_ZONE,
  }).format(date);
}
