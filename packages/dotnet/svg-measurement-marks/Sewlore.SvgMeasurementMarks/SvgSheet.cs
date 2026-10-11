using System;
using System.Collections.Generic;
using System.Globalization;
using System.Xml;
using System.Xml.Linq;

namespace Sewlore.SvgMeasurementMarks
{
    public enum RulerOrientation { Horizontal, Vertical }

    /// <summary>
    /// Generates a self-contained SVG whose viewBox coordinates are millimetres.
    /// Text is XML-encoded; the generator never emits script, external URLs, or images.
    /// Print scaling and actual hardware accuracy must be checked by the user.
    /// </summary>
    public sealed class SvgSheet
    {
        private static readonly XNamespace Svg = "http://www.w3.org/2000/svg";
        private readonly List<XElement> marks = new List<XElement>();
        private readonly string title;
        private readonly string description;
        private const decimal Stroke = 0.2m;

        public SvgSheet(Length width, Length height, string title = "Measurement reference sheet", string description = "Print at actual size. Check calibration dimensions with a physical ruler before use.")
        {
            WidthMillimetres = Dimension(width, nameof(width));
            HeightMillimetres = Dimension(height, nameof(height));
            this.title = Text(title, nameof(title), 160);
            this.description = Text(description, nameof(description), 1024);
        }

        public decimal WidthMillimetres { get; }
        public decimal HeightMillimetres { get; }

        /// <summary>Adds a square with the stated centreline-to-centreline side length.</summary>
        public SvgSheet AddCalibrationSquare(decimal xMillimetres, decimal yMillimetres, Length side, string? label = null)
        {
            Positive(side, nameof(side));
            var text = Text(label ?? "Calibration " + side, nameof(label), 128);
            Bounds(xMillimetres - Stroke / 2, yMillimetres - Stroke / 2,
                   side.Millimetres + Stroke, side.Millimetres + Stroke);
            var group = new XElement(Svg + "g", new XAttribute("data-mark", "calibration-square"),
                new XElement(Svg + "rect", A("x", xMillimetres), A("y", yMillimetres),
                    A("width", side.Millimetres), A("height", side.Millimetres),
                    new XAttribute("fill", "none"), new XAttribute("stroke", "#111827"), A("stroke-width", Stroke)),
                TextElement(xMillimetres + side.Millimetres / 2, yMillimetres + side.Millimetres / 2, text, "middle"));
            marks.Add(group);
            return this;
        }

        /// <summary>
        /// Adds ticks at exact interval multiples and at the endpoint, including a partial
        /// final interval. Tick labels show original units. At most 10,001 interval ticks.
        /// </summary>
        public SvgSheet AddRuler(decimal xMillimetres, decimal yMillimetres, Length length, Length interval, int majorEvery = 5, RulerOrientation orientation = RulerOrientation.Horizontal)
        {
            Positive(length, nameof(length));
            Positive(interval, nameof(interval));
            if (majorEvery < 1 || majorEvery > 1000) throw new ArgumentOutOfRangeException(nameof(majorEvery));
            if (orientation != RulerOrientation.Horizontal && orientation != RulerOrientation.Vertical) throw new ArgumentOutOfRangeException(nameof(orientation));
            if (interval.Millimetres > length.Millimetres) throw new ArgumentOutOfRangeException(nameof(interval), "Interval must not exceed ruler length.");
            if (length.Millimetres > (orientation == RulerOrientation.Horizontal ? WidthMillimetres : HeightMillimetres)) throw new ArgumentOutOfRangeException(nameof(length), "Ruler exceeds sheet dimensions.");
            if (interval.Millimetres < length.Millimetres / 10000m) throw new ArgumentOutOfRangeException(nameof(interval), "Ruler exceeds the 10,000 interval limit.");
            var countDecimal = decimal.Floor(length.Millimetres / interval.Millimetres);
            if (countDecimal > 10000) throw new ArgumentOutOfRangeException(nameof(interval), "Ruler exceeds the 10,000 interval limit.");
            var count = (int)countDecimal;
            bool horizontal = orientation == RulerOrientation.Horizontal;
            Bounds(xMillimetres - Stroke / 2, yMillimetres - (horizontal ? 5.1m : 2m),
                horizontal ? length.Millimetres + Stroke : 15.1m,
                horizontal ? 11.2m : length.Millimetres + 4m);
            var group = new XElement(Svg + "g", new XAttribute("data-mark", "ruler"),
                new XAttribute("data-input-unit", length.UnitSymbol),
                Line(xMillimetres, yMillimetres, xMillimetres + (horizontal ? length.Millimetres : 0), yMillimetres + (horizontal ? 0 : length.Millimetres)));
            for (int i = 0; i <= count; i++)
            {
                decimal at = i * interval.Millimetres;
                AddTick(group, xMillimetres, yMillimetres, at, i % majorEvery == 0 || at == length.Millimetres, horizontal, length);
            }
            if (count * interval.Millimetres != length.Millimetres)
                AddTick(group, xMillimetres, yMillimetres, length.Millimetres, true, horizontal, length);
            marks.Add(group);
            return this;
        }

