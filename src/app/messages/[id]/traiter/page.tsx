import { redirect } from "next/navigation";

export default async function ProcessMessagePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  redirect(`/messages/${id}`);
}
