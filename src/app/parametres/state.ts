export type StructureRenameState =
  | { status: "idle"; message: "" }
  | { status: "error"; message: string }
  | { status: "success"; message: string };

export const initialStructureRenameState: StructureRenameState = {
  status: "idle",
  message: "",
};
