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


export function getBoralogCivilDate(value: Date = new Date()) {
  const parts = new Intl.DateTimeFormat("fr-CA", {
    timeZone: BORALOG_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(value);
  const year = parts.find((part) => part.type === "year")?.value;
  const month = parts.find((part) => part.type === "month")?.value;
  const day = parts.find((part) => part.type === "day")?.value;
  if (!year || !month || !day) throw new Error("Unable to resolve Boralog civil date");
  return `${year}-${month}-${day}`;
}