        /// <summary>Adds an exact horizontal measurement line, endpoint caps and an encoded label.</summary>
        public SvgSheet AddMeasurementLabel(decimal xMillimetres, decimal yMillimetres, Length length, string label)
        {
            Positive(length, nameof(length));
            var text = Text(label, nameof(label), 96) + " - " + length;
            Bounds(xMillimetres - Stroke / 2, yMillimetres - 4m, length.Millimetres + Stroke, 5.6m);
            marks.Add(new XElement(Svg + "g", new XAttribute("data-mark", "measurement-label"),
                Line(xMillimetres, yMillimetres, xMillimetres + length.Millimetres, yMillimetres),
                Line(xMillimetres, yMillimetres - 1.5m, xMillimetres, yMillimetres + 1.5m),
                Line(xMillimetres + length.Millimetres, yMillimetres - 1.5m, xMillimetres + length.Millimetres, yMillimetres + 1.5m),
                TextElement(xMillimetres + length.Millimetres / 2, yMillimetres - 2m, text, "middle")));
            return this;
        }

        public string ToSvg()
        {
            return new XElement(Svg + "svg", new XAttribute("width", Number(WidthMillimetres) + "mm"),
                new XAttribute("height", Number(HeightMillimetres) + "mm"),
                new XAttribute("viewBox", "0 0 " + Number(WidthMillimetres) + " " + Number(HeightMillimetres)),
                new XAttribute("preserveAspectRatio", "xMinYMin meet"), new XAttribute("role", "img"),
                new XElement(Svg + "title", title), new XElement(Svg + "desc", description), marks).ToString(SaveOptions.DisableFormatting);
        }

        private static void AddTick(XElement group, decimal x, decimal y, decimal at, bool major, bool horizontal, Length length)
        {
            decimal tick = major ? 5m : 3m;
            var line = horizontal ? Line(x + at, y, x + at, y - tick) : Line(x, y + at, x + tick, y + at);
            line.Add(new XAttribute("data-position-mm", Number(at)));
            group.Add(line);
            if (major)
            {
                var factor = length.Unit == MeasurementUnit.Inch ? 25.4m : length.Unit == MeasurementUnit.Centimetre ? 10m : 1m;
                string label = (at / factor).ToString("0.######", CultureInfo.InvariantCulture);
                group.Add(horizontal ? TextElement(x + at, y + 4m, label, at == 0 ? "start" : at == length.Millimetres ? "end" : "middle")
                                     : TextElement(x + 6m, y + at + 0.8m, label, "start"));
            }
        }

        private void Bounds(decimal x, decimal y, decimal width, decimal height)
        {
            if (x < 0 || y < 0 || width <= 0 || height <= 0 || x > WidthMillimetres - width || y > HeightMillimetres - height)
                throw new ArgumentOutOfRangeException(nameof(x), "Mark geometry must fit inside the sheet with its stroke and standard label area.");
        }
        private static decimal Dimension(Length length, string name)
        {
            if (length.Millimetres < 1 || length.Millimetres > 10000) throw new ArgumentOutOfRangeException(name, "Sheet dimension must be between 1 and 10,000 mm.");
            return length.Millimetres;
        }
        private static void Positive(Length length, string name)
        {
            if (length.Millimetres <= 0) throw new ArgumentOutOfRangeException(name, "Mark length must be positive.");
        }
        private static string Text(string? value, string name, int max)
        {
            if (value == null) throw new ArgumentNullException(name);
            if (value.Length > max) throw new ArgumentOutOfRangeException(name, "Text is too long.");
            XmlConvert.VerifyXmlChars(value);
            return value;
        }
        private static XElement TextElement(decimal x, decimal y, string text, string anchor) => new XElement(Svg + "text", A("x", x), A("y", y), new XAttribute("text-anchor", anchor), A("font-size", 2.5m), new XAttribute("font-family", "sans-serif"), new XAttribute("fill", "#111827"), text);
        private static XElement Line(decimal x1, decimal y1, decimal x2, decimal y2) => new XElement(Svg + "line", A("x1", x1), A("y1", y1), A("x2", x2), A("y2", y2), new XAttribute("stroke", "#111827"), A("stroke-width", Stroke));
        private static XAttribute A(string name, decimal value) => new XAttribute(name, Number(value));
        private static string Number(decimal value) => value.ToString("0.############################", CultureInfo.InvariantCulture);
    }
}
