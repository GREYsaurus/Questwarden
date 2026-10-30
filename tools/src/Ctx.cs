// Guide build tooling - the build context: add-on name and the chosen -Target.
// Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
// SPDX-License-Identifier: GPL-3.0-only
//
// tools/build.ps1 calls Ctx.Load once per run. The values come from tools/addon.json (Name) and
// targets/<Target>/Target.<Target>.lua (game rules), the same file the add-on ships as
// Config/Target.lua, so the tools and the add-on can never disagree about a limit.

using System;
using System.Collections.Generic;
using System.IO;

namespace GuideTools
{
    public static class Ctx
    {
        public static string Name = "ClassicGuide";   // tools/addon.json "name"
        public static string Target = "";             // -Target
        public static string Root = "";               // repository root
        public static string TargetDir = "";          // targets/<Target>
        public static string GuidesSrc = "";          // targets/<Target>/guides-src
        public static string ReportDir = "";          // docs/generated/<Target>
        // Game rules (Target.<Target>.lua)
        public static int MaxLevel = 60;
        public static int QuestLogMax = 20;
        public static int FirstTalentLevel = 10;
        public static List<string> Chapters = new List<string> { "Azeroth" };
        public static string TargetName = "";
        public static string ClientBuild = "";
        public static bool Verified = false;
        // Coverage switches (targets/<Target>/target.json "require"), set by tools/build.ps1.
        public static bool RequireDatabase = true, RequireTalents = true, RequireRoutes = true;

        public static int TalentPoints { get { return MaxLevel - FirstTalentLevel + 1; } }

        public static string Load(string root, string target, string name)
        {
            Root = root; Target = target; Name = name;
            TargetDir = Path.Combine(root, "targets", target);
            GuidesSrc = Path.Combine(TargetDir, "guides-src");
            ReportDir = Path.Combine(root, "docs", "generated", target);
            string file = Path.Combine(TargetDir, "Target." + target + ".lua");
            if (!File.Exists(file)) throw new Exception("missing " + file);
            string text = File.ReadAllText(file);
            int start = text.IndexOf("ns.Target", StringComparison.Ordinal);
            start = start < 0 ? -1 : text.IndexOf('{', start);
            int end = text.LastIndexOf('}');
            if (start < 0 || end < start) throw new Exception(file + ": no `ns.Target = { ... }` table");
            var t = LuaLiteralReader.ParseValue(text.Substring(start, end - start + 1), Path.GetFileName(file)) as LTable;
            if (t == null) throw new Exception(file + ": ns.Target is not a literal table (functions are not allowed there)");
            if ((t.Get("id") as string) != target) throw new Exception(file + ": id must be \"" + target + "\"");
            MaxLevel = Int(t, "maxLevel", file);
            QuestLogMax = Int(t, "questLogMax", file);
            FirstTalentLevel = Int(t, "firstTalentLevel", file);
            TargetName = (t.Get("name") as string) ?? target;
            ClientBuild = (t.Get("clientBuild") as string) ?? "";
            Verified = t.Get("verified") is bool && (bool)t.Get("verified");
            var ch = t.Get("chapters") as LTable;
            Chapters = new List<string>();
            if (ch != null) for (int i = 1; i <= ch.Count; i++) Chapters.Add((string)ch.Get(i));
            if (Chapters.Count == 0) throw new Exception(file + ": chapters is empty");
            return string.Format("target {0}: {1}, level cap {2}, quest log {3}, {4} talent points, chapters {5}{6}",
                target, TargetName, MaxLevel, QuestLogMax, TalentPoints, string.Join("/", Chapters), Verified ? "" : " (UNVERIFIED)");
        }

        static int Int(LTable t, string key, string file)
        {
            object v = t.Get(key);
            if (!(v is double)) throw new Exception(file + ": " + key + " must be a number");
            return (int)(double)v;
        }
    }
}
