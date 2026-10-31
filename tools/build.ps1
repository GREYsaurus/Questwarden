# ClassicGuide build script (Windows PowerShell 5.1+ / PowerShell 7).
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools/build.ps1 <command> [-Target ClassicEra|Forever|TBC]
#
# Targets (targets/<Target>/, docs/DEVELOPER.md): ClassicEra (default, shipped), TBC (TBC Classic Anniversary,
# TBCGuide 0.9.5's data, shipped) and Forever (skeleton, not shipped until verified in the live client). Every
# command except package works on the add-on as staged for ONE target in build/<Target>/<name>/.
#
# Commands:
#   stage            Assemble build/<Target>/<name>/ from addon/ (shared code), targets/<Target>/addon/ (data),
#                    Target.<Target>.lua, and the TOC/Bindings templates filled from tools/addon.json
#   fetch            Download pinned upstream inputs (tools/upstream.json) into .cache/ and verify checksums
#   import-questie   Regenerate targets/<Target>/addon/Database/Questie/*.lua from the pinned QuestieDB source
#   import-client    Regenerate talent trees and race/class tables from client DB2 CSV exports
#   guides           Compile targets/<Target>/guides-src/*.guide into targets/<Target>/addon/Guides/Compiled/
#   lint             Lua 5.1 syntax check + global usage audit of every shipped .lua file
#   validate         Content validation (guides, talents, coverage, manifest)
#   report           Write docs/generated/<Target>/COVERAGE_REPORT.md
#   crosscheck       Compare our data with a reference add-on's data files: -Reference <folder outside the
#                    repository>. Writes only docs/generated/CROSSCHECK.md (docs/DATA_POLICY.md)
#   routes           Route model: walk every race/class route, write docs/generated/<Target>/ROUTE_AUDIT.md
#                    (fails on impossible quest order / quest-log overflow)
#   test             Headless Lua 5.1 tests against the staged add-on (lua5.1, or Python's lupa package)
#   package          Build dist/<name>-<version>.zip: ONE add-on folder for every shipped target (shared code once,
#                    each target's data under Targets/<Target>/, one <name>_<tocSuffix>.toc each), tested
#                    through each TOC, plus dist/<name>-<version>-source.zip. -Target is ignored
#   all              stage, guides, lint, validate, routes, report, test, then package if this target is shipped
#   rename <Name> [<slash>]   Change the add-on's name (and slash command) in tools/addon.json
#   zonequests "<Zone>" <Alliance|Horde>   Authoring aid: list a zone's quests from the bundled DB
#
# Nothing here is needed by players: the shipped add-on already contains all generated data.

