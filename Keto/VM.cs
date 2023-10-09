namespace Keto;

using Value = Double;

public delegate Value BinaryDelegate(Value a, Value b);

public delegate void ParseDelegate();

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
}

public class Compiler
{
    private readonly Chunk _chunk;
    private Scanner _scanner;
    private Parser _parser;

    private readonly Dictionary<TokenType, ParseRule> _rules;

    public Compiler(string source, Chunk chunk)
    {
        _chunk = chunk;
        _scanner = new Scanner(source);
        _rules = new Dictionary<TokenType, ParseRule>
        {
            { TokenType.LeftParen, new ParseRule { Prefix = Grouping, Infix = null, Precedence = Precedence.None } },
            { TokenType.RightParen, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.LeftBrace, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.RightBrace, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Comma, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Dot, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Minus, new ParseRule { Prefix = Unary, Infix = Binary, Precedence = Precedence.Term } },
            { TokenType.Plus, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Term } },
            { TokenType.Semicolon, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Slash, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Factor } },
            { TokenType.Star, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Factor } },
            { TokenType.Bang, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.BangEqual, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Equal, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.EqualEqual, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Greater, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.GreaterEqual, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Less, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.LessEqual, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Identifier, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.String, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Number, new ParseRule { Prefix = Number, Infix = null, Precedence = Precedence.None } },
            { TokenType.And, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Class, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Else, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.False, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.For, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Fun, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.If, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Nil, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Or, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Print, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Return, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Super, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.This, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.True, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Var, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.While, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Error, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Eof, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
        };
        _parser = new Parser();
    }

    public static bool Compile(string source, Chunk chunk)
    {
        var compiler = new Compiler(source, chunk);
        return compiler.Compile();
    }


    public bool Compile()
    {
        Advance();
        Expression();
        Consume(TokenType.Eof, "Expect end of expression.");
        EndCompiler();
        return !_parser.HadError;
        //int line = -1;

        //while (true)
        //{
        //    Token token = scanner.ScanToken();
        //    if (token.Line != line)
        //    {
        //        Debug.Print($"{token.Line,4} ");
        //        line = token.Line;
        //    }
        //    else
        //    {
        //        Debug.Print("   | ");
        //    }

        //    Debug.Print($"{token.Type,8} '{token.Value}'");

        //    if (token.Type == TokenType.Eof)
        //        break;
        //}
    }

    private void Advance()
    {
        _parser.Previous = _parser.Current;

        while (true)
        {
            _parser.Current = _scanner.ScanToken();
            if (_parser.Current.Type != TokenType.Error)
                break;
            ErrorAtCurrent(_parser.Current.Value);
        }
    }

    private void Consume(TokenType type, string message)
    {
        if (_parser.Current.Type == type)
        {
            Advance();
            return;
        }

        ErrorAtCurrent(message);
    }

    private void EmitByte(byte value)
    {
        _chunk.Write(value, _parser.Previous.Line);
    }

    private void EmitByte(OpCode value)
    {
        EmitByte((byte)value);
    }

    private void EmitBytes(OpCode opCode, params byte[] values)
    {
        EmitByte(opCode);
        foreach (var value in values)
        {
            EmitByte(value);
        }
    }

    private void EndCompiler()
    {
        EmitReturn();
#if DEBUG_PRINT_CODE
        if (!_parser.HadError)
        {
            _chunk.Disassemble("code");
        }
#endif
    }

    private void EmitReturn()
    {
        EmitByte(OpCode.Return);
    }

    private void EmitConstant(Value value)
    {
        EmitBytes(OpCode.Constant, MakeConstant(value));
    }

    private byte MakeConstant(Value value)
    {
        int constant = _chunk.AddConstant(value);
        if (constant > byte.MaxValue)
        {
            Error("Too many constants in one chunk.");
            return 0;
        }

        return (byte)constant;
    }

    private void ErrorAt(Token token, string message)
    {
        if (_parser.PanicMode)
            return;
        _parser.PanicMode = true;
        Console.Error.Write($"[line {token.Line,4}] Error");
        if (token.Type == TokenType.Eof)
        {
            Console.Error.Write(" at end");
        }
        else if (token.Type == TokenType.Error)
        {
            // Nothing.
        }
        else
        {
            Console.Error.Write($" at '{token.Value}'");
        }

        Console.Error.Write($": {message}\n");
        _parser.HadError = true;
    }

    private void ErrorAtCurrent(string message)
    {
        ErrorAt(_parser.Current, message);
    }

    private void Error(string message)
    {
        ErrorAt(_parser.Previous, message);
    }

    private void Expression()
    {
        ParsePrecedence(Precedence.Assignment);
    }

    private void Number()
    {
        Value value = Value.Parse(_parser.Previous.Value);
        EmitConstant(value);
    }

    private void Grouping()
    {
        Expression();
        Consume(TokenType.RightParen, "Expect ')' after expression.");
    }

    private void Unary()
    {
        var operatorType = _parser.Previous.Type;

        // Compile the operand.
        ParsePrecedence(Precedence.Unary);

        // Emit the operator instruction.
        switch (operatorType)
        {
            case TokenType.Minus:
                EmitByte(OpCode.Negate);
                break;
        }
    }

    private void Binary()
    {
        var operatorType = _parser.Previous.Type;
        var rule = GetRule(operatorType);
        ParsePrecedence(rule.Precedence + 1);

        switch (operatorType)
        {
            case TokenType.Plus:
                EmitByte(OpCode.Add);
                break;
            case TokenType.Minus:
                EmitByte(OpCode.Subtract);
                break;
            case TokenType.Star:
                EmitByte(OpCode.Multiply);
                break;
            case TokenType.Slash:
                EmitByte(OpCode.Divide);
                break;
        }
    }

    private void ParsePrecedence(Precedence precedence)
    {
        Advance();
        var prefixRule = GetRule(_parser.Previous.Type).Prefix;
        if (prefixRule == null)
        {
            Error("Expect expression.");
            return;
        }

        prefixRule();

        while (precedence <= GetRule(_parser.Current.Type).Precedence)
        {
            Advance();
            var infixRule = GetRule(_parser.Previous.Type).Infix;
            infixRule?.Invoke();
        }
    }

    private ParseRule GetRule(TokenType type)
    {
        return _rules[type];
    }
}

public class Parser
{
    public Token Current { get; set; }
    public Token Previous { get; set; }
    public bool HadError { get; set; }
    public bool PanicMode { get; set; }
}

public struct Token
{
    public TokenType Type;
    public int StartOffset;
    public int Length;
    public int Line;
    public string Value;
}

public struct ParseRule
{
    public ParseDelegate? Prefix;
    public ParseDelegate? Infix;
    public Precedence Precedence;
}