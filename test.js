const fs = require('fs');
const source = fs.readFileSync("./zig-out/lib/keto.wasm");
const typedArray = new Uint8Array(source);

WebAssembly.instantiate(typedArray).then(result => {
  const add = result.instance.exports.add;
  console.log(add(1, 2));
});