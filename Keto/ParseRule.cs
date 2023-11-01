namespace Keto;

public struct ParseRule
{
    public ParseDelegate? Prefix;
    public ParseDelegate? Infix;
    public Precedence Precedence;
}