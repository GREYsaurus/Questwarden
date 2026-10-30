# Run a Lua 5.1 file with the Lua 5.1 runtime bundled in Python's `lupa` package, for machines
# without a lua5.1 binary (tools/build.ps1 test uses this as its fallback; docs/DEVELOPER.md).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Usage: python tools/lua51.py <file.lua>     (run from the repository root)
# The test runners end with os.exit(0|1), which ends this process with that code. An uncaught Lua
# error is printed and exits 1.
import sys

import lupa.lua51 as lua51

if len(sys.argv) != 2:
    sys.exit("usage: python tools/lua51.py <file.lua>")
runtime = lua51.LuaRuntime()
run = runtime.eval("function(path) local ok, err = pcall(dofile, path) if not ok then print('ERROR ' .. tostring(err)) os.exit(1) end end")
run(sys.argv[1].replace("\\", "/"))
