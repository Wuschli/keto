namespace Keto;

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
            { TokenType.Bang, new ParseRule { Prefix = Unary, Infix = null, Precedence = Precedence.None } },
            { TokenType.BangEqual, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Equality } },
            { TokenType.Equal, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.EqualEqual, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Equality } },
            { TokenType.Greater, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Comparison } },
            { TokenType.GreaterEqual, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Comparison } },
            { TokenType.Less, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Comparison } },
            { TokenType.LessEqual, new ParseRule { Prefix = null, Infix = Binary, Precedence = Precedence.Comparison } },
            { TokenType.Identifier, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.String, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Number, new ParseRule { Prefix = Number, Infix = null, Precedence = Precedence.None } },
            { TokenType.And, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Class, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Else, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.False, new ParseRule { Prefix = Literal, Infix = null, Precedence = Precedence.None } },
            { TokenType.For, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Fun, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.If, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Nil, new ParseRule { Prefix = Literal, Infix = null, Precedence = Precedence.None } },
            { TokenType.Or, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Print, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Return, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.Super, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.This, new ParseRule { Prefix = null, Infix = null, Precedence = Precedence.None } },
            { TokenType.True, new ParseRule { Prefix = Literal, Infix = null, Precedence = Precedence.None } },
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

    private void EmitBytes(OpCode opCode1, OpCode opCode2, params byte[] values)
    {
        EmitByte(opCode1);
        EmitByte(opCode2);
        foreach (var value in values)
        {
            EmitByte(value);
        }
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
        Debug.PrintError($"[line {token.Line,4}] Error");
        if (token.Type == TokenType.Eof)
        {
            Debug.PrintError(" at end");
        }
        else if (token.Type == TokenType.Error)
        {
            // Nothing.
        }
        else
        {
            Debug.PrintError($" at '{token.Value}'");
        }

        Debug.PrintError($": {message}\n");
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
        double value = double.Parse(_parser.Previous.Value);
        EmitConstant(value.ToValue());
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
            case TokenType.Bang:
                EmitByte(OpCode.Not);
                break;
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
            case TokenType.BangEqual:
                EmitBytes(OpCode.Equal, OpCode.Not);
                break;
            case TokenType.EqualEqual:
                EmitByte(OpCode.Equal);
                break;
            case TokenType.Greater:
                EmitBytes(OpCode.Greater);
                break;
            case TokenType.GreaterEqual:
                EmitBytes(OpCode.Less, OpCode.Not);
                break;
            case TokenType.Less:
                EmitByte(OpCode.Less);
                break;
            case TokenType.LessEqual:
                EmitBytes(OpCode.Greater, OpCode.Not);
                break;

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

    private void Literal()
    {
        switch (_parser.Previous.Type)
        {
            case TokenType.False:
                EmitByte(OpCode.False);
                break;
            case TokenType.Nil:
                EmitByte(OpCode.Nil);
                break;
            case TokenType.True:
                EmitByte(OpCode.True);
                break;
            default: return; //unreachable
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