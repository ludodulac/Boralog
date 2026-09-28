"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../../../../../lib/supabase/server";

export type CreateDateState = {
  status: "idle" | "error" | "success";
  message: string;
  values: { date: string; time: string; city: string; venue: string };
};

export const initialCreateDateState: CreateDateState = { status: "idle", message: "", values: { date: "", time: "", city: "", venue: "" } };

const clean = (value: FormDataEntryValue | null) => typeof value === "string" ? value.trim() : "";
const validDate = (value: string) => /^\d{4}-\d{2}-\d{2}$/.test(value) && !Number.isNaN(Date.parse(value + "T00:00:00Z"));
const validTime = (value: string) => value === "" || /^(?:[01]\d|2[0-3]):[0-5]\d$/.test(value);

export async function createDate(projectId: string, _previous: CreateDateState, formData: FormData): Promise<CreateDateState> {
  const values = { date: clean(formData.get("date")), time: clean(formData.get("time")), city: clean(formData.get("city")), venue: clean(formData.get("venue")) };
  if (!validDate(values.date)) return { status: "error", message: "Indiquez une date valide.", values };
  if (!validTime(values.time)) return { status: "error", message: "Indiquez une heure valide.", values };

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) return { status: "error", message: "Votre session n’est plus valide. Reconnectez-vous puis réessayez.", values };

  const { data: project, error: projectError } = await supabase.from("projects").select("id").eq("id", projectId).maybeSingle();
  if (projectError || !project) return { status: "error", message: "Ce projet n’est pas accessible.", values };

  // events has only timestamptz for the calendar value. 00:00Z is a storage marker
  // for date-only input; the UI deliberately does not present it as a business time.
  const startsAt = `${values.date}T${values.time || "00:00"}:00Z`;
  const { error } = await supabase.from("events").insert({
    project_id: project.id,
    starts_at: startsAt,
    status: "draft",
    city: values.city || null,
    venue_name: values.venue || null,
    created_by: authData.user.id,
  });

  if (error) return { status: "error", message: "La date n’a pas pu être créée. Vérifiez votre connexion puis réessayez.", values };

  revalidatePath(`/projets/reel/${project.id}/dates`);
  return { status: "success", message: "Date créée.", values };
}
