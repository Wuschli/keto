namespace Keto;

public static class Debug
{
    public static void Disassemble(this Chunk chunk, string name)
    {
        Print($"== {name} ==\n");
        for (int offset = 0; offset < chunk.Count;)
        {
            offset = chunk.DisassembleInstruction(offset);
        }
    }

    public static int DisassembleInstruction(this Chunk chunk, int offset)
    {
        Print($"{offset:D4} ");

        if (offset > 0 && chunk.Lines[offset] == chunk.Lines[offset - 1])
        {
            Print("   | ");
        }
        else
        {
            Print($"{chunk.Lines[offset],4} ");
        }

        byte instruction = chunk.Code[offset];

        switch (instruction)
        {
            case (byte)OpCode.Constant:
                return ConstantInstruction(((OpCode)instruction).ToString().ToUpper(), chunk, offset);
            case (byte)OpCode.Return:
                return SimpleInstruction(((OpCode)instruction).ToString().ToUpper(), offset);
            case (byte)OpCode.Negate:
                return SimpleInstruction(((OpCode)instruction).ToString().ToUpper(), offset);
            case (byte)OpCode.Add:
                return SimpleInstruction(((OpCode)instruction).ToString().ToUpper(), offset);
            case (byte)OpCode.Subtract:
                return SimpleInstruction(((OpCode)instruction).ToString().ToUpper(), offset);
            case (byte)OpCode.Multiply:
                return SimpleInstruction(((OpCode)instruction).ToString().ToUpper(), offset);
            case (byte)OpCode.Divide:
                return SimpleInstruction(((OpCode)instruction).ToString().ToUpper(), offset);
            default:
                Print($"Unknown opcode {instruction:D}\n");
                return offset + 1;
        }
    }

    private static int ConstantInstruction(string name, Chunk chunk, int offset)
    {
        var constant = chunk.Code[offset + 1];
        Print($"{name,-16} {offset:D4} '");
        PrintValue(chunk.Constants[constant]);
        Print("'\n");
        return offset + 2;
    }

    private static int SimpleInstruction(string name, int offset)
    {
        Print($"{name}\n");
        return offset + 1;
    }

    public static void PrintValue(double value)
    {
        Print($"{value:G}");
    }

    public static void Print(string value)
    {
        Console.Write(value);
    }
}