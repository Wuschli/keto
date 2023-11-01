using System.Runtime.InteropServices;

// ReSharper disable CompareOfFloatsByEqualityOperator

namespace Keto;

[StructLayout(LayoutKind.Explicit)]
public struct Value
{
    [FieldOffset(0)]
    public ValueType Type;

    [FieldOffset(4)]
    private bool _boolean;

    [FieldOffset(4)]
    private double _number;

    public static Value Bool(bool value) => new() { Type = ValueType.Bool, _boolean = value };
    public static Value Nil() => new() { Type = ValueType.Nil, _number = 0 };
    public static Value Number(double value) => new() { Type = ValueType.Number, _number = value };

    public bool ToBool() => _boolean;
    public double ToNumber() => _number;

    public bool IsBool() => Type == ValueType.Bool;
    public bool IsNil() => Type == ValueType.Nil;
    public bool IsNumber() => Type == ValueType.Number;

    public override bool Equals(object? obj)
    {
        if (obj is not Value b)
            return false;

        if (Type != b.Type)
            return false;

        switch (Type)
        {
            case ValueType.Bool:
                return ToBool() == b.ToBool();
            case ValueType.Nil:
                return true;
            case ValueType.Number:
                return ToNumber() == b.ToNumber();
        }

        return false;
    }
}