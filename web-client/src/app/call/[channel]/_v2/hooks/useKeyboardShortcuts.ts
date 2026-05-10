"use client";

import { useEffect, useRef } from "react";

export type ShortcutHandlers = {
  toggleMic: () => void;
  toggleCamera: () => void;
  toggleChat: () => void;
  endCall: () => void;
  pushToTalkDown?: () => void;
  pushToTalkUp?: () => void;
};

/**
 * Keyboard shortcuts for the call screen:
 *   M     — toggle microphone
 *   V     — toggle camera
 *   /     — toggle side chat panel
 *   E     — end call
 *   Space — push-to-talk (hold)
 *
 * We intentionally ignore the shortcuts when the user is typing in an
 * input/textarea/contenteditable so the chat draft works normally.
 */
export function useKeyboardShortcuts(handlers: ShortcutHandlers) {
  const handlersRef = useRef(handlers);

  useEffect(() => {
    handlersRef.current = handlers;
  }, [handlers]);

  useEffect(() => {
    if (typeof window === "undefined") return undefined;

    const isTyping = () => {
      const el = document.activeElement;
      if (!el) return false;
      const tag = el.tagName.toLowerCase();
      if (tag === "input" || tag === "textarea" || tag === "select") return true;
      const ce = (el as HTMLElement).isContentEditable;
      return Boolean(ce);
    };

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.repeat) {
        // Push-to-talk benefits from repeats but everything else doesn't.
        if (e.key === " " && !isTyping()) {
          handlersRef.current.pushToTalkDown?.();
        }
        return;
      }
      if (isTyping() && e.key !== "Escape") return;

      const k = e.key.toLowerCase();
      if (k === "m") {
        e.preventDefault();
        handlersRef.current.toggleMic();
      } else if (k === "v") {
        e.preventDefault();
        handlersRef.current.toggleCamera();
      } else if (k === "/") {
        e.preventDefault();
        handlersRef.current.toggleChat();
      } else if (k === "e") {
        e.preventDefault();
        handlersRef.current.endCall();
      } else if (k === " ") {
        e.preventDefault();
        handlersRef.current.pushToTalkDown?.();
      }
    };

    const onKeyUp = (e: KeyboardEvent) => {
      if (e.key === " ") handlersRef.current.pushToTalkUp?.();
    };

    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("keyup", onKeyUp);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("keyup", onKeyUp);
    };
  }, []);
}
