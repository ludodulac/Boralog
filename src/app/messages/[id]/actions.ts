"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../../lib/supabase/server";
import {
  initialAddMessageNoteState,
  initialMessageStatusState,
  type AddMessageNoteState,
  type MessageStatusState,
} from "./state";

type MessageStatus = "TO_PROCESS" | "PROCESSED";

type ActionRpcClient = {
  rpc: (
    name: string,
    args: Record<string, unknown>
  ) => Promise<{ error: { message?: string } | null }>;
};

type ActionDependencies = {
  client?: ActionRpcClient;
  revalidate?: (path: string) => void;
};

function readString(value: FormDataEntryValue | null) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeContent(value: FormDataEntryValue | null) {
  if (typeof value !== "string") return "";
  return value.trim().replace(/\r\n/g, "\n");
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

async function resolveClient(dependencies?: ActionDependencies) {
  if (dependencies?.client) return dependencies.client;
  return await createClient() as unknown as ActionRpcClient;
}

function resolveRevalidate(dependencies?: ActionDependencies) {
  return dependencies?.revalidate ?? revalidatePath;
}

export async function addMessageNote(
  _previousState: AddMessageNoteState = initialAddMessageNoteState,
  formData: FormData,
  dependencies?: ActionDependencies
): Promise<AddMessageNoteState> {
  const messageId = readString(formData.get("message_id"));
  const content = normalizeContent(formData.get("content"));
  const values = { content };

  if (!isUuid(messageId)) {
    return { status: "error", message: "Ce message n’est pas valide.", values };
  }

  if (!content) {
    return { status: "error", message: "Écrivez une note.", values };
  }

  const supabase = await resolveClient(dependencies);
  const { error } = await supabase.rpc("boralog_add_message_note", {
    p_message_id: messageId,
    p_content: content,
  });

  if (error) {
    return {
      status: "error",
      message: "La note n’a pas pu être ajoutée. Réessayez.",
      values,
    };
  }

  const revalidate = resolveRevalidate(dependencies);
  revalidate(`/messages/${messageId}`);
  revalidate("/messages");

  return {
    status: "success",
    message: "Note ajoutée.",
    values: { content: "" },
  };
}

export async function setMessageStatus(
  _previousState: MessageStatusState = initialMessageStatusState,
  formData: FormData,
  dependencies?: ActionDependencies
): Promise<MessageStatusState> {
  const messageId = readString(formData.get("message_id"));
  const status = readString(formData.get("status")) as MessageStatus;

  if (!isUuid(messageId)) {
    return { status: "error", message: "Ce message n’est pas valide." };
  }

  if (status !== "TO_PROCESS" && status !== "PROCESSED") {
    return { status: "error", message: "Le nouvel état n’est pas valide." };
  }

  const supabase = await resolveClient(dependencies);
  const { error } = await supabase.rpc("boralog_set_message_status", {
    p_message_id: messageId,
    p_status: status,
  });

  if (error) {
    return {
      status: "error",
      message: "L’état du message n’a pas pu être modifié. Réessayez.",
    };
  }

  const revalidate = resolveRevalidate(dependencies);
  revalidate(`/messages/${messageId}`);
  revalidate("/messages");

  return {
    status: "success",
    message: status === "PROCESSED" ? "Message marqué traité." : "Message remis à traiter.",
  };
}
