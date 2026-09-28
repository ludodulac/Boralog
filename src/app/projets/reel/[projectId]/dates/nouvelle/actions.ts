"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../../../../../lib/supabase/server";
import { initialCreateDateState, type CreateDateState } from "./state";

export type { CreateDateState } from "./state";

const datePattern = /^\d{4}-\d{2}-\d{2}$/;
const timePattern = /^([01]\d|2[0-3]):[0-5]\d$/;

function optionalText(value: FormDataEntryValue | null) {
  if (typeof value !== "string") return null;
  const normalized = value.trim().replace(/\s+/g, " ");
  return normalized || null;
}

export async function createDate(
  _previousState: CreateDateState = initialCreateDateState,
  formData: FormData
): Promise<CreateDateState> {
  const projectId = String(formData.get("project_id") ?? "");
  const eventDate = String(formData.get("date") ?? "").trim();
  const time = String(formData.get("time") ?? "").trim();
  const city = optionalText(formData.get("city"));
  const venue = optionalText(formData.get("venue"));
  const values = { date: eventDate, time, city: city ?? "", venue: venue ?? "" };

  if (!datePattern.test(eventDate)) return { status: "error", message: "Indiquez une date valide.", values };
  if (time && !timePattern.test(time)) return { status: "error", message: "Indiquez une heure valide.", values };

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) return { status: "error", message: "Votre session n’est plus valide. Reconnectez-vous puis réessayez.", values };

  const { data: project, error: projectError } = await supabase.from("projects").select("id").eq("id", projectId).maybeSingle();
  if (projectError || !project) return { status: "error", message: "Ce projet n’est pas accessible.", values };

  const startsAt = time ? `${eventDate}T${time}:00` : null;
  const { error } = await supabase.from("events").insert({
    project_id: project.id,
    event_date: eventDate,
    starts_at: startsAt,
    city,
    venue_name: venue,
    status: "draft",
    created_by: authData.user.id,
  });

  if (error) return { status: "error", message: "La date n’a pas pu être enregistrée. Vérifiez votre connexion puis réessayez.", values };

  revalidatePath(`/projets/reel/${project.id}/dates`);
  return { status: "success", message: "Date enregistrée", values };
}
