# Krust
A simple interpreted programming language based on Lox in the book [Crafting Interpreters](https://craftinginterpreters.com/)

## CLI Usage

- Run from file: `krust ./path/to/file.krust`
- REPL: `krust`

## Language grammar

```swift
fn fib(n) {
  if (n <= 1) return n;
  return fib(n - 2) + fib(n - 1);
}

for (var i = 0; i < 20; i = i + 1) {
  print fib(i);
}
```
