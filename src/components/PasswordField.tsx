"use client";

import { Eye, EyeOff } from "lucide-react";
import { useState } from "react";

export function PasswordField({
  autoComplete,
  disabled,
  label = "Mot de passe",
  name = "password",
}: {
  autoComplete: "current-password" | "new-password";
  disabled: boolean;
  label?: string;
  name?: string;
}) {
  const [visible, setVisible] = useState(false);
  const visibilityLabel = visible ? `Masquer ${label.toLowerCase()}` : `Afficher ${label.toLowerCase()}`;

  return <label>
    {label}
    <span className="password-field">
      <input
        name={name}
        type={visible ? "text" : "password"}
        autoComplete={autoComplete}
        minLength={8}
        required
        disabled={disabled}
      />
      <button
        className="password-visibility"
        type="button"
        aria-label={visibilityLabel}
        title={visibilityLabel}
        onClick={() => setVisible((current) => !current)}
        disabled={disabled}
      >
        {visible ? <EyeOff size={20} aria-hidden="true" /> : <Eye size={20} aria-hidden="true" />}
      </button>
    </span>
  </label>;
}
