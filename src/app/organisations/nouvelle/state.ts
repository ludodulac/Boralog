export type CreateOrganizationState = {
  status: "idle" | "success" | "error";
  message: string;
};

export const initialCreateOrganizationState: CreateOrganizationState = { status: "idle", message: "" };
