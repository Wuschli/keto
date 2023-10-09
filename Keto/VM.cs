namespace Keto;

using Value = Double;

public delegate Value BinaryDelegate(Value a, Value b);

public class VM : IDisposable
{
    private const int StackMax = 256;

    private Chunk _chunk = null!;
    private Value[] _stack = new Value[StackMax];

    private int _ipOffset;
    private int _stackOffset;

    private Value StackTop
    {
        get => _stack[_stackOffset];
        set => _stack[_stackOffset] = value;
    }

    public InterpretResult Interpret(Chunk chunk)
    {
        _chunk = chunk;
        _ipOffset = 0;
        return Run();
    }

    private InterpretResult Run()
    {
        while (true)
        {
#if DEBUG_TRACE_EXECUTION
            Debug.Print("          ");
            for (var i = 0; i < _stackOffset; i++)
                Debug.Print($"[ {_stack[i]} ]");

            Debug.Print("\n");

            _chunk.DisassembleInstruction(_ipOffset);
#endif

            var instruction = ReadByte();
            switch (instruction)
            {
                case (byte)OpCode.Return:
                    Debug.PrintValue(Pop());
                    Debug.Print("\n");
                    return InterpretResult.Ok;
                case (byte)OpCode.Constant:
                    var constant = ReadConstant();
                    Push(constant);
                    break;
                case (byte)OpCode.Add:
                    BinaryOp((a, b) => a + b);
                    break;
                case (byte)OpCode.Subtract:
                    BinaryOp((a, b) => a - b);
                    break;
                case (byte)OpCode.Multiply:
                    BinaryOp((a, b) => a * b);
                    break;

                case (byte)OpCode.Divide:
                    BinaryOp((a, b) => a / b);
                    break;
                case (byte)OpCode.Negate:
                    Push(-Pop());
                    break;
            }
        }
    }

    private void BinaryOp(BinaryDelegate func)
    {
        var a = Pop();
        var b = Pop();
        Push(func(a, b));
    }

    private void Push(Value value)
    {
        StackTop = value;
        _stackOffset++;
    }

    private Value Pop()
    {
        _stackOffset--;
        return StackTop;
    }

    private byte ReadByte()
    {
        return _chunk.Code[_ipOffset++];
    }

    private Value ReadConstant()
    {
        return _chunk.Constants[ReadByte()];
    }

    public void Dispose()
    {
        // TODO release managed resources here
    }
}