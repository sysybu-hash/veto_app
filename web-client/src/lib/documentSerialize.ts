/**
 * Reads the edited state of the document generator's `contentEditable`
 * article back out of the DOM into the structured shape the server
 * renderer expects. The article is a single `contentEditable` region
 * (see `vault/generator/page.tsx`), so React state no longer reflects
 * user edits after the first keystroke — this is the only source of
 * truth for "what the user actually has on screen right now".
 *
 * Each editable node carries `data-field="<key>"` (and `data-index` for
 * array entries), set once at render time in the generator page's JSX.
 */

export type SerializedLegalDocument = {
  title: string;
  preamble: string;
  parties: string[];
  definitions: string[];
  clauses: string[];
  attachments: string[];
  completionChecklist: string[];
  legalNotes: string[];
  signatures: { role: string; name: string }[];
};

function textOf(el: Element | null | undefined): string {
  return (el?.textContent ?? "").replace(/ /g, " ").trim();
}

function collectIndexed(root: HTMLElement, field: string): string[] {
  const nodes = Array.from(root.querySelectorAll(`[data-field="${field}"]`));
  return nodes
    .sort((a, b) => {
      const ai = Number(a.getAttribute("data-index") ?? 0);
      const bi = Number(b.getAttribute("data-index") ?? 0);
      return ai - bi;
    })
    .map((n) => textOf(n))
    .filter((t) => t.length > 0);
}

export function serializeDocumentFromDom(root: HTMLElement): SerializedLegalDocument {
  const title = textOf(root.querySelector('[data-field="title"]'));
  const preamble = textOf(root.querySelector('[data-field="preamble"]'));
  const parties = collectIndexed(root, "parties");
  const definitions = collectIndexed(root, "definitions");
  const clauses = collectIndexed(root, "clauses");
  const attachments = collectIndexed(root, "attachments");
  const completionChecklist = collectIndexed(root, "completionChecklist");
  const legalNotes = collectIndexed(root, "legalNotes");

  const roleNodes = Array.from(root.querySelectorAll('[data-field="signatureRole"]'));
  const signatures = roleNodes
    .sort((a, b) => Number(a.getAttribute("data-index") ?? 0) - Number(b.getAttribute("data-index") ?? 0))
    .map((roleEl) => {
      const idx = roleEl.getAttribute("data-index");
      const nameEl = root.querySelector(`[data-field="signatureName"][data-index="${idx}"]`);
      return { role: textOf(roleEl), name: textOf(nameEl) };
    })
    .filter((s) => s.role.length > 0);

  return { title, preamble, parties, definitions, clauses, attachments, completionChecklist, legalNotes, signatures };
}
