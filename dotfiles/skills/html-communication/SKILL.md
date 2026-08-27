---
name: html-communication
description: Use when the user wants a plan, spec, writeup, findings, summary, report, comparison, or UI mocks presented as readable HTML, or mentions HTML with no additional context.
---

# HTML Communication

Create one complete static HTML document for communicating with the user. Write it like a useful spec or working document, not a promotional landing page. Do not use this skill for HTML that ships as part of the product.

Keep the file self-contained and no larger than 512 KB.

Allowed:

- semantic HTML;
- inline CSS or a `<style>` block;
- normal document metadata such as charset, viewport, and title;
- links to ordinary HTTPS pages;
- images from HTTPS or data URLs when necessary.

Do not include:

- JavaScript, `<script>` tags, or inline event handlers;
- `javascript:` URLs;
- forms;
- iframes, embeds, objects, or applets;
- meta refresh redirects;
- secrets, tokens, private URLs, or local filesystem paths.

Match the document to the request. Prefer clear hierarchy, concise prose, and direct comparisons over decoration. When presenting UI mocks:

- create several genuinely different options;
- label them `A`, `B`, `C`, and so on for easy selection;
- place them where they can be compared directly;
- keep explanation secondary to the mocks.

Use one stable local file across revisions. The PostPlan CLI remembers the draft associated with that absolute file path, so uploading the file again updates the existing document while preserving its public URL.

If the user requests a local-only document, return the local file and do not upload it. Otherwise publish the finished document:

```sh
postplan upload <file-path> --description "Short purpose"
```

Use `--new` only when the user wants a separate draft. PostPlan stores CLI authentication and local-file draft mappings in `~/.postplan`.

Treat publication as successful only when the command succeeds. Return the clickable PostPlan URL and the local file. Never claim the document is hosted before upload succeeds.

Do not open or visually verify the hosted page unless the user asks.
