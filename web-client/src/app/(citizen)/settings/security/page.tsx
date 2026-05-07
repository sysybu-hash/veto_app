import { redirect } from "next/navigation";



export default function SettingsSecurityLegacyPage() {

  redirect("/settings?tab=security");

}

