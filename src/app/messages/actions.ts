"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../lib/supabase/server";
import { initialCreateMessageState, type CreateMessageState } from "./state";

export type { CreateMessageState } from "./state";

type MessageVisibility = "ORGANIZATION" | "RESTRICTED";
type MessageContextMode = "NONE" | "PROJECT" | "DATE";

function normalizeContent(value: FormDataEntryValue | null) {
  if (typeof value !== "string") return "";
  return value.trim().replace(/\r\n/g, "\n");
}

function readString(value: FormDataEntryValue | null) {
  return typeof value === "string" ? value.trim() : "";
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function readVisibility(value: FormDataEntryValue | null): MessageVisibility | null {
  if (value === "ORGANIZATION" || value === "RESTRICTED") return value;
  return null;
}

function readContextMode(value: FormDataEntryValue | null): MessageContextMode | null {
  if (value === "NONE" || value === "PROJECT" || value === "DATE") return value;
  return null;
}

export async function createMessage(
  _previousState: CreateMessageState = initialCreateMessageState,
  formData: FormData
): Promise<CreateMessageState> {
  const content = normalizeContent(formData.get("content"));
  const visibility = readVisibility(formData.get("visibility"));
  const contextMode = readContextMode(formData.get("context_mode"));
  const projectId = readString(formData.get("project_id"));
  const eventId = readString(formData.get("event_id"));
  const rawRecipientIds = formData
    .getAll("recipient_user_ids")
    .filter((value): value is string => typeof value === "string")
    .map((value) => value.trim())
    .filter(Boolean);
  const recipientUserIds = [...new Set(rawRecipientIds)];
  const values = { content };

  if (!content) {
    return { status: "error", message: "Écrivez un message.", values };
  }

  if (!visibility) {
    return { status: "error", message: "Choisissez qui peut lire ce message.", values };
  }

  if (recipientUserIds.some((recipientId) => !isUuid(recipientId))) {
    return { status: "error", message: "La sélection de personnes n’est pas valide.", values };
  }

  if (visibility === "RESTRICTED" && recipientUserIds.length === 0) {
    return { status: "error", message: "Choisissez au moins une personne.", values };
  }

  if (visibility === "ORGANIZATION" && recipientUserIds.length > 0) {
    return { status: "error", message: "La sélection de personnes n’est pas valide.", values };
  }

  if (!contextMode) {
    return { status: "error", message: "Choisissez un contexte.", values };
  }

  if (contextMode === "NONE" && (projectId || eventId)) {
    return { status: "error", message: "Le contexte sélectionné n’est pas valide.", values };
  }

  if (contextMode === "PROJECT" && (!isUuid(projectId) || eventId)) {
    return { status: "error", message: "Choisissez un projet.", values };
  }

  if (contextMode === "DATE" && (!isUuid(eventId) || projectId)) {
    return { status: "error", message: "Choisissez une date.", values };
  }

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) {
    return {
      status: "error",
      message: "Votre session n’est plus valide. Reconnectez-vous puis réessayez.",
      values,
    };
  }

  const { data: memberships, error: membershipError } = await supabase
    .from("organization_memberships")
    .select("organization_id, access_level")
    .eq("user_id", authData.user.id)
    .eq("status", "active")
    .limit(1);

  const membership = memberships?.[0];
  if (membershipError || !membership) {
    return {
      status: "error",
      message: "Aucune structure active n’est accessible.",
      values,
    };
  }

  if (
    membership.access_level === "limited"
    && visibility === "ORGANIZATION"
    && contextMode === "NONE"
  ) {
    return {
      status: "error",
      message: "Choisissez un projet ou une date pour ce message.",
      values,
    };
  }

  const { error } = await supabase.rpc("boralog_create_internal_message", {
    p_organization_id: membership.organization_id,
    p_content: content,
    p_visibility: visibility,
    p_recipient_user_ids: visibility === "RESTRICTED" ? recipientUserIds : [],
    p_project_id: contextMode === "PROJECT" ? projectId : null,
    p_event_id: contextMode === "DATE" ? eventId : null,
  });

  if (error) {
    return {
      status: "error",
      message: "Le message n’a pas pu être enregistré. Vérifiez les choix puis réessayez.",
      values,
    };
  }

  revalidatePath("/messages");
  return {
    status: "success",
    message: "Message enregistré.",
    values: { content: "" },
  };
}
