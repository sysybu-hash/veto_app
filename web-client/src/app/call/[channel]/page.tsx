import CallRoom from "./CallRoom";

export default async function CallPage({
  params,
}: {
  params: Promise<{ channel: string }>;
}) {
  const { channel: raw } = await params;
  const channel = decodeURIComponent(raw);
  return <CallRoom channel={channel} />;
}
