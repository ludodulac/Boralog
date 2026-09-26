import { AppShellRender } from "../../../../components/AppShell";
export const dynamic = "force-dynamic";
export default function DiagnosticWithOrgPage() {
 const id="11111111-1111-4111-8111-111111111111";
 const identity={userId:id,email:"synthetic@example.invalid",profile:{id,display_name:"Profil Test",professional_email:null},organization:{id:"22222222-2222-4222-8222-222222222222",name:"Structure Test",accessLevel:"owner" as const},hasOrganization:true};
 return <AppShellRender identity={identity} pathname="/">{<div>DEMO_FIXTURE_SENTINEL_045</div>}</AppShellRender>;
}
