"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "../../../../../../lib/supabase/server";
import { initialCreateDateState, type CreateDateState, type CreateDateValues } from "./state";

function clean(value: FormDataEntryValue | null) {
  return typeof value === "string" ? value.trim().replace(/\s+/g, " ") : "";
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function validCivilDate(value: string) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [year, month, day] = value.split("-").map(Number);
  const check = new Date(Date.UTC(year, month - 1, day));
  return check.getUTCFullYear() === year && check.getUTCMonth() === month - 1 && check.getUTCDate() === day;
}

function startsAtFromLocal(date: string, time: string, offsetText: string) {
  if (!time) return { ok: true as const, value: null };
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(time) || !/^-?\d{1,3}$/.test(offsetText)) return { ok: false as const };
  const browserOffset = Number(offsetText);
  if (!Number.isInteger(browserOffset) || Math.abs(browserOffset) > 840) return { ok: false as const };
  const isoOffsetMinutes = -browserOffset;
  const sign = isoOffsetMinutes >= 0 ? "+" : "-";
  const absolute = Math.abs(isoOffsetMinutes);
  const hours = String(Math.floor(absolute / 60)).padStart(2, "0");
  const minutes = String(absolute % 60).padStart(2, "0");
  const value = `${date}T${time}:00${sign}${hours}:${minutes}`;
  return Number.isNaN(Date.parse(value)) ? { ok: false as const } : { ok: true as const, value };
}

export async function createDate(
  projectId: string,
  _previousState: CreateDateState = initialCreateDateState,
  formData: FormData
): Promise<CreateDateState> {
  const values: CreateDateValues = {
    date: clean(formData.get("date")),
    time: clean(formData.get("time")),
    city: clean(formData.get("city")),
    venue: clean(formData.get("venue")),
  };
  if (!isUuid(projectId)) return { status: "error", message: "Ce projet n’est plus valide.", values };
  if (!validCivilDate(values.date)) return { status: "error", message: "Indiquez une date valide.", values };

  const startsAt = startsAtFromLocal(values.date, values.time, clean(formData.get("timezone_offset")));
  if (!startsAt.ok) return { status: "error", message: "L’heure indiquée n’est pas valide. Réessayez.", values };

  const attemptId = clean(formData.get("attempt_id"));
  if (!isUuid(attemptId)) return { status: "error", message: "Cette tentative n’est plus valide. Rechargez la page puis réessayez.", values };

  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) return { status: "error", message: "Votre session n’est plus valide. Reconnectez-vous puis réessayez.", values };

  const { data: project, error: projectError } = await supabase.from("projects").select("id").eq("id", projectId).maybeSingle();
  if (projectError || !project) return { status: "error", message: "Ce projet n’est pas accessible.", values };

  const { data: existing, error: existingError } = await supabase.from("events").select("id").eq("id", attemptId).eq("project_id", projectId).maybeSingle();
  if (!existingError && existing) {
    revalidatePath(`/projets/reel/${projectId}/dates`);
    return { status: "success", message: "Date créée", values };
  }

  const { error } = await supabase.from("events").insert({
    id: attemptId,
    project_id: projectId,
    event_date: values.date,
    starts_at: startsAt.value,
    city: values.city || null,
    venue_name: values.venue || null,
    status: "draft",
    created_by: authData.user.id,
  });

  if (error) {
    const { data: recovered } = await supabase.from("events").select("id").eq("id", attemptId).eq("project_id", projectId).maybeSingle();
    if (!recovered) return { status: "error", message: "La date n’a pas pu être créée. Vérifiez votre connexion puis réessayez.", values };
  }

  revalidatePath(`/projets/reel/${projectId}/dates`);
  return { status: "success", message: "Date créée", values };
}
