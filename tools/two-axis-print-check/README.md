# Two-axis PDF print check — self-hostable embed

A small calculator for comparing a printed reference rectangle with its intended width and height. `print-check.html` is one standalone file containing the interface, styles, arithmetic and complete MIT notice. No build step, external library or service is required. It works with JavaScript enabled, including from a local file.

The interface accepts four measurements, so the reference can be a rectangle as well as a square.

## Use

1. Select millimetres, centimetres or inches. All four entries must use the selected unit.
2. Enter intended width and height from the pattern, then measured width and height from the actual printed reference. One point or comma is interpreted as a decimal separator. Thousands separators are unsupported: enter `1000` for one thousand, because `1,000` is interpreted as `1`. Repeated/mixed separators, partial text and exponent notation are rejected.
3. Choose **Compare measurements**. Width and height are reported independently.

Changing the unit invalidates the old result and updates labels. The numbers are retained without conversion; the interface explicitly asks the user to check them before calculating again. Editing any input hides the stale result. The worked example is explicitly labelled as an illustration, not a physical printer observation.

For each direction: scale is `measured / intended * 100`, signed error is `(measured - intended) / intended * 100`, and the length difference is `measured - intended`. The absolute difference between the signed errors is reported in percentage points. Formula semantics match Sewlore's existing `calculations.js`; unlike its square helper, this interface accepts separate intended width and height. No default tolerance, average of axes, pass/fail decision, correction recommendation or claim that a printer/PDF has been fixed is made. Extremely large or small numeric ranges are rejected when the scale cannot be represented as a positive finite number.

## Embed

`embed-example.html` loads the adjacent file and includes an accessible title, a direct-open fallback, lazy loading, a restricted sandbox and no referrer. Open both adjacent files locally to review the example. On a public site, upload the standalone calculator file, verify its actual URL, then replace the relative `src` and fallback link with that verified URL. No assumed Sewlore or GitHub Pages URL has been inserted.

```html
<iframe
  src="./print-check.html"
  title="Two-axis PDF pattern print measurement calculator"
  width="100%"
  height="980"
  loading="lazy"
  sandbox="allow-scripts allow-popups allow-popups-to-escape-sandbox"
  referrerpolicy="no-referrer"
></iframe>
<p><a href="./print-check.html">Open the calculator directly</a></p>
```

The relative URL above is a local example. A host should provide enough height at mobile widths, retain scrolling, and keep a direct-open fallback. No parent-window messages or automatic resizing are used. Hosts should check their `frame-src` policy and serving headers rather than assume embedding is enabled on every deployment.

## Privacy and attribution

There is no form submission, account, analytics, tracking pixel, cookie, local storage, third-party script, network request, server or stored measurement history in this code. A restrictive Content Security Policy blocks connection requests. Normal hosting access logs, if a host enables them, remain that host's responsibility.

The visible source-guide footer and host-page reference are optional and may be removed without affecting calculations. They contain no query tracking parameters. A host controls whether a reference is included and what `rel` it uses; the example uses `nofollow`. Retain the copyright and MIT permission notice in distributed software copies. The source-code notice is a license obligation; a public backlink is not.

Source guidance: [Sewlore PDF pattern print guide](https://sewlore.com/pages/pdf-pattern-print-scale-checker).

## Verification

Thirteen automated checks covered arithmetic, input validation, compatibility with the existing square helper, core UI events and source/link/network constraints. Browser checks also verified Enter-key submission, separate 96% width and 104% height results, rejection of a zero measurement, and removal of stale results when the unit changes. These are digital checks, not physical printer measurements. Mobile and screen-reader use have not been verified.

## Limits

Use the pattern's real reference, measuring marks and stated tolerance. This arithmetic does not inspect clipping, paper dimensions, assembly marks, PDF contents or garment fit. The HTML layout is not a physical ruler. There are no physical printer measurements in this package and no search ranking, traffic or AI citation gain has been measured.
