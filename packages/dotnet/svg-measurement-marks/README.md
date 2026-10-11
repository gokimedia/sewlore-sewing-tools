# Sewlore.SvgMeasurementMarks

A small .NET Standard 2.0 library for physically dimensioned SVG calibration squares, rulers and measurement labels. Input units are mm, cm and inches; all drawing coordinates are normalized to millimetres using exact decimal arithmetic.

By [Sewlore](https://sewlore.com/). For consistent baselines, measuring-point labels and recording methods, read the [fabric measurement methods guide](https://sewlore.com/pages/fabric-measurement-methods-guide).

## Use

The prepared local package is version 0.1.0. This README does not assert that a registry release already exists. Install the built `.nupkg` from your local package folder, or reference the source project:

```sh
dotnet add package Sewlore.SvgMeasurementMarks --version 0.1.0 --source ./artifacts
```

```csharp
using Sewlore.SvgMeasurementMarks;

var sheet = new SvgSheet(
    new Length(210, MeasurementUnit.Millimetre),
    new Length(297, MeasurementUnit.Millimetre));
sheet.AddCalibrationSquare(15, 15, new Length(5, MeasurementUnit.Centimetre));
sheet.AddRuler(15, 90, new Length(6, MeasurementUnit.Inch),
    new Length(0.25m, MeasurementUnit.Inch), majorEvery: 4);
sheet.AddMeasurementLabel(15, 130, new Length(10, MeasurementUnit.Centimetre),
    "Before-wash baseline");
File.WriteAllText("reference.svg", sheet.ToSvg());
```

`AddRuler` supports horizontal and vertical orientation. Intervals can use a different unit than the ruler length. The final endpoint is included even when the last interval is partial. Tick labels use the ruler's input unit; labels with recurring decimals display up to six decimal places while geometry retains decimal precision.

## Print and layout limits

- The root SVG has physical `width`/`height` in mm and a matching millimetre `viewBox`. Dimensions describe the geometric centreline of the 0.2 mm stroke.
- Print at **actual size / 100%**, disable fit-to-page scaling, and measure the calibration square with a physical ruler. The library cannot validate a printer, browser zoom, paper, cutting accuracy or hardware.
- Sheet dimensions are limited to 1-10,000 mm. Marks must fit with their stroke and standard label area; a ruler is limited to 10,000 intervals. Long text can visually exceed a mark: font metrics and text wrapping are not computed.
- XML text is encoded. Invalid XML characters, unsupported units, negative lengths, zero mark lengths, conversion overflow and out-of-bounds geometry are rejected. Generated output contains no script, hyperlinks, external images or network requests.
- Measurement marks are reference graphics; they do not constitute a complete fitted pattern or a validated fabric-testing protocol.

## Build and test

Library consumers need a .NET Standard 2.0 compatible runtime. The included tests and example generator require a .NET 10 SDK.

```sh
dotnet test tests/Sewlore.SvgMeasurementMarks.Tests.csproj -c Release
dotnet pack Sewlore.SvgMeasurementMarks/Sewlore.SvgMeasurementMarks.csproj -c Release -o artifacts
dotnet run --project examples/GenerateSheets/GenerateSheets.csproj -c Release -- examples/generated
```

Tests cover exact physical-unit conversion, SVG viewport geometry, partial and mixed-unit ruler intervals, vertical orientation, measurement spans, Turkish decimal formatting, XML injection, invalid inputs and failure atomicity. SVG physical dimensions follow the [W3C SVG coordinate specification](https://www.w3.org/TR/SVG2/coords.html).

MIT licensed. Developed with AI assistance; source and tests are included for inspection. No telemetry and no runtime third-party package dependencies.
