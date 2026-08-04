"use client";

/**
 * Back-compat wrapper for e2e / older imports.
 * New UI uses EventEditorModal directly from CalendarShell.
 */
export { EventEditorModal as CreateEventModal } from "./EventEditorModal";
export type { EventEditorSave as CreateEventModalSubmit } from "./EventEditorModal";
