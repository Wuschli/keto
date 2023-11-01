namespace Keto;

public class VM
{
    private const int StackMax = 256;

    private Chunk _chunk = new Chunk();
    private Value[] _stack = new Value[StackMax];

    private int _ipOffset;
    private int _stackOffset;

    private Value StackTop
    {
        get => _stack[_stackOffset];
        set => _stack[_stackOffset] = value;
    }

    public InterpretResult Interpret(string source)
    {
        var chunk = new Chunk();
        if (!Compiler.Compile(source, chunk))
            return InterpretResult.CompileError;

        _chunk = chunk;
        _ipOffset = 0;
        var result = Run();
        return result;
    }

    private InterpretResult Run()
    {
        while (true)
        {
#if DEBUG_TRACE_EXECUTION
            Debug.Print("          ");
            for (var i = 0; i < _stackOffset; i++)
            {
                Debug.Print("[");
                Debug.PrintValue(_stack[i]);
                Debug.Print("]");
            }

            Debug.Print("\n");

            _chunk.DisassembleInstruction(_ipOffset);
#endif

            var instruction = ReadByte();
            InterpretResult? result = null;
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
                case (byte)OpCode.Nil:
                    Push(Value.Nil());
                    break;
                case (byte)OpCode.True:
                    Push(Value.Bool(true));
                    break;
                case (byte)OpCode.False:
                    Push(Value.Bool(false));
                    break;

                case (byte)OpCode.Equal:
                    var b = Pop();
                    var a = Pop();
                    Push(a.Equals(b).ToValue());
                    break;

                case (byte)OpCode.Greater:
                    result = BinaryOp((a, b) => a > b);
                    if (result != null)
                        return result.Value;
                    break;

                case (byte)OpCode.Less:
                    result = BinaryOp((a, b) => a < b);
                    if (result != null)
                        return result.Value;
                    break;
                case (byte)OpCode.Add:
                    result = BinaryOp((a, b) => a + b);
                    if (result != null)
                        return result.Value;
                    break;
                case (byte)OpCode.Subtract:
                    result = BinaryOp((a, b) => a - b);
                    if (result != null)
                        return result.Value;
                    break;
                case (byte)OpCode.Multiply:
                    result = BinaryOp((a, b) => a * b);
                    if (result != null)
                        return result.Value;
                    break;
                case (byte)OpCode.Divide:
                    result = BinaryOp((a, b) => a / b);
                    if (result != null)
                        return result.Value;
                    break;

                case (byte)OpCode.Not:
                    Push(IsFalsey(Pop()).ToValue());
                    break;
                case (byte)OpCode.Negate:
                    if (!Peek(0).IsNumber())
                    {
                        RuntimeError("Operand must be a number.");
                        return InterpretResult.RuntimeError;
                    }

                    Push((-Pop().ToNumber()).ToValue());
                    break;
            }
        }
    }

    private InterpretResult? BinaryOp(BinaryDelegate func)
    {
        if (!Peek(0).IsNumber() || !Peek(1).IsNumber())
        {
            RuntimeError("Operands must be numbers.");
            return InterpretResult.RuntimeError;
        }

        var b = Pop().ToNumber();
        var a = Pop().ToNumber();
        Push(func(a, b).ToValue());
        return null;
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

    private Value Peek(int distance)
    {
        return _stack[_stackOffset - 1 - distance];
    }

    private bool IsFalsey(Value value)
    {
        return value.IsNil() || (value.IsBool() && !value.ToBool()) || (value.IsNumber() && value.ToNumber() == 0);
    }

    private byte ReadByte()
    {
        return _chunk.Code[_ipOffset++];
    }

    private Value ReadConstant()
    {
        return _chunk.Constants[ReadByte()];
    }

    private void ResetStack()
    {
        _stackOffset = 0;
    }

    private void RuntimeError(string format, params object[] args)
    {
        Debug.PrintError(string.Format(format, args));
        var instruction = _ipOffset - 1;
        var line = _chunk.Lines[instruction];
        Debug.PrintError($"[line {line}] in script\n");
        ResetStack();
    }
}