"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../lib/supabase/server";
import { initialCreateMessageState, type CreateMessageState } from "./state";

export type { CreateMessageState } from "./state";

function normalizeContent(value: FormDataEntryValue | null) {
  if (typeof value !== "string") return "";
  return value.trim().replace(/\r\n/g, "\n");
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

export async function createMessage(
  _previousState: CreateMessageState = initialCreateMessageState,
  formData: FormData
): Promise<CreateMessageState> {
  const content = normalizeContent(formData.get("content"));
  const projectId = String(formData.get("project_id") ?? "").trim();
  const eventId = String(formData.get("event_id") ?? "").trim();
  const values = { content, projectId, eventId };

  if (!content) {
    return { status: "error", message: "Écrivez le message à traiter.", values };
  }

  if (projectId && !isUuid(projectId)) {
    return { status: "error", message: "Le projet sélectionné n’est pas valide.", values };
  }

  if (eventId && !isUuid(eventId)) {
    return { status: "error", message: "La date sélectionnée n’est pas valide.", values };
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

  let validatedProjectId: string | null = null;
  let validatedEventId: string | null = null;

  if (projectId) {
    const { data: project, error: projectError } = await supabase
      .from("projects")
      .select("id")
      .eq("id", projectId)
      .eq("organization_id", membership.organization_id)
      .is("archived_at", null)
      .maybeSingle();

    if (projectError || !project) {
      return {
        status: "error",
        message: "Ce projet n’est pas accessible.",
        values,
      };
    }

    validatedProjectId = project.id;
  }

  if (eventId) {
    const { data: selectedEvent, error: eventError } = await supabase
      .from("events")
      .select("id, project_id")
      .eq("id", eventId)
      .maybeSingle();

    if (eventError || !selectedEvent) {
      return {
        status: "error",
        message: "Cette date n’est pas accessible.",
        values,
      };
    }

    const { data: eventProject, error: eventProjectError } = await supabase
      .from("projects")
      .select("id")
      .eq("id", selectedEvent.project_id)
      .eq("organization_id", membership.organization_id)
      .is("archived_at", null)
      .maybeSingle();

    if (eventProjectError || !eventProject) {
      return {
        status: "error",
        message: "Cette date n’est pas accessible dans cette structure.",
        values,
      };
    }

    if (validatedProjectId && validatedProjectId !== eventProject.id) {
      return {
        status: "error",
        message: "La date sélectionnée n’appartient pas au projet choisi.",
        values,
      };
    }

    validatedProjectId = eventProject.id;
    validatedEventId = selectedEvent.id;
  }

  if (membership.access_level === "limited" && !validatedProjectId) {
    return {
      status: "error",
      message: "Choisissez un projet ou une date accessible pour créer ce message.",
      values,
    };
  }

  const { error } = await supabase.from("messages").insert({
    organization_id: membership.organization_id,
    project_id: validatedProjectId,
    event_id: validatedEventId,
    content,
    created_by: authData.user.id,
  });

  if (error) {
    return {
      status: "error",
      message: "Le message n’a pas pu être enregistré. Vérifiez votre connexion puis réessayez.",
      values,
    };
  }

  revalidatePath("/messages");
  return {
    status: "success",
    message: "Message enregistré.",
    values: { content: "", projectId: "", eventId: "" },
  };
}
