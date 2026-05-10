import { CallRoomNoSsr } from "./CallRoomNoSsr";

export default async function CallPage({
  params,
}: {
  params: Promise<{ channel: string }>;
}) {
  const { channel: raw } = await params;
  const channel = decodeURIComponent(raw);
  return <CallRoomNoSsr channel={channel} />;
}