param(
    [Parameter(Position = 0)][string]$Command = "all",
    [Parameter(Position = 1)][string]$Arg1,
    [Parameter(Position = 2)][string]$Arg2,
    [string]$Target = "ClassicEra",
    [string]$Reference = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Cache = Join-Path $Root ".cache"
$Upstream = Get-Content (Join-Path $PSScriptRoot "upstream.json") -Raw | ConvertFrom-Json
$BrandFile = Join-Path $PSScriptRoot "addon.json"
$Brand = Get-Content $BrandFile -Raw | ConvertFrom-Json
$Name = $Brand.name

$Shared = Join-Path $Root "addon"
$TargetDir = Join-Path $Root "targets\$Target"
if (-not (Test-Path (Join-Path $TargetDir "target.json"))) {
    $known = (Get-ChildItem (Join-Path $Root "targets") -Directory | ForEach-Object { $_.Name }) -join ", "
    throw "Unknown target '$Target'. Known targets: $known"
}
$TargetInfo = Get-Content (Join-Path $TargetDir "target.json") -Raw | ConvertFrom-Json
$Overlay = Join-Path $TargetDir "addon"
$StageRoot = Join-Path $Root "build\$Target"
$AddOn = Join-Path $StageRoot $Name
$Reports = Join-Path $Root "docs\generated\$Target"
$script:Staged = $false

function Load-Tools {
    if (-not ("GuideTools.LuaLiteralReader" -as [type])) {
        $src = Get-ChildItem (Join-Path $PSScriptRoot "src") -Filter *.cs | ForEach-Object { $_.FullName }
        Add-Type -Path $src -ReferencedAssemblies System.Core, System.Data, System.Xml, Microsoft.VisualBasic
    }
    $info = [GuideTools.Ctx]::Load($Root, $Target, $Name)
    $req = $TargetInfo.require
    [GuideTools.Ctx]::RequireDatabase = [bool]$req.database
    [GuideTools.Ctx]::RequireTalents = [bool]$req.talents
    [GuideTools.Ctx]::RequireRoutes = [bool]$req.routes
    $q = $TargetInfo.questie
    if ($q) {
        [GuideTools.Ctx]::QuestieFlavor = $q.flavor; [GuideTools.Ctx]::QuestieDataDir = $q.dataDir
        [GuideTools.Ctx]::QuestiePrefix = $q.prefix; [GuideTools.Ctx]::QuestieFixes = $q.fixes
        [GuideTools.Ctx]::QuestieFixesModule = $q.fixesModule; [GuideTools.Ctx]::QuestieXp = $q.xp
        [GuideTools.Ctx]::QuestieAllDangerousMobs = [bool]$q.allDangerousMobs
        [GuideTools.Ctx]::QuestieSpiritHealers = [bool]$q.spiritHealers
        $f = $q.npcFlags
        [GuideTools.Ctx]::FlagQuestGiver = $f.QUEST_GIVER; [GuideTools.Ctx]::FlagVendor = $f.VENDOR
        [GuideTools.Ctx]::FlagFlight = $f.FLIGHT_MASTER; [GuideTools.Ctx]::FlagTrainer = $f.TRAINER; [GuideTools.Ctx]::FlagInn = $f.INNKEEPER
    }
    if ($TargetInfo.xpPerLevel) {
        $v = @(0) + @($TargetInfo.xpPerLevel.values | ForEach-Object { [int]$_ })
        [GuideTools.Ctx]::XpPerLevel = [int[]]$v
    }
    if ($TargetInfo.clientTables) {
        [GuideTools.Ctx]::ClientProduct = $TargetInfo.clientTables.product
        [GuideTools.Ctx]::ClientTablesBuild = $TargetInfo.clientTables.build
        [GuideTools.Ctx]::ClientFlights = [bool]$TargetInfo.clientTables.flights
        if ($TargetInfo.clientTables.excludeSpellIdsFrom) { [GuideTools.Ctx]::ExcludeSpellIdsFrom = [int]$TargetInfo.clientTables.excludeSpellIdsFrom }
        [GuideTools.Ctx]::ExcludeSpellIds.Clear()
        foreach ($s in @($TargetInfo.clientTables.excludeSpellIds)) { if ($s) { [void][GuideTools.Ctx]::ExcludeSpellIds.Add([int]$s) } }
    }
    New-Item -ItemType Directory -Force $Reports | Out-Null
    if (-not $script:ToolsAnnounced) { Write-Host "info  $info"; $script:ToolsAnnounced = $true }
}

function Get-QdbRoot { Join-Path $Cache "upstream\questiedb" }
# Client tables are cached per build: .cache/upstream/db2/<build>/
function Get-Db2Root {
    if (-not $TargetInfo.clientTables) { throw "Target $Target has no clientTables in target.json." }
    Join-Path $Cache ("upstream\db2\" + $TargetInfo.clientTables.build)
}

function Write-Text([string]$path, [string[]]$lines) {
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    [IO.File]::WriteAllText($path, (($lines -join "`r`n") + "`r`n"), (New-Object Text.UTF8Encoding($false)))
}

# Copy every file under $from into $to, keeping relative paths and overwriting what is there.
function Copy-Tree([string]$from, [string]$to) {
    if (-not (Test-Path $from)) { return }
    $base = (Resolve-Path $from).Path.TrimEnd('\')
    foreach ($f in Get-ChildItem $from -Recurse -File) {
        $dest = Join-Path $to $f.FullName.Substring($base.Length + 1)
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item $f.FullName $dest -Force
    }
}

function Assert-Name {
    if ($Name -notmatch '^[A-Za-z][A-Za-z0-9]{2,15}$') { throw "tools/addon.json name '$Name' must be 3-16 letters/digits starting with a letter (it becomes a folder, SavedVariables and party-message prefix)" }
    if ($Brand.slash -notmatch '^[a-z][a-z0-9]{1,15}$') { throw "tools/addon.json slash '$($Brand.slash)' must be lowercase letters/digits" }
}

function Invoke-Stage {
    if ($script:Staged) { return }
    Assert-Name
    if (Test-Path $StageRoot) { Remove-Item $StageRoot -Recurse -Force -Confirm:$false }
    New-Item -ItemType Directory -Force $AddOn | Out-Null
    Copy-Tree $Shared $AddOn
    Copy-Tree $Overlay $AddOn
    New-Item -ItemType Directory -Force (Join-Path $AddOn "Config") | Out-Null
    Copy-Item (Join-Path $TargetDir "Target.$Target.lua") (Join-Path $AddOn "Config\Target.lua") -Force
    Write-Text (Join-Path $AddOn "Config\Brand.lua") @(
        "-- $Name - names that are not derived from the add-on folder. GENERATED by tools/build.ps1 stage",
        "-- from tools/addon.json. DO NOT EDIT: change tools/addon.json and rebuild.",
        "-- SPDX-License-Identifier: GPL-3.0-only",
        "local _, ns = ...",
        "ns.brand = { slash = `"$($Brand.slash)`" }")
    $vars = @{
        "{{NAME}}" = $Name; "{{KEY}}" = $Name.ToUpperInvariant(); "{{VERSION}}" = $Brand.version
        "{{AUTHOR}}" = $Brand.author; "{{NOTES}}" = $Brand.notes; "{{INTERFACE}}" = $TargetInfo.interface
        "{{TARGET_TITLE}}" = $TargetInfo.title
    }
    function Fill([string]$text) { foreach ($k in $vars.Keys) { $text = $text.Replace($k, [string]$vars[$k]) }; $text }
    $toc = foreach ($l in Get-Content (Join-Path $Shared "addon.toc.in")) {
        if ($l.StartsWith("#!")) { continue }
        if ($l.Trim() -eq "{{EXTRA}}") { foreach ($x in @($TargetInfo.tocExtra)) { if ($x) { Fill $x } }; continue }
        Fill $l
    }
    Write-Text (Join-Path $AddOn "$Name.toc") $toc
    Write-Text (Join-Path $AddOn "Bindings.xml") (Get-Content (Join-Path $Shared "Bindings.xml.in") | ForEach-Object { Fill $_ })
    Get-ChildItem $AddOn -Recurse -File -Filter *.in | Remove-Item -Force -Confirm:$false
    # For tests/run_tests.lua and tests/run_smoke.lua (GUIDE_TARGET picks the target; see docs/DEVELOPER.md).
    $rel = "build/$Target/$Name/"
    Write-Text (Join-Path $StageRoot "stage.lua") @(
        "-- GENERATED by tools/build.ps1 stage. Where the staged add-on is, for the headless tests.",
        "return { name = `"$Name`", target = `"$Target`", dir = `"$rel`", toc = `"$Name.toc`", data = `"`", slash = `"$($Brand.slash)`" }")
    $script:Staged = $true
    Write-Host "Staged $Target -> $rel"
}

function Invoke-Fetch {
    $ProgressPreference = 'SilentlyContinue'
    $q = $Upstream.questiedb
    $zip = Join-Path $Cache "questiedb-$($q.commit).zip"
    New-Item -ItemType Directory -Force $Cache | Out-Null
    if (-not (Test-Path $zip)) {
        Write-Host "Downloading QuestieDB @ $($q.commit)"
        Invoke-WebRequest $q.archiveUrl -OutFile $zip -UseBasicParsing
    }
    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash
    if ($hash -ne $q.archiveSha256) { throw "QuestieDB archive checksum mismatch: $hash (expected $($q.archiveSha256))" }
    Write-Host "QuestieDB archive SHA256 OK"
    $dest = Get-QdbRoot
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $z = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        foreach ($e in $z.Entries) {
            $rel = $e.FullName -replace '^[^/]+/', ''
            if ($e.Length -gt 0 -and ($q.files -contains $rel)) {
                $t = Join-Path $dest ($rel -replace '/', '\')
                New-Item -ItemType Directory -Force (Split-Path $t) | Out-Null
                [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $t, $true)
            }
        }
    } finally { $z.Dispose() }
    foreach ($f in $q.files) {
        if (-not (Test-Path (Join-Path $dest $f))) { throw "Expected upstream file missing from archive: $f" }
    }
    $c = $Upstream.clientTables
    if (-not $TargetInfo.clientTables) { Write-Host "No client tables for $Target."; return }
    $dd = Get-Db2Root
    New-Item -ItemType Directory -Force $dd | Out-Null
    foreach ($t in $c.tables) {
        $out = Join-Path $dd "$t.csv"
        if (-not (Test-Path $out)) {
            $url = $c.urlTemplate.Replace("{table}", $t).Replace("{build}", $TargetInfo.clientTables.build)
            Write-Host "Downloading $t ($($TargetInfo.clientTables.build))"
            Invoke-WebRequest $url -OutFile $out -UseBasicParsing
        }
    }
    Write-Host "Upstream inputs ready in $Cache"
}

function Invoke-ImportQuestie {
    Load-Tools
    if (-not $TargetInfo.questie) { throw "Target $Target has no questie inputs in target.json." }
    $qdb = Get-QdbRoot
    if (-not (Test-Path $qdb)) { throw "Run 'fetch' first." }
    $prov = "QuestieDB commit $($Upstream.questiedb.commit) ($($Upstream.questiedb.release)), flavor $($TargetInfo.questie.flavor)."
    Write-Host "Parsing upstream tables..."
    $data = [GuideTools.QuestieData]::Load($qdb)
    $corr = [GuideTools.QuestieCorrections]::Apply($data, $qdb)
    $out = Join-Path $Overlay "Database\Questie"
    $stats = [GuideTools.QuestieExporter]::Export($data, $out, $prov)
    $stats.GetEnumerator() | Sort-Object Key | ForEach-Object { Write-Host ("  {0,-10} {1}" -f $_.Key, $_.Value) }
    Write-Host ("  corrections applied: {0}, skipped: {1}" -f $corr.Applied, $corr.Skipped.Count)
    $log = Join-Path $Reports "questie-import.log"
    $lines = @("QuestieDB import - $prov", "")
    $lines += $stats.GetEnumerator() | Sort-Object Key | ForEach-Object { "{0}: {1}" -f $_.Key, $_.Value }
    $lines += "", "Corrections applied: $($corr.Applied)", "Corrections skipped (could not be evaluated statically):"
    $lines += $corr.Skipped
    $lines += "", "Warnings:"
    $lines += $data.Warnings
    $lines | Set-Content $log -Encoding UTF8
    Write-Host "Wrote $out (log: $log)"
}

function Invoke-Crosscheck {
    if (-not $Reference) { throw "crosscheck needs -Reference <folder outside the repository> (docs/DATA_POLICY.md)." }
    python (Join-Path $PSScriptRoot "research\crosscheck.py") $Target $Reference
    if ($LASTEXITCODE -ne 0) { throw "crosscheck failed." }
}

function Invoke-ImportClient {
    Load-Tools
    $dd = Get-Db2Root
    if (-not (Test-Path $dd)) { throw "Run 'fetch' first." }
    $r = [GuideTools.ClientTables]::Export($dd, $Overlay, $TargetInfo.clientTables.build)
    Write-Host $r
    $ex = Join-Path $Reports "client-excluded-spells.csv"
    (@("table,spell,name") + @([GuideTools.Ctx]::ExcludedSpells)) | Set-Content $ex -Encoding UTF8
    Write-Host ("left out (spell id >= {0}, or in excludeSpellIds): {1} (list: docs/generated/{2}/client-excluded-spells.csv)" -f [GuideTools.Ctx]::ExcludeSpellIdsFrom, [GuideTools.Ctx]::ExcludedSpells.Count, $Target)
}

function Write-Csv([string]$path, [string]$header, $rows) {
    (@($header) + @($rows | ForEach-Object { ($_ | ForEach-Object { '"' + ($_ -replace '"','""') + '"' }) -join "," })) | Set-Content $path -Encoding UTF8
}

function Invoke-Guides {
    Invoke-Stage
    Load-Tools
    $stagedCompiled = Join-Path $AddOn "Guides\Compiled"
    if (Test-Path $stagedCompiled) { Get-ChildItem $stagedCompiled -File | Remove-Item -Force -Confirm:$false }
    $res = [GuideTools.GuideCompiler]::CompileAll([GuideTools.Ctx]::GuidesSrc, $AddOn)
    Write-Host $res.Summary
    (@($res.Errors | ForEach-Object { "ERROR $_" }) + @($res.Warnings)) | Set-Content (Join-Path $Reports "guide-warnings.log") -Encoding UTF8
    # Dungeon audit: quests tagged from quest data, and quests with only some objectives inside.
    Write-Csv (Join-Path $Reports "dungeon-quests.csv") "guide,quest,title,instance,step" $res.AutoDungeon
    Write-Csv (Join-Path $Reports "dungeon-mixed.csv") "guide,quest,title,place" $res.MixedDungeon
    # Roaming hunting routes: which kill/drop steps have one, could get one, or keep a single waypoint (docs/ROAMING.md).
    Write-Csv (Join-Path $Reports "roaming-candidates.csv") "guide,quest,obj,title,status,reason,targets,route" $res.RoamInventory
    if ($res.Errors.Count -gt 0) {
        $res.Errors | Select-Object -First 200 | ForEach-Object { Write-Host "  ERROR $_" -ForegroundColor Red }
        throw "Guide compilation failed with $($res.Errors.Count) error(s)."
    }
    # The compiled guides are target data: keep the copy in targets/<Target>/addon/ in step with the stage.
    $compiledOut = Join-Path $Overlay "Guides\Compiled"
    if (Test-Path $compiledOut) { Get-ChildItem $compiledOut -File | Remove-Item -Force -Confirm:$false }
    Copy-Tree (Join-Path $AddOn "Guides\Compiled") $compiledOut
    $res.Warnings | Select-Object -First 60 | ForEach-Object { Write-Host "  warn  $_" -ForegroundColor Yellow }
    if ($res.Warnings.Count -gt 60) { Write-Host "  ... $($res.Warnings.Count - 60) more warnings (see docs/generated/$Target/guide-warnings.log)" }
}

function Invoke-Lint {
    Invoke-Stage
    Load-Tools
    $r = [GuideTools.Linter]::Run($AddOn, (Join-Path $PSScriptRoot "wow_api_allowlist.txt"))
    $r.Messages | ForEach-Object { Write-Host $_ }
    Write-Host $r.Summary
    if ($r.Errors -gt 0) { throw "Lint failed with $($r.Errors) error(s)." }
}

function Invoke-Validate {
    Invoke-Stage
    Load-Tools
    $r = [GuideTools.Validator]::Run($Root, $AddOn)
    $r.Messages | ForEach-Object { Write-Host $_ }
    Write-Host $r.Summary
    if ($r.Errors -gt 0) { throw "Validation failed with $($r.Errors) error(s)." }
}

function Invoke-Routes {
    Invoke-Stage
    Load-Tools
    $a = [GuideTools.RouteAnalyzer]::Run($Root, $AddOn)
    [GuideTools.RouteAnalyzer]::Write($Root, $a)
    $a.Errors | Select-Object -First 40 | ForEach-Object { Write-Host "  ERROR $_" -ForegroundColor Red }
    Write-Host ("routes: {0} routes walked, {1} error(s), {2} warning(s). Report: docs/generated/{3}/ROUTE_AUDIT.md" -f $a.Routes, $a.Errors.Count, $a.Warnings.Count, $Target)
    if ($a.Errors.Count -gt 0) { throw "Route audit failed with $($a.Errors.Count) error(s)." }
}

function Invoke-Report {
    Invoke-Stage
    Load-Tools
    $path = Join-Path $Reports "COVERAGE_REPORT.md"
    [GuideTools.Validator]::WriteCoverageReport($Root, $AddOn, $path)
    Write-Host "Wrote $path"
}

function Invoke-Test {
    Invoke-Stage
    # Build tooling first (C# lua reader, linter, target rules), then the add-on in Lua.
    powershell -ExecutionPolicy Bypass -File (Join-Path $Root "tests/tools-selftest.ps1")
    if ($LASTEXITCODE -ne 0) { throw "Tool self-test failed." }
    # The TBC fixture carries real data, so it runs the full suite; the other targets run the smoke suite
    # (boot, detection, empty-data behaviour) until their data exists.
    $runner = if ($Target -eq "TBC") { "tests/run_tests.lua" } else { "tests/run_smoke.lua" }
    $env:GUIDE_TARGET = $Target
    Push-Location $Root
    try {
        $lua = Get-Command lua5.1 -ErrorAction SilentlyContinue
        if ($lua) { & $lua.Source $runner; $code = $LASTEXITCODE }
        else {
            python (Join-Path $PSScriptRoot "lua51.py") $runner; $code = $LASTEXITCODE
        }
    } finally { Pop-Location }
    if ($code -ne 0) { throw "Tests failed ($runner, target $Target)." }
}

# Zip a folder (including the folder name) with forward-slash entry names, as the zip spec requires.
# ZipFile.CreateFromDirectory on .NET Framework writes backslashes, which some extractors mishandle.
function New-Zip([string]$dir, [string]$zipPath) {
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $base = Split-Path -Parent $dir
    $fs = [IO.File]::Open($zipPath, [IO.FileMode]::Create)
    $zip = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($f in Get-ChildItem $dir -Recurse -File) {
            $name = $f.FullName.Substring($base.Length).TrimStart('\', '/').Replace('\', '/')
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $name, [IO.Compression.CompressionLevel]::Optimal)
        }
    } finally { $zip.Dispose(); $fs.Dispose() }
}

# One download for every shipped target (target.json "shipped": true). The add-on folder holds the shared code
# once and each target's data under Targets\<Target>\, with one <name>_<tocSuffix>.toc per target that lists
# the shared files plus that target's data. The client loads the TOC for its game type (_Vanilla on Classic Era,
# _TBC on TBC Classic Anniversary), so each client sees only its own data. Each target is staged first, and
# the assembled folder is tested once per TOC before it is zipped.
function Invoke-Package {
    $targets = @(Get-ChildItem (Join-Path $Root "targets") -Directory | Where-Object {
        (Get-Content (Join-Path $_.FullName "target.json") -Raw | ConvertFrom-Json).shipped } | ForEach-Object { $_.Name })
    if ($targets.Count -eq 0) { throw "No target has `"shipped`": true." }
    $ver = $Brand.version
    $dist = Join-Path $Root "dist"
    $pkgRoot = Join-Path $Root "build\Package"
    $pkg = Join-Path $pkgRoot $Name
    if (Test-Path $pkgRoot) { Remove-Item $pkgRoot -Recurse -Force -Confirm:$false }
    New-Item -ItemType Directory -Force $pkg | Out-Null
    $sharedBase = (Resolve-Path $Shared).Path.TrimEnd('\')
    $sharedSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($f in Get-ChildItem $Shared -Recurse -File) { if ($f.Extension -ne ".in") { [void]$sharedSet.Add($f.FullName.Substring($sharedBase.Length + 1)) } }
    foreach ($x in "Config\Brand.lua", "Bindings.xml") { [void]$sharedSet.Add($x) }
    foreach ($t in $targets) {
        $info = Get-Content (Join-Path $Root "targets\$t\target.json") -Raw | ConvertFrom-Json
        if (-not $info.tocSuffix) { throw "targets/$t/target.json: a shipped target needs `"tocSuffix`" (the client's TOC suffix, e.g. Vanilla, TBC)." }
        powershell -ExecutionPolicy Bypass -File $PSCommandPath stage -Target $t | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Staging $t failed." }
        $src = Join-Path $Root "build\$t\$Name"
        foreach ($f in Get-ChildItem $src -Recurse -File) {
            $rel = $f.FullName.Substring($src.Length + 1)
            if ($rel -eq "$Name.toc") { continue }
            if ($sharedSet.Contains($rel)) {
                $dest = Join-Path $pkg $rel
                if (Test-Path $dest) {
                    if ((Get-FileHash $dest).Hash -ne (Get-FileHash $f.FullName).Hash) { throw "Shared file $rel differs between targets." }
                    continue
                }
            } else { $dest = Join-Path $pkg "Targets\$t\$rel" }
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Copy-Item $f.FullName $dest -Force
        }
        $toc = foreach ($l in Get-Content (Join-Path $src "$Name.toc")) {
            $line = $l.Trim()
            if ($line -eq "" -or $line.StartsWith("#") -or $sharedSet.Contains($line)) { $l } else { "Targets\$t\$line" }
        }
        Write-Text (Join-Path $pkg "$($Name)_$($info.tocSuffix).toc") $toc
        # For the package tests: the same suites as `test`, run through this TOC in the assembled folder.
        Write-Text (Join-Path $pkgRoot "$t\stage.lua") @(
            "-- GENERATED by tools/build.ps1 package. The assembled download, loaded through one target's TOC.",
            "return { name = `"$Name`", target = `"$t`", dir = `"build/Package/$Name/`", toc = `"$($Name)_$($info.tocSuffix).toc`", data = `"Targets/$t/`", slash = `"$($Brand.slash)`" }")
    }
    foreach ($f in "LICENSE", "NOTICE.md", "THIRD_PARTY_LICENSES.md", "README.md") { Copy-Item (Join-Path $Root $f) (Join-Path $pkg $f) }
    foreach ($t in $targets) {
        $runner = if ($t -eq "TBC") { "tests/run_tests.lua" } else { "tests/run_smoke.lua" }
        $env:GUIDE_TARGET = "Package/$t"
        Push-Location $Root
        try {
            $lua = Get-Command lua5.1 -ErrorAction SilentlyContinue
            if ($lua) { & $lua.Source $runner; $code = $LASTEXITCODE } else { python (Join-Path $PSScriptRoot "lua51.py") $runner; $code = $LASTEXITCODE }
        } finally { Pop-Location }
        if ($code -ne 0) { throw "Package tests failed ($runner through the $t TOC)." }
    }
    New-Item -ItemType Directory -Force $dist | Out-Null
    $stage = Join-Path $dist "stage"
    if (Test-Path $stage) { Remove-Item $stage -Recurse -Force -Confirm:$false }
    # GPL: the full corresponding source alongside the add-on.
    $srcStage = Join-Path $stage "$Name-source"
    New-Item -ItemType Directory -Force $srcStage | Out-Null
    foreach ($d in "addon", "targets", "tools", "tests", "docs") { Copy-Tree (Join-Path $Root $d) (Join-Path $srcStage $d) }
    foreach ($f in "LICENSE", "COPYING", "NOTICE.md", "THIRD_PARTY_LICENSES.md", "README.md", "INSTALL.md", "CHANGELOG.md", ".gitignore") {
        Copy-Item (Join-Path $Root $f) (Join-Path $srcStage $f)
    }
    $addonZip = Join-Path $dist "$Name-$ver.zip"
    $srcZip = Join-Path $dist "$Name-$ver-source.zip"
    foreach ($z in $addonZip, $srcZip) { if (Test-Path $z) { Remove-Item $z -Force -Confirm:$false } }
    New-Zip $pkg $addonZip
    New-Zip $srcStage $srcZip
    Remove-Item $stage -Recurse -Force -Confirm:$false
    Write-Host ("Packaged {0} ({1})" -f $addonZip, ($targets -join " + "))
    Write-Host "Packaged $srcZip"
}

function Invoke-Rename([string]$newName, [string]$newSlash) {
    if (-not $newName) { throw "Usage: tools/build.ps1 rename <NewName> [<slash>]" }
    $j = Get-Content $BrandFile -Raw
    $j = $j -replace '"name":\s*"[^"]*"', ('"name": "' + $newName + '"')
    if ($newSlash) { $j = $j -replace '"slash":\s*"[^"]*"', ('"slash": "' + $newSlash + '"') }
    [IO.File]::WriteAllText($BrandFile, $j, (New-Object Text.UTF8Encoding($false)))
    Write-Host "tools/addon.json: name $Name -> $newName$(if ($newSlash) { ", slash -> $newSlash" })"
    Write-Host "Code needs no change. Prose in README.md, INSTALL.md and docs/ still says ${Name}: update it by hand."
}

switch ($Command) {
    "stage" { Invoke-Stage }
    "fetch" { Invoke-Fetch }
    "import-questie" { Invoke-ImportQuestie }
    "import-client" { Invoke-ImportClient }
    "crosscheck" { Invoke-Crosscheck }
    "guides" { Invoke-Guides }
    "lint" { Invoke-Lint }
    "validate" { Invoke-Validate }
    "report" { Invoke-Report }
    "routes" { Invoke-Routes }
    "test" { Invoke-Test }
    "package" { Invoke-Package }
    "rename" { Invoke-Rename $Arg1 $Arg2 }
    "zonequests" { Invoke-Stage; Load-Tools; [GuideTools.QuestLister]::List($AddOn, $Arg1, $Arg2) }
    "all" {
        Invoke-Stage; Invoke-Guides; Invoke-Lint; Invoke-Validate; Invoke-Routes; Invoke-Report; Invoke-Test
        if ($TargetInfo.shipped) { Invoke-Package } else { Write-Host "package: skipped ($Target is not shipped)" }
    }
    default { throw "Unknown command '$Command'. See the header of tools/build.ps1." }
}
