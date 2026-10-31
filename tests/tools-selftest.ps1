# Questwarden - self-tests for the build tooling (runs without a Lua interpreter).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
#   powershell -ExecutionPolicy Bypass -File tests/tools-selftest.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$src = Get-ChildItem (Join-Path $Root "tools\src") -Filter *.cs | ForEach-Object { $_.FullName }
Add-Type -Path $src -ReferencedAssemblies System.Core, System.Data, System.Xml, Microsoft.VisualBasic

$fail = 0; $pass = 0
function Check($cond, $msg) { if ($cond) { $script:pass++ } else { $script:fail++; Write-Host "FAIL: $msg" -ForegroundColor Red } }
function SyntaxOk($code) { try { [void][GuideTools.LuaChecker]::Check($code); return $true } catch { return $false } }

# Lua checker must accept valid and reject invalid Lua 5.1
Check (SyntaxOk 'local t = {a=1,[2]=3,"x";} print(t.a)') "table constructor"
Check (SyntaxOk 'local function f(...) return ... end') "vararg function"
Check (SyntaxOk 'for i=1,2 do if i then break end end') "break inside if inside for"
Check (SyntaxOk 'local s = [==[ long ]] ]==]') "long bracket level"
Check (-not (SyntaxOk 'local x = = 1')) "rejects double equals"
Check (-not (SyntaxOk 'if x then')) "rejects missing end"
Check (-not (SyntaxOk 'local function f() return ... end')) "rejects ... outside vararg"
Check (-not (SyntaxOk 'x = "unterminated')) "rejects unterminated string"
Check (-not (SyntaxOk 'return 1 print(2)')) "rejects statement after return"

# Global tracking
$c = [GuideTools.LuaChecker]::Check('local a = 1; b = 2; print(c.d)')
Check (($c.Globals | Where-Object { $_.Name -eq 'b' -and $_.Write }).Count -eq 1) "detects global write"
Check (($c.Globals | Where-Object { $_.Name -eq 'c' -and $_.Field -eq 'd' }).Count -eq 1) "detects global read with field"
Check (($c.Globals | Where-Object { $_.Name -eq 'a' }).Count -eq 0) "locals are not globals"

# Literal reader round trip
$t = [GuideTools.LuaLiteralReader]::ParseValue('return {1,nil,{x=2},"s\"q",[10]=-3.5,flag=true}', 'test')
$lua = [GuideTools.LuaWriter]::Value($t)
$t2 = [GuideTools.LuaLiteralReader]::ParseValue($lua, 'test2')
Check ([GuideTools.LuaWriter]::Value($t2) -eq $lua) "literal round trip: $lua"
Check ($t.Get(1) -eq 1 -and $null -eq $t.Get(2) -and $t.Get(4) -eq 's"q') "positional values with holes"

# Target rules parse from the same Target.<Target>.lua the add-on ships (tools/src/Ctx.cs)
[void][GuideTools.Ctx]::Load($Root, "ClassicEra", "Questwarden")
Check ([GuideTools.Ctx]::MaxLevel -eq 60 -and [GuideTools.Ctx]::QuestLogMax -eq 20 -and [GuideTools.Ctx]::TalentPoints -eq 51) "Classic Era rules: 60, quest log 20, 51 points"
Check ([GuideTools.Ctx]::Verified -and [GuideTools.Ctx]::Chapters.Count -eq 1) "Classic Era: verified, one chapter"
[void][GuideTools.Ctx]::Load($Root, "Forever", "Questwarden")
Check (-not [GuideTools.Ctx]::Verified) "Forever is unverified"
[void][GuideTools.Ctx]::Load($Root, "TBC", "Questwarden")
Check ([GuideTools.Ctx]::MaxLevel -eq 70 -and [GuideTools.Ctx]::QuestLogMax -eq 25 -and [GuideTools.Ctx]::TalentPoints -eq 61) "TBC fixture rules: 70, quest log 25, 61 points"

# Target data parses and has expected shape (TBC fixture)
$db = [GuideTools.BundledDb]::Load((Join-Path $Root "targets/TBC/addon"))
Check ($db.Quests.Count -gt 6000) "quest count"
Check ($db.Quests[783].Get(1) -eq "A Threat Within") "quest 783 name"
Check ($db.ZoneByName["Hellfire Peninsula"] -eq 3483) "zone lookup"

Write-Host ("tools self-test: {0} passed, {1} failed" -f $pass, $fail)
if ($fail -gt 0) { exit 1 }
