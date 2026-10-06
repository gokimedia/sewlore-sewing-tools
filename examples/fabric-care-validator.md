# Fabric-care CSV validation notebook

[Open in Colab](https://colab.research.google.com/github/gokimedia/sewlore-sewing-tools/blob/main/examples/fabric-care-validator.ipynb) · [View or download the notebook](fabric-care-validator.ipynb)

Learn to check paired fabric-care readings before calculating a change. This self-contained Python notebook begins with a CSV header and **no measurement records**. Its optional assertions use hypothetical numbers; they are software checks, not observations from washed or sewn fabric.

## Use the lesson

1. Open the notebook in Colab, or download it for a compatible Jupyter environment. Running in Colab uses Google's runtime and may require a Google account.
2. Run the definitions cell. Keep the supplied CSV header, and replace the header-only `RAW_CSV` string with your own records when you are ready.
3. Run validation and review accepted records and diagnostics separately. Correct rejected records in the input and rerun before interpreting the calculations.
4. The export cell creates two CSV strings. File saving starts off. Set `SAVE_EXPORT_FILES = True` only if you want the accepted-record and error CSV files in your current runtime; download them before that runtime ends.

## Record comparable readings

Each row needs a sample identifier, care-method context, matching before/after units (`cm`, `mm` or `in`) and four positive, finite readings: length and width before and after. Different rows may use different units. Keep unit labels in their own columns and use ordinary CSV quoting for notes containing commas or line breaks.

The signed axis formula is `(before − after) / before × 100`: positive means contraction and negative means expansion. An area result is available only when `rectangle_assumption` is `yes` and the paired dimensions describe rectangles. The notebook retains the sign and does not add the two axis percentages. It reports malformed records and unusable numeric combinations instead of silently repairing them.

For one pair of readings, the [browser fabric-shrinkage calculator](https://sewlore-fabric-shrinkage.web.app/) offers a form. The notebook's guide explains the record-keeping context and links to the related preparation methods.

## Keep your data private

The code uses Python's standard library. It adds no network requests, Drive mounting, account access, dependency installation or analytics. Colab still processes entered text on Google's service. Keep personal information out of sample notes, and review saved input, outputs and comments before sharing a notebook. Clear outputs and restore the blank input for a public copy.

These calculations do not prescribe a care treatment, certify a textile test or establish garment fit. Record the method you actually used and follow the material's appropriate care guidance.

## Source and licence

This copy preserves the native saved-notebook export from Colab on 6 October 2026. Its 14 ordered cell sources match the original preparation; all six code cells have empty outputs and unset execution counts. Colab's cell-identifier metadata is retained. No lesson text or code was changed for this companion. The original lesson and software were prepared with AI assistance from OpenAI Codex; this is an educational software resource, with no peer-review or physical fabric-test results claimed.

Code and lesson: © 2026 Sewlore, [MIT licence](../LICENSE), also included in the notebook. The licence grants no trademark ownership or endorsement. See [Colab's FAQ](https://research.google.com/colaboratory/faq.html) for current runtime, download and sharing behaviour.
