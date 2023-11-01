namespace Keto;

public static class ValueExtensions
{
    public static Value ToValue(this double value) => Value.Number(value);
    public static Value ToValue(this bool value) => Value.Bool(value);

    public static Value ToValue(this object? value)
    {
        if (value == null)
            return Value.Nil();
        switch (value)
        {
            case bool b:
                return b.ToValue();
            case double d:
                return d.ToValue();
        }

        return Value.Nil(); // should not be reachable
    }
}