namespace Keto;

public class Parser
{
    public Token Current { get; set; }
    public Token Previous { get; set; }
    public bool HadError { get; set; }
    public bool PanicMode { get; set; }
}