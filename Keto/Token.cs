namespace Keto;

public struct Token
{
    public TokenType Type;
    public int StartOffset;
    public int Length;
    public int Line;
    public string Value;
}