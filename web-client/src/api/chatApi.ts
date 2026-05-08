import { apiUrl, authFetch } from "@/api/apiClient";

export type ChatPartnerRole = "user" | "admin" | "lawyer" | string;

export type ChatConversation = {
  partner_id: string;
  partner_name: string;
  partner_role: ChatPartnerRole;
  last_message: string;
  last_message_at: string | null;
  unread_count: number;
};

export type ChatPartner = {
  id: string;
  name: string;
  role: ChatPartnerRole;
};

export type ChatMessage = {
  _id: string;
  sender_id: string;
  sender_role: ChatPartnerRole;
  receiver_id: string;
  receiver_role: ChatPartnerRole;
  text: string;
  read?: boolean;
  createdAt?: string;
  updatedAt?: string;
};

async function parseJsonError(res: Response): Promise<string> {
  try {
    const j = (await res.json()) as { error?: string; message?: string };
    return j.error || j.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

export async function fetchChatConversations(): Promise<ChatConversation[]> {
  const res = await authFetch(apiUrl("/api/chat/conversations"));
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { conversations?: ChatConversation[] };
  return Array.isArray(data.conversations) ? data.conversations : [];
}

export async function fetchChatPartners(): Promise<ChatPartner[]> {
  const res = await authFetch(apiUrl("/api/chat/partners"));
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { partners?: ChatPartner[] };
  return Array.isArray(data.partners) ? data.partners : [];
}

export async function fetchChatMessages(
  partnerId: string,
  page = 1,
): Promise<ChatMessage[]> {
  const res = await authFetch(
    apiUrl(`/api/chat/messages/${encodeURIComponent(partnerId)}?page=${page}`),
  );
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { messages?: ChatMessage[] };
  return Array.isArray(data.messages) ? data.messages : [];
}

export async function sendChatMessage(payload: {
  receiver_id: string;
  receiver_role: ChatPartnerRole;
  text: string;
}): Promise<ChatMessage> {
  const res = await authFetch(apiUrl("/api/chat/messages"), {
    method: "POST",
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { message?: ChatMessage };
  if (!data.message) throw new Error("Invalid chat response");
  return data.message;
}

export async function deleteChatMessage(messageId: string): Promise<void> {
  const res = await authFetch(
    apiUrl(`/api/chat/messages/${encodeURIComponent(messageId)}`),
    { method: "DELETE" },
  );
  if (!res.ok) throw new Error(await parseJsonError(res));
}

export async function deleteChatConversation(partnerId: string): Promise<number> {
  const res = await authFetch(
    apiUrl(`/api/chat/conversations/${encodeURIComponent(partnerId)}`),
    { method: "DELETE" },
  );
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as { deleted?: number };
  return Number(data.deleted ?? 0);
}
