import { SettingsShell } from "@/app/(citizen)/settings/_components/SettingsShell";

export default function AdminSettingsLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return <SettingsShell variant="admin">{children}</SettingsShell>;
}
