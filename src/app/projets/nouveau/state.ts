export type CreateProjectState =
  | { status: "idle"; message: ""; values: { name: ""; description: "" } }
  | { status: "error"; message: string; values: { name: string; description: string } }
  | { status: "success"; message: string; projectId: string; values: { name: string; description: string } };

export const initialCreateProjectState: CreateProjectState = { status: "idle", message: "", values: { name: "", description: "" } };
