"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import { initialProcessMessageState, type ProcessMessageState } from "./state";

function readString(value: FormDataEntryValue | null) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeContents(values: FormDataEntryValue[]) {
  return values
    .filter((value): value is string => typeof value === "string")
    .map((value) => value.trim().replace(/\r\n/g, "\n"));
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

export async function processMessage(
  _previousState: ProcessMessageState = initialProcessMessageState,
  formData: FormData
): Promise<ProcessMessageState> {
  const messageId = readString(formData.get("message_id"));
  const resolution = readString(formData.get("resolution"));
  const informationContents = normalizeContents(formData.getAll("information_contents"));
  const taskContents = normalizeContents(formData.getAll("task_contents"));

  if (!isUuid(messageId)) {
    return { status: "error", message: "Ce message n’est pas valide." };
  }

  if (resolution !== "NO_FOLLOW_UP" && resolution !== "CONSEQUENCES_CREATED") {
    return { status: "error", message: "Choisissez ce qu’il faut faire du message." };
  }

  if (informationContents.some((content) => !content) || taskContents.some((content) => !content)) {
    return { status: "error", message: "Remplissez chaque information et chaque tâche ajoutée." };
  }

  if (
    resolution === "NO_FOLLOW_UP"
    && (informationContents.length > 0 || taskContents.length > 0)
  ) {
    return { status: "error", message: "Sans suite ne peut pas contenir de conséquence." };
  }

  if (
    resolution === "CONSEQUENCES_CREATED"
    && informationContents.length + taskContents.length === 0
  ) {
    return { status: "error", message: "Ajoutez une information, une tâche, ou choisissez Sans suite." };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("boralog_process_message", {
    p_message_id: messageId,
    p_resolution: resolution,
    p_information_contents: informationContents,
    p_task_contents: taskContents,
  });

  if (error) {
    return {
      status: "error",
      message: "Le traitement n’a pas pu être terminé. Vérifiez vos choix puis réessayez.",
    };
  }

  revalidatePath("/messages");
  redirect("/messages");
}
