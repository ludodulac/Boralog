"use client";

import { Eye, EyeOff } from "lucide-react";
import { useState } from "react";

export function PasswordField({ autoComplete, disabled }: { autoComplete: "current-password" | "new-password"; disabled: boolean }) {
  const [visible, setVisible] = useState(false);
  const label = visible ? "Masquer le mot de passe" : "Afficher le mot de passe";

  return <label>
    Mot de passe
    <span className="password-field">
      <input
        name="password"
        type={visible ? "text" : "password"}
        autoComplete={autoComplete}
        minLength={8}
        required
        disabled={disabled}
      />
      <button
        className="password-visibility"
        type="button"
        aria-label={label}
        title={label}
        onClick={() => setVisible((current) => !current)}
        disabled={disabled}
      >
        {visible ? <EyeOff size={20} aria-hidden="true" /> : <Eye size={20} aria-hidden="true" />}
      </button>
    </span>
  </label>;
}
