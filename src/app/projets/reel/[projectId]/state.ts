export type ProjectEditState =
  | { status: "idle"; message: "" }
  | { status: "error"; message: string }
  | { status: "success"; message: string };

export const initialProjectEditState: ProjectEditState = { status: "idle", message: "" };
