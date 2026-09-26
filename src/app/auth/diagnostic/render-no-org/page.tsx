import { AppShellRender } from "../../../../components/AppShell";
export const dynamic = "force-dynamic";
export default function DiagnosticNoOrgPage() {
 const id="11111111-1111-4111-8111-111111111111";
 const identity={userId:id,email:"synthetic@example.invalid",profile:{id,display_name:"Profil Test",professional_email:null},organization:null,hasOrganization:false};
 return <AppShellRender identity={identity} pathname="/">{<div>UNEXPECTED_CHILD_045</div>}</AppShellRender>;
}
