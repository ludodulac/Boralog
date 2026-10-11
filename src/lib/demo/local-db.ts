// BORALOG-DEMO-002: browser-only foundation. No Supabase imports.
export const DB_NAME = "boralog-demo";
export const DB_VERSION = 1;
export const STORE_NAMES = [
  "organizations", "users", "organization_memberships", "projects",
  "project_memberships", "people", "companies", "person_companies",
  "messages", "message_notes", "message_reads", "message_recipients",
  "message_status_history", "recipient_groups", "recipient_group_members",
  "informations", "information_message_sources", "tasks",
  "task_message_sources", "events"
] as const;
export type StoreName = typeof STORE_NAMES[number];
export type LocalRecord = { id: string; [key: string]: unknown };
export const DEMO_USER_ID = "00000000-0000-4000-8000-000000000001";
export const DEMO_ORG_ID = "00000000-0000-4000-8000-000000000002";
export const DEMO_MEMBERSHIP_ID = "00000000-0000-4000-8000-000000000003";
export const SEED: ReadonlyArray<{ store: StoreName; value: LocalRecord }> = [
  { store: "users", value: { id: DEMO_USER_ID, display_name: "Démonstrateur", fictitious: true } },
  { store: "organizations", value: { id: DEMO_ORG_ID, name: "Compagnie Horizon", created_by: DEMO_USER_ID } },
  { store: "organization_memberships", value: { id: DEMO_MEMBERSHIP_ID, organization_id: DEMO_ORG_ID, user_id: DEMO_USER_ID, role: "owner", access_level: "owner", status: "active" } }
];
export const RELATIONS: Partial<Record<StoreName, ReadonlyArray<{ field: string; target: StoreName }>>> = {
  organizations: [{ field: "created_by", target: "users" }],
  organization_memberships: [{ field: "organization_id", target: "organizations" }, { field: "user_id", target: "users" }],
  projects: [{ field: "organization_id", target: "organizations" }],
  project_memberships: [{ field: "project_id", target: "projects" }, { field: "user_id", target: "users" }],
  people: [{ field: "organization_id", target: "organizations" }],
  companies: [{ field: "organization_id", target: "organizations" }],
  person_companies: [{ field: "person_id", target: "people" }, { field: "company_id", target: "companies" }],
  messages: [{ field: "organization_id", target: "organizations" }, { field: "project_id", target: "projects" }],
  message_notes: [{ field: "message_id", target: "messages" }],
  message_reads: [{ field: "message_id", target: "messages" }],
  message_recipients: [{ field: "message_id", target: "messages" }],
  message_status_history: [{ field: "message_id", target: "messages" }],
  recipient_groups: [{ field: "organization_id", target: "organizations" }],
  recipient_group_members: [{ field: "recipient_group_id", target: "recipient_groups" }],
  informations: [{ field: "organization_id", target: "organizations" }, { field: "project_id", target: "projects" }],
  information_message_sources: [{ field: "information_id", target: "informations" }, { field: "message_id", target: "messages" }],
  tasks: [{ field: "organization_id", target: "organizations" }, { field: "project_id", target: "projects" }],
  task_message_sources: [{ field: "task_id", target: "tasks" }, { field: "message_id", target: "messages" }],
  events: [{ field: "organization_id", target: "organizations" }, { field: "project_id", target: "projects" }]
};
function requestResult<T>(req: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}
function transactionDone(tx: IDBTransaction): Promise<void> {
  return new Promise((resolve, reject) => {
    tx.oncomplete = () => resolve();
    tx.onabort = () => reject(tx.error ?? new Error("Transaction aborted"));
    tx.onerror = () => reject(tx.error ?? new Error("Transaction failed"));
  });
}
export function openDemoDatabase(factory: IDBFactory = indexedDB): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const req = factory.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = () => {
      const db = req.result;
      for (const name of STORE_NAMES) if (!db.objectStoreNames.contains(name)) db.createObjectStore(name, { keyPath: "id" });
      if (!db.objectStoreNames.contains("_meta")) db.createObjectStore("_meta", { keyPath: "id" });
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
    req.onblocked = () => reject(new Error("Close other demo tabs before upgrading the database"));
  });
}
export async function initializeDemo(db: IDBDatabase): Promise<void> {
  const tx = db.transaction([...STORE_NAMES, "_meta"], "readwrite");
  const done = transactionDone(tx);
  const meta = tx.objectStore("_meta");
  const marker = await requestResult(meta.get("seed-v1"));
  if (!marker) {
    for (const item of SEED) tx.objectStore(item.store).add(item.value);
    meta.add({ id: "seed-v1", initialized_at: new Date().toISOString() });
  }
  await done;
}
export async function getRecord(db: IDBDatabase, store: StoreName, id: string): Promise<LocalRecord | undefined> {
  const tx = db.transaction(store, "readonly");
  const done = transactionDone(tx);
  const value = await requestResult<LocalRecord | undefined>(tx.objectStore(store).get(id));
  await done;
  return value;
}
export async function listRecords(db: IDBDatabase, store: StoreName): Promise<LocalRecord[]> {
  const tx = db.transaction(store, "readonly");
  const done = transactionDone(tx);
  const values = await requestResult<LocalRecord[]>(tx.objectStore(store).getAll());
  await done;
  return values;
}
export type Mutation = { operation: "create" | "update" | "delete"; store: StoreName; id: string; value?: LocalRecord };
export async function mutateDemo(db: IDBDatabase, mutations: Mutation[]): Promise<void> {
  if (!mutations.length) return;
  const tx = db.transaction(STORE_NAMES, "readwrite");
  const done = transactionDone(tx);
  try {
    for (const mutation of mutations) {
      const objectStore = tx.objectStore(mutation.store);
      const existing = await requestResult<LocalRecord | undefined>(objectStore.get(mutation.id));
      if (mutation.operation === "create" && existing) throw new Error("Duplicate id: " + mutation.id);
      if (mutation.operation !== "create" && !existing) throw new Error("Missing record: " + mutation.id);
      if (mutation.operation === "delete") {
        for (const [dependentStore, relations] of Object.entries(RELATIONS) as [StoreName, { field: string; target: StoreName }[]][]) {
          const rows = await requestResult<LocalRecord[]>(tx.objectStore(dependentStore).getAll());
          if (rows.some(row => relations.some(rel => rel.target === mutation.store && row[rel.field] === mutation.id))) {
            throw new Error("Referenced record cannot be deleted: " + mutation.id);
          }
        }
        objectStore.delete(mutation.id);
      } else {
        if (!mutation.value || mutation.value.id !== mutation.id) throw new Error("Invalid mutation id");
        for (const rel of RELATIONS[mutation.store] ?? []) {
          const foreignId = mutation.value[rel.field];
          if (foreignId !== undefined && foreignId !== null && !(await requestResult(tx.objectStore(rel.target).get(foreignId)))) {
            throw new Error("Missing relation " + mutation.store + "." + rel.field);
          }
        }
        if (mutation.operation === "create") objectStore.add(mutation.value);
        else objectStore.put(mutation.value);
      }
    }
  } catch (error) {
    tx.abort();
    await done.catch(() => {});
    throw error;
  }
  await done;
}
