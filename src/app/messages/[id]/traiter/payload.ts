export type ProcessMessagePayload =
  | {
      ok: true;
      messageId: string;
      resolution: "NO_FOLLOW_UP" | "CONSEQUENCES_CREATED";
      informationContents: string[];
      taskContents: string[];
      expectedInformationCount: number;
      expectedTaskCount: number;
    }
  | { ok: false; message: string };

function readString(value: FormDataEntryValue | null) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeContents(values: FormDataEntryValue[]) {
  return values
    .filter((value): value is string => typeof value === "string")
    .map((value) => value.trim().replace(/\r\n/g, "\n"));
}

function readExpectedCount(value: FormDataEntryValue | null) {
  const raw = readString(value);
  if (!/^\d+$/.test(raw)) return null;
  const parsed = Number(raw);
  return Number.isSafeInteger(parsed) ? parsed : null;
}

export function parseProcessMessagePayload(formData: FormData): ProcessMessagePayload {
  const messageId = readString(formData.get("message_id"));
  const resolution = readString(formData.get("resolution"));
  const informationContents = normalizeContents(formData.getAll("information_contents"));
  const taskContents = normalizeContents(formData.getAll("task_contents"));
  const expectedInformationCount = readExpectedCount(formData.get("expected_information_count"));
  const expectedTaskCount = readExpectedCount(formData.get("expected_task_count"));

  if (resolution !== "NO_FOLLOW_UP" && resolution !== "CONSEQUENCES_CREATED") {
    return { ok: false, message: "Choisissez ce qu’il faut faire du message." };
  }

  if (expectedInformationCount === null || expectedTaskCount === null) {
    return { ok: false, message: "Le formulaire de traitement est incomplet. Réessayez." };
  }

  if (
    informationContents.length !== expectedInformationCount
    || taskContents.length !== expectedTaskCount
  ) {
    return {
      ok: false,
      message: "Une conséquence affichée n’a pas été transmise. Réessayez sans quitter cette page.",
    };
  }

  return {
    ok: true,
    messageId,
    resolution,
    informationContents,
    taskContents,
    expectedInformationCount,
    expectedTaskCount,
  };
}
