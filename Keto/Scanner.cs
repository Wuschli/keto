using System.Diagnostics.CodeAnalysis;

namespace Keto;

public class Scanner
{
    private readonly string _source;
    private int _startOffset;
    private int _currentOffset;
    private int _line = 1;

    private char Current
    {
        get
        {
            if (_currentOffset >= _source.Length)
                return '\0';
            return _source[_currentOffset];
        }
    }

    private char Next
    {
        get
        {
            if (IsAtEnd())
                return '\0';
            return _source[_currentOffset + 1];
        }
    }

    public Scanner(string source)
    {
        _source = source;
    }

    public Token ScanToken()
    {
        SkipWhitespace();
        _startOffset = _currentOffset;
        if (IsAtEnd())
            return MakeToken(TokenType.Eof);

        var character = Advance();
        if (IsDigit(character))
            return MakeNumber();
        if (IsAlpha(character))
            return MakeIdentifier();

        switch (character)
        {
            case '(': return MakeToken(TokenType.LeftParen);
            case ')': return MakeToken(TokenType.RightParen);
            case '{': return MakeToken(TokenType.LeftBrace);
            case '}': return MakeToken(TokenType.RightBrace);
            case ';': return MakeToken(TokenType.Semicolon);
            case ',': return MakeToken(TokenType.Comma);
            case '.': return MakeToken(TokenType.Dot);
            case '-': return MakeToken(TokenType.Minus);
            case '+': return MakeToken(TokenType.Plus);
            case '/': return MakeToken(TokenType.Slash);
            case '*': return MakeToken(TokenType.Star);
            case '!':
                return MakeToken(Match('=') ? TokenType.BangEqual : TokenType.Bang);
            case '=':
                return MakeToken(Match('=') ? TokenType.EqualEqual : TokenType.Equal);
            case '<':
                return MakeToken(Match('=') ? TokenType.LessEqual : TokenType.Less);
            case '>':
                return MakeToken(Match('=') ? TokenType.GreaterEqual : TokenType.Greater);
            case '"':
                return MakeString();
        }

        return ErrorToken("Unexpected character.");
    }

    private char Advance()
    {
        _currentOffset++;
        return _source[_currentOffset - 1];
    }

    private bool Match(char expected)
    {
        if (IsAtEnd())
            return false;
        if (Current != expected)
            return false;
        _currentOffset++;
        return true;
    }

    private bool IsAtEnd()
    {
        return Current == '\0';
    }

    private bool IsDigit(char c)
    {
        return c >= '0' && c <= '9';
    }

    private bool IsAlpha(char c)
    {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
    }

    private Token MakeToken(TokenType type)
    {
        var length = _currentOffset - _startOffset;
        return new Token
        {
            Type = type,
            StartOffset = _startOffset,
            Length = length,
            Line = _line,
            Value = _source.Substring(_startOffset, length)
        };
    }

    private Token ErrorToken(string message)
    {
        return new Token
        {
            Type = TokenType.Error,
            StartOffset = 0,
            Length = message.Length,
            Line = _line,
            Value = message
        };
    }

    private Token MakeString()
    {
        while (Current != '"' && !IsAtEnd())
        {
            if (Current == '\n')
                _line++;
            Advance();
        }

        if (IsAtEnd())
            return ErrorToken("Unterminated string.");
        Advance();
        return MakeToken(TokenType.String);
    }

    private Token MakeNumber()
    {
        while (IsDigit(Current))
            Advance();

        // Look for fractional part
        if (Current == '.' && IsDigit(Next))
        {
            Advance(); // consume the '.'
            while (IsDigit(Current))
                Advance();
        }

        return MakeToken(TokenType.Number);
    }

    private Token MakeIdentifier()
    {
        while (IsAlpha(Current) || IsDigit(Current))
            Advance();
        return MakeToken(IdentifierType());
    }

    [SuppressMessage("ReSharper", "StringLiteralTypo")]
    private TokenType IdentifierType()
    {
        switch (_source[_startOffset])
        {
            case 'a': return CheckKeyword(1, 2, "nd", TokenType.And);
            case 'c': return CheckKeyword(1, 4, "lass", TokenType.Class);
            case 'e': return CheckKeyword(1, 3, "lse", TokenType.Else);
            case 'i': return CheckKeyword(1, 1, "f", TokenType.If);
            case 'n': return CheckKeyword(1, 2, "il", TokenType.Nil);
            case 'o': return CheckKeyword(1, 1, "r", TokenType.Or);
            case 'p': return CheckKeyword(1, 4, "rint", TokenType.Print);
            case 'r': return CheckKeyword(1, 5, "eturn", TokenType.Return);
            case 's': return CheckKeyword(1, 4, "uper", TokenType.Super);
            case 'v': return CheckKeyword(1, 2, "ar", TokenType.Var);
            case 'w': return CheckKeyword(1, 4, "hile", TokenType.While);

            case 'f':
                if (_currentOffset - _startOffset > 1)
                    switch (_source[_startOffset + 1])
                    {
                        case 'a': return CheckKeyword(2, 3, "lse", TokenType.False);
                        case 'o': return CheckKeyword(2, 1, "r", TokenType.For);
                        case 'u': return CheckKeyword(2, 1, "n", TokenType.Fun);
                    }

                break;
            case 't':
                if (_currentOffset - _startOffset > 1)
                    switch (_source[_startOffset + 1])
                    {
                        case 'h': return CheckKeyword(2, 2, "is", TokenType.This);
                        case 'r': return CheckKeyword(2, 2, "ue", TokenType.True);
                    }

                break;
        }

        return TokenType.Identifier;
    }

    private TokenType CheckKeyword(int start, int length, string rest, TokenType type)
    {
        if (_currentOffset - _startOffset == start + length && _source.Substring(_startOffset + start, length) == rest)
            return type;
        return TokenType.Identifier;
    }

    private void SkipWhitespace()
    {
        while (true)
        {
            char c = Current;
            switch (c)
            {
                case ' ':
                case '\r':
                case '\t':
                    Advance();
                    break;
                case '\n':
                    _line++;
                    Advance();
                    break;
                case '/':
                    if (Next == '/')
                        while (Current != '\n' && !IsAtEnd())
                            Advance();
                    else
                        return;
                    break;
                default:
                    return;
            }
        }
    }
}