using Keto;

internal class Program
{
    public static void Main(string[] args)
    {
        var vm = new VM();

        if (args.Length == 0)
            Repl(vm);
        else if (args.Length == 1)
            RunFile(vm, args[0]);
        else
        {
            Console.Error.WriteLine("Usage: keto [path]");
            Environment.Exit(64);
        }
    }

    private static void RunFile(VM vm, string path)
    {
        var source = File.ReadAllText(path);
        var result = vm.Interpret(source);

        if (result == InterpretResult.CompileError) Environment.Exit(65);
        if (result == InterpretResult.RuntimeError) Environment.Exit(70);
    }

    private static void Repl(VM vm)
    {
        while (true)
        {
            Console.Write("> ");

            var line = Console.ReadLine();
            if (string.IsNullOrEmpty(line))
            {
                Console.WriteLine();
                Environment.Exit(0);
            }

            vm.Interpret(line);
        }
    }
}