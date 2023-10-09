namespace Keto;

using Value = Double;

public class Chunk
{
    private readonly List<byte> _code = new();
    private readonly List<Value> _constants = new();
    private readonly List<int> _lines = new();

    public int Count => _code.Count;
    public IReadOnlyList<byte> Code => _code;
    public IReadOnlyList<Value> Constants => _constants;
    public IReadOnlyList<int> Lines => _lines;

    public void Write(byte value, int line)
    {
        _code.Add(value);
        _lines.Add(line);
    }

    public int AddConstant(Value value)
    {
        _constants.Add(value);
        return _constants.Count - 1;
    }
}