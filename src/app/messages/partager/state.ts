export type SharedMessageState =
  | { status: "idle"; message: "" }
  | { status: "error"; message: string }
  | { status: "success"; message: string };

export const initialSharedMessageState: SharedMessageState = { status: "idle", message: "" };
