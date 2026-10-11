"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { SHARED_MESSAGE_STORAGE_KEY } from "../lib/android-share";

export function ImportClipboardButton() {
  const router = useRouter();
  const [error, setError] = useState("");
  const [pending, setPending] = useState(false);

  async function importClipboard() {
    setError("");

    if (!navigator.clipboard?.readText) {
      setError("BORALOG n’a pas pu lire le presse-papiers. Copiez le message puis réessayez.");
      return;
    }

    setPending(true);
    try {
      const text = (await navigator.clipboard.readText()).trim();
      if (!text) {
        setError("Aucun texte copié. Copiez d’abord un message puis réessayez.");
        return;
      }

      sessionStorage.setItem(SHARED_MESSAGE_STORAGE_KEY, text);
      router.push("/messages/partager");
    } catch {
      setError("BORALOG n’a pas pu lire le presse-papiers. Copiez le message puis réessayez.");
    } finally {
      setPending(false);
    }
  }

  return <div className="person-stack">
    <button
      className="person-primary-link"
      type="button"
      onClick={() => void importClipboard()}
      disabled={pending}
    >
      {pending ? "Lecture…" : "Importer le texte copié"}
    </button>
    <small>Copiez un message dans WhatsApp, puis appuyez ici.</small>
    {error && <p className="person-feedback error" role="alert">{error}</p>}
  </div>;
}
