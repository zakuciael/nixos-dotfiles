---
name: postplan
description: Create and upload safe static HTML drafts to Postplan, or read and implement plans supplied as postplan.dev URLs. Use whenever a user provides a Postplan URL or asks to publish a plan, proposal, brief, architecture note, or similar artifact with Postplan.
---

# Postplan

## Read a Postplan URL

When a user supplies a `postplan.dev` URL, fetch the uploaded HTML immediately with the shell. Do not use web search or a browser to retrieve it.

1. Remove a trailing slash, then append `/raw` unless the URL already ends in `/raw`.
2. Run `curl --fail --silent --show-error --location --max-time 30 --output /tmp/postplan.html '<raw-url>'`.
3. Read `/tmp/postplan.html` as the user's artifact and continue the requested task.

A web-search refusal is not evidence that Postplan rejected the request. If `curl` fails, report its actual status or network error; do not substitute search results.

## Document Rules

Create one complete static HTML document.

Allowed:

- Semantic HTML.
- Inline CSS or a `<style>` block.
- Normal document metadata such as charset, viewport, and title.
- Links to ordinary HTTPS pages.
- Images from HTTPS or data URLs when necessary.

Do not include:

- JavaScript.
- `<script>` tags.
- Inline event handlers such as `onclick`, `onload`, or `onerror`.
- `javascript:` URLs.
- Forms.
- Iframes, embeds, objects, or applets.
- Meta refresh redirects.
- Secrets, tokens, private URLs, or local filesystem paths.

## Upload Flow

1. Write the HTML file locally.
2. Run:

   ```sh
   npx postplan upload <file path>
   ```

3. Return the Postplan URL to the user.

The CLI prints both a draft URL and a `Raw HTML` URL. Either works for any client; hand the `Raw HTML` URL to another agent when you want the most explicit form.

If the same local file was uploaded before, the CLI updates the existing draft. To force a new draft, use:

```sh
npx postplan upload <file path> --new
```

Postplan stores CLI auth and draft mappings in `~/.postplan`.

## Viewer Behavior

Every Postplan URL serves the exact uploaded HTML, byte for byte, to every client — browsers, curl, and agent fetch tools alike. There is no wrapper page, sandbox, or consent step: fetching a Postplan URL always yields the draft content itself. The `/raw` suffix is an alias that returns the same bytes.
