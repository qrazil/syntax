#!/usr/bin/env python3
"""Does m31 swallow a parser-sized static table? Writes big.m31 (a constant
Array<int> of N entries, 10% non-zero) and main.m31 (sums it), into DIR.

  tabletest.py DIR [N]       then, in DIR (with a `deps` file):
  m31c --emit-c main.m31 -o main.c && cc -O2 ... main.c <runtime>

N must stay under 2^20: a collection constant holds at most that many.
"""
import os, random, sys

out = sys.argv[1]
n = int(sys.argv[2]) if len(sys.argv) > 2 else 1000000
random.seed(1)
values = [random.randrange(0, 60000) if random.random() < 0.1 else 0 for _ in range(n)]
os.makedirs(out, exist_ok=True)
open(os.path.join(out, "big.m31"), "w").write(
    "const Array<int> TABLE = [" + ", ".join(map(str, values)) + "];\n\n"
    "pub int get(int index) {\n    return TABLE[index];\n}\n")
open(os.path.join(out, "main.m31"), "w").write(
    "import big;\n\nint sum = 0;\nfor (int index in 0 .. %d) {\n    sum = sum + big.get(index);\n}\nprint(sum);\n" % n)
open(os.path.join(out, "deps"), "w").write("name tabletest\nversion 0.1.0\n")
