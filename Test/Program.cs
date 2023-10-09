using Keto;

var chunk = new Chunk();

var constant = chunk.AddConstant(1.2);
chunk.Write(OpCode.Constant, 123);
chunk.Write(constant, 123);
chunk.Write(OpCode.Negate, 123);

chunk.Write(OpCode.Return, 123);
chunk.Disassemble("test chunk");

using var vm = new VM();

vm.Interpret(chunk);