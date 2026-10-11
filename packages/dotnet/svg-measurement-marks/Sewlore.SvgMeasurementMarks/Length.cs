using System;
using System.Globalization;

namespace Sewlore.SvgMeasurementMarks
{
    /// <summary>Accepted physical input units. SVG geometry is normalized to millimetres.</summary>
    public enum MeasurementUnit { Millimetre, Centimetre, Inch }

    /// <summary>A nonnegative physical length preserving its original input value and unit.</summary>
    public readonly struct Length : IEquatable<Length>
    {
        /// <summary>Creates a length; invalid units, negatives and overflow are rejected.</summary>
        public Length(decimal value, MeasurementUnit unit)
        {
            if (value < 0) throw new ArgumentOutOfRangeException(nameof(value), "Length must be nonnegative.");
            decimal factor;
            switch (unit)
            {
                case MeasurementUnit.Millimetre: factor = 1m; break;
                case MeasurementUnit.Centimetre: factor = 10m; break;
                case MeasurementUnit.Inch: factor = 25.4m; break;
                default: throw new ArgumentOutOfRangeException(nameof(unit));
            }
            try { Millimetres = checked(value * factor); }
            catch (OverflowException) { throw new ArgumentOutOfRangeException(nameof(value), "Converted length is too large."); }
            Value = value;
            Unit = unit;
        }

        public decimal Value { get; }
        public MeasurementUnit Unit { get; }
        public decimal Millimetres { get; }
        public string UnitSymbol => Unit == MeasurementUnit.Inch ? "in" : Unit == MeasurementUnit.Centimetre ? "cm" : "mm";
        public bool Equals(Length other) => Millimetres == other.Millimetres;
        public override bool Equals(object? obj) => obj is Length other && Equals(other);
        public override int GetHashCode() => Millimetres.GetHashCode();
        public override string ToString() => Value.ToString("0.############################", CultureInfo.InvariantCulture) + " " + UnitSymbol;
        public static bool operator ==(Length left, Length right) => left.Equals(right);
        public static bool operator !=(Length left, Length right) => !left.Equals(right);
    }
}
