# Sewlore Tool Embed Starter

A small developer integration example for embedding the live Fabric Stretch Lab and PDF Print Scale Checker in a sewing resource page. It contains two iframe examples, copyable HTML, accessible frame titles, responsive styling and visible fallback links. The calculators remain in the live Hugging Face app; this folder does not contain a second calculator implementation.

## Run locally

From this folder, with Node.js available:

```sh
npm start
```

Or run `node serve.mjs` directly. There are no dependencies and no install step. Open `http://localhost:3000`. To use another port, set the `PORT` environment variable before starting; `PORT=0` lets the operating system choose an available port.

The server uses Node built-ins and serves only files within this example folder, regardless of the current working directory. It supports GET and HEAD, returns MIME types for the example assets, rejects traversal and Windows alternate path syntax, and checks resolved symlink targets before serving a file. It has no upload, API or directory listing endpoint.

## Planned StackBlitz import

**Status: prepared locally; this example's StackBlitz import has not been opened or verified.** A maintainer must first publish this folder to the public repository's `main` branch and then check the import, server preview, frames and copy controls in StackBlitz. This link is a planned GitHub import, not a claim that a saved StackBlitz project exists:

[Planned StackBlitz import — unverified](https://stackblitz.com/github/gokimedia/sewlore-sewing-tools/tree/main/examples/stackblitz-embed?file=index.html)

To give a visitor their own editable copy instead, use the [planned fork import — also unverified](https://stackblitz.com/fork/github/gokimedia/sewlore-sewing-tools/tree/main/examples/stackblitz-embed?file=index.html).

StackBlitz imports only this subfolder's contents, so the starter has no relative dependencies on the repository root. The `start` script is `node serve.mjs`; StackBlitz's documented default chooses `start` when there is no `dev` script. A `.stackblitzrc` or custom `startCommand` is therefore unnecessary. The `stackblitz.installDependencies: false` setting in `package.json` avoids an automatic dependency install for this dependency-free example.

## Embed URLs and fallback pages

| Initial tool | Live iframe URL | Visible fallback |
| --- | --- | --- |
| Fabric Stretch Lab | [HF stretch embed](https://sewlore-sewlore-sewing-tools.static.hf.space/index.html?embed=1&tool=stretch) | [Sewlore fabric stretch calculator](https://sewlore.com/pages/fabric-stretch-calculator) |
| PDF Print Scale Checker | [HF print embed](https://sewlore-sewlore-sewing-tools.static.hf.space/index.html?embed=1&tool=print-scale) | [Sewlore PDF print scale checker](https://sewlore.com/pages/pdf-pattern-print-scale-checker) |

`embed=1` selects the app's compact embedded layout; `tool` selects its initial tab. Both tabs remain available. Do not add a `#stretch` or `#print-scale` fragment to these iframe URLs: a valid fragment takes priority over `tool` and can cause native anchor scrolling. These parameters belong to the Sewlore app, not to the StackBlitz editor.

Copy one of the snippets from the preview, keep the meaningful `title`, and adjust `height` for the destination page. Copy controls use the browser Clipboard API, which usually requires HTTPS or localhost. If clipboard access is unavailable, the control selects the snippet for manual copying. The snippets use `&amp;` between HTML attribute query parameters.

Keep a visible fallback link near the frame. A visitor's browser, network or destination content security policy may block external iframes. This example uses `referrerpolicy="no-referrer"` and does not attempt to read cross-origin frame content. If the destination has a content security policy, its allowed frame sources need to include `https://sewlore-sewlore-sewing-tools.static.hf.space`. Check the destination's actual layout and policies before release.

## Privacy and optional attribution

The live app calculates locally in the browser, does not upload entered measurements and adds no analytics. This starter does not collect measurements, set cookies or add analytics. Hosting services still receive normal requests to load pages and assets. StackBlitz also receives the requests needed to run its editor and preview when the example is opened there. Following an external link uses the destination site's own privacy practices.

Both default snippets omit `source`. Leave it out for an embed on Sewlore so navigation within the site is not labelled as a referral. A partner can opt into outbound source attribution by adding an agreed value, for example `&source=partner_name`, to the iframe URL. Encode this as `&amp;source=partner_name` in HTML. This setting tags outbound Sewlore links and does not send the measurement inputs. Do not add attribution on the partner's behalf without that choice.

## Files

- `index.html`: two live iframe examples, fallback links and integration notes.
- `styles.css`: original responsive layout and visible keyboard focus states.
- `embed.js`: copy helper with manual selection fallback.
- `serve.mjs`: dependency-free static preview server restricted to this folder.
- `package.json`: module type, `start` script and StackBlitz install preference.
- `LICENSE`: the repository's MIT license included for subfolder imports.

## Local verification

Checked on 2026-10-05: Node syntax checks passed for `serve.mjs` and `embed.js`; `package.json` parsed with no dependencies; both displayed HTML snippets parsed to the same URLs and titles as their live frames. Seventeen local HTTP checks passed, covering asset GETs and MIME types, HEAD, missing files, rejected POST, encoded and plain traversal, Windows path syntax, invalid encoding and a null byte. The server was started from the parent directory to verify that its file root remains this example folder.

Browser layout, clipboard interaction, the live frames inside a StackBlitz preview and the planned StackBlitz import have not been verified by these checks. There is no install, deployment or saved StackBlitz project as part of this preparation.

## Official references

The GitHub subdirectory URL format, fork option and script selection are documented in [StackBlitz: Launching projects from GitHub](https://developer.stackblitz.com/guides/integration/open-from-github). The supported `package.json` configuration, `installDependencies` and `startCommand` defaults are documented in [StackBlitz: Project configuration](https://developer.stackblitz.com/platform/webcontainers/project-config). Both references were checked on 2026-10-05.

This source example follows the repository's MIT license. External hosts and services retain their own terms.
