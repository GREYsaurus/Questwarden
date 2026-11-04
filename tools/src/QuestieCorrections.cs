// Guide build tooling - static application of QuestieDB TBC quest corrections.
// Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
// SPDX-License-Identifier: GPL-3.0-only
//
// Upstream corrections (src/corrections/Tbc/tbcQuestFixes.lua) are Lua code that
// returns override tables keyed by symbolic constants. We cannot (and must not)
// execute arbitrary upstream code at build time, so this is a tiny *evaluator*
// for the data-shaped subset: literals, tables, enum constants, l10n("...")
// wrappers and +/- arithmetic. Anything else (class/race/faction-dependent
// expressions, runtime calls) is skipped and logged, never guessed.

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

namespace GuideTools
{
    public sealed class CorrectionResult
    {
        public int Applied;
        public List<string> Skipped = new List<string>();
        public List<string> Repaired = new List<string>();
    }

    public sealed class QuestieCorrections
    {
        sealed class Unevaluable { public string Why; public Unevaluable(string w) { Why = w; } }

        List<Token> t;
        int i;
        readonly Dictionary<string, Dictionary<string, double>> enums = new Dictionary<string, Dictionary<string, double>>();

        static readonly string[] QuestKeyNames = {
            null, "name","startedBy","finishedBy","requiredLevel","questLevel","requiredRaces","requiredClasses",
            "objectivesText","triggerEnd","objectives","sourceItemId","preQuestGroup","preQuestSingle","childQuests",
            "inGroupWith","exclusiveTo","zoneOrSort","requiredSkill","requiredMinRep","requiredMaxRep",
            "requiredSourceItems","nextQuestInChain","questFlags","specialFlags","parentQuest","reputationReward",
            "breadcrumbForQuestId","breadcrumbs","extraObjectives","requiredSpell","requiredSpecialization",
            "requiredMaxLevel","availableUntilCompleted","availableStartingWith","requiredRanks","disabledByQuest" };

        // The fix file (target.json questie.fixes / fixesModule), or the ordered layers of questie.fixList: each
        // later layer overrides the earlier ones, as QuestieDB applies them.
        public static CorrectionResult Apply(QuestieData d, string qdbRoot)
        {
            var res = new CorrectionResult();
            var layers = Ctx.QuestieFixList.Count > 0 ? Ctx.QuestieFixList : new List<string[]> { new[] { Ctx.QuestieFixes, Ctx.QuestieFixesModule } };
            var c = new QuestieCorrections();
            c.LoadEnums(qdbRoot);
            foreach (var layer in layers)
            {
                string fixes = Path.Combine(qdbRoot, layer[0].Replace('/', Path.DirectorySeparatorChar));
                if (!File.Exists(fixes)) { res.Skipped.Add(layer[0] + " not present; layer skipped"); continue; }
                c.module = layer[1];
                c.t = LuaLexer.Lex(File.ReadAllText(fixes, Encoding.UTF8));
                c.ApplyMainTable(d, res);
            }
            DropSelfPrerequisites(d, res);
            return res;
        }

        // A quest can never be its own prerequisite. A preQuestSingle list that names the quest itself is an exclusive
        // group recorded in the wrong field (Forever's Call of Earth: 1516 and 1519 list {1516, 1519, 92466}, which
        // are also their exclusiveTo), so the list is dropped and logged.
        static void DropSelfPrerequisites(QuestieData d, CorrectionResult res)
        {
            const int preQuestSingle = 13;
            foreach (var kv in d.Quests)
            {
                var pre = kv.Value.Get(preQuestSingle) as LTable;
                if (pre == null) continue;
                for (int k = 1; k <= pre.Count; k++)
                {
                    if (pre.Get(k) is double && (int)(double)pre.Get(k) == kv.Key)
                    {
                        kv.Value.Set((double)preQuestSingle, null);
                        res.Repaired.Add("quest " + kv.Key + ": preQuestSingle names the quest itself (an exclusive group); dropped");
                        break;
                    }
                }
            }
        }

        string module;

        void LoadEnums(string qdbRoot)
        {
            var qk = new Dictionary<string, double>();
            for (int k = 1; k < QuestKeyNames.Length; k++)
            {
                qk[QuestKeyNames[k]] = k;
                qk[QuestKeyNames[k] + "_add"] = AddBase + k;       // merge into the field (Forever traces and fixes)
                qk[QuestKeyNames[k] + "_remove"] = RemoveBase + k; // take ids out of the field
            }
            enums["questKeys"] = qk;

            enums["raceIDs"] = new Dictionary<string, double> {
                {"NONE",0},{"HUMAN",1},{"ORC",2},{"DWARF",4},{"NIGHT_ELF",8},{"UNDEAD",16},{"TAUREN",32},
                {"GNOME",64},{"TROLL",128},{"GOBLIN",256},{"BLOOD_ELF",512},{"DRAENEI",1024},
                {"ALL_ALLIANCE",1101},{"ALL_HORDE",690},
                // Forever's Skyborne (QuestieDB src/corrections/enum/expansions.lua: race ids 95 and 96)
                {"SKYBORNE_ALLIANCE",4294967296.0},{"SKYBORNE_HORDE",8589934592.0} };
            enums["classIDs"] = new Dictionary<string, double> {
                {"NONE",0},{"WARRIOR",1},{"PALADIN",2},{"HUNTER",4},{"ROGUE",8},{"PRIEST",16},{"SHAMAN",64},
                {"MAGE",128},{"WARLOCK",256},{"DRUID",1024},{"ALL_CLASSES",1503} };

            // Map-icon hints inside objective rows. the importer does not export icon types, so any
            // stable placeholder value is fine; it only lets the surrounding data evaluate.
            var icons = new Dictionary<string, double>();
            foreach (var n in new[] { "EVENT", "INTERACT", "TALK", "OBJECT", "SLAY", "LOOT", "NODE_FISH", "NODE_HERB", "NODE_ORE", "AVAILABLE", "COMPLETE" })
                icons["ICON_TYPE_" + n] = icons.Count + 1;
            enums["Questie"] = icons;

            string en = Path.Combine(qdbRoot, "src", "corrections", "enum");
            ReadEnumBlocks(Path.Combine(en, "zones.lua"), "zoneIDs", "zoneIDs");
            ReadEnumBlocks(Path.Combine(en, "quests.lua"), "sortKeys", "sortKeys");
            ReadEnumBlocks(Path.Combine(en, "quests.lua"), "specialFlags", "specialFlags");
            ReadEnumBlocks(Path.Combine(en, "quests.lua"), "questFlags", "questFlags");
            ReadEnumBlocks(Path.Combine(en, "factions.lua"), "factionIDs", "factionIDs");
            ReadEnumBlocks(Path.Combine(en, "professions.lua"), "professionKeys", "profKeys");
        }

        static readonly Regex EnumEntry = new Regex(@"^\s*\[?""?([A-Za-z_][A-Za-z0-9_]*)""?\]?\s*=\s*(-?\d+)\s*,?");

        // Reads `constants.<block> = { NAME = number, ... }` blocks line by line.
        void ReadEnumBlocks(string path, string block, string alias)
        {
            if (!File.Exists(path)) return;
            var dict = new Dictionary<string, double>();
            bool inBlock = false;
            int depth = 0;
            foreach (var raw in File.ReadAllLines(path))
            {
                string line = raw;
                int cpos = line.IndexOf("--", StringComparison.Ordinal);
                if (cpos >= 0) line = line.Substring(0, cpos);
                if (!inBlock)
                {
                    if (Regex.IsMatch(line, @"\." + block + @"\s*=\s*\{")) { inBlock = true; depth = 1; }
                    continue;
                }
                foreach (char ch in line) { if (ch == '{') depth++; else if (ch == '}') depth--; }
                var m = EnumEntry.Match(line);
                if (m.Success && depth >= 1) dict[m.Groups[1].Value] = double.Parse(m.Groups[2].Value, CultureInfo.InvariantCulture);
                if (depth <= 0) break;
            }
            if (dict.Count > 0) enums[alias] = dict;
        }

        Token Cur { get { return t[i]; } }
        bool IsOp(string s) { return (Cur.Kind == TK.Op || Cur.Kind == TK.Keyword) && Cur.Text == s; }

        void ApplyMainTable(QuestieData d, CorrectionResult res)
        {
            // Locate `function <module>:Load()` (QuestieQuestFixes for Classic, QuestieTBCQuestFixes for TBC), then its `return {`.
            int start = -1;
            for (int k = 0; k + 3 < t.Count; k++)
            {
                if (t[k].Text == "function" && t[k + 1].Text == module && t[k + 2].Text == ":" && t[k + 3].Text == "Load")
                { start = k; break; }
            }
            if (start < 0) { res.Skipped.Add("could not locate " + module + ":Load"); return; }
            int r = start;
            while (r < t.Count && !(t[r].Text == "return" && t[r + 1].Text == "{")) r++;
            if (r >= t.Count) { res.Skipped.Add("could not locate Load() return table"); return; }
            i = r + 2;
            while (!IsOp("}") && Cur.Kind != TK.EOF)
            {
                // [questId] = { [questKeys.x] = expr, ... },
                if (!IsOp("[")) { SkipValue(); Sep(); continue; }
                i++;
                object idv = Eval();
                Expect("]"); Expect("=");
                int qid = idv is double ? (int)(double)idv : -1;
                if (!IsOp("{")) { SkipValue(); Sep(); res.Skipped.Add("quest " + qid + ": non-table correction"); continue; }
                i++;
                LTable q = null;
                if (qid > 0) d.Quests.TryGetValue(qid, out q);
                while (!IsOp("}") && Cur.Kind != TK.EOF)
                {
                    int fieldLine = Cur.Line;
                    if (!IsOp("[")) { SkipValue(); Sep(); continue; }
                    i++;
                    object keyv = Eval();
                    Expect("]"); Expect("=");
                    int save = i;
                    object val = Eval();
                    if (val is Unevaluable)
                    {
                        i = save; SkipValue();
                        res.Skipped.Add("quest " + qid + " field " + KeyName(keyv) + " (line " + fieldLine + "): " + ((Unevaluable)val).Why);
                    }
                    else if (!(keyv is double))
                    {
                        res.Skipped.Add("quest " + qid + " (line " + fieldLine + "): unknown key");
                    }
                    else
                    {
                        if (q == null)
                        {
                            // Correction creates a quest absent from base data; only accept if it carries a name.
                            q = new LTable();
                            d.Quests[qid] = q;
                        }
                        int kn = (int)(double)keyv;
                        if (kn > AddBase) Merge(q, kn % AddBase, val, kn > RemoveBase);
                        else q.Set(keyv, val);
                        res.Applied++;
                    }
                    Sep();
                }
                Expect("}");
                Sep();
            }
            // Remove placeholder quests that never received a name.
            var drop = new List<int>();
            foreach (var kv in d.Quests) if (!(kv.Value.Get(1) is string)) drop.Add(kv.Key);
            foreach (var k in drop) { d.Quests.Remove(k); res.Skipped.Add("quest " + k + ": correction-only record without a name dropped"); }
        }

        const int AddBase = 1000, RemoveBase = 2000;

        static string KeyName(object k)
        {
            if (k is double) { int n = (int)(double)k % AddBase; if (n > 0 && n < QuestKeyNames.Length) return QuestKeyNames[n]; }
            return "?";
        }

        // field_add / field_remove: QuestieDB merges these into the current value instead of replacing it. A
        // value is either a list of ids/rows, or a table of lists ({npcs, objects, items} for startedBy and
        // finishedBy); each list is merged position by position.
        static void Merge(LTable q, int field, object val, bool remove)
        {
            var cur = q.Get(field) as LTable;
            var add = val as LTable;
            if (add == null) return;
            if (cur == null) { if (!remove) q.Set((double)field, add); return; }
            bool nested = false;
            for (int k = 1; k <= add.Count; k++) if (add.Get(k) is LTable && cur.Get(k) is LTable) nested = true;
            if (nested || (add.Count > 0 && (add.Get(1) == null || add.Get(1) is LTable) && !(cur.Get(1) is double)))
            {
                for (int k = 1; k <= Math.Max(add.Count, cur.Count); k++)
                {
                    var a = add.Get(k) as LTable;
                    if (a == null) continue;
                    var c = cur.Get(k) as LTable;
                    if (c == null) { if (!remove) cur.Set((double)k, a); continue; }
                    MergeList(c, a, remove);
                }
            }
            else MergeList(cur, add, remove);
        }

        static void MergeList(LTable cur, LTable add, bool remove)
        {
            var have = new List<object>();
            for (int k = 1; k <= cur.Count; k++) have.Add(cur.Get(k));
            for (int k = 1; k <= add.Count; k++)
            {
                object v = add.Get(k);
                int at = have.FindIndex(x => x != null && v != null && x.Equals(v));
                if (remove) { if (at >= 0) have.RemoveAt(at); }
                else if (at < 0 || !(v is double)) have.Add(v);
            }
            for (int k = cur.Count; k >= 1; k--) cur.Arr.RemoveAt(k);
            foreach (var v in have) cur.Append(v);
        }

        void Sep() { if (IsOp(",") || IsOp(";")) i++; }
        void Expect(string s)
        {
            if (!IsOp(s)) throw new LuaSyntaxError("corrections: expected '" + s + "' near '" + Cur.Text + "'", Cur.Line);
            i++;
        }

        // Skips one expression (balanced brackets), used after an unevaluable value.
        void SkipValue()
        {
            int depth = 0;
            while (Cur.Kind != TK.EOF)
            {
                if (IsOp("{") || IsOp("(") || IsOp("[")) depth++;
                else if (IsOp("}") || IsOp(")") || IsOp("]"))
                {
                    if (depth == 0) return;
                    depth--;
                }
                else if (depth == 0 && (IsOp(",") || IsOp(";"))) return;
                i++;
            }
        }

        object Eval()
        {
            object left = Primary();
            while (IsOp("+") || IsOp("-") || IsOp("and") || IsOp("or") || IsOp("==") || IsOp(".."))
            {
                string op = Cur.Text; i++;
                object right = Primary();
                if (left is Unevaluable) continue;
                if (right is Unevaluable) { left = right; continue; }
                if ((op == "+" || op == "-") && left is double && right is double)
                    left = op == "+" ? (double)left + (double)right : (double)left - (double)right;
                else if (op == ".." && left is string && right is string)
                    left = (string)left + (string)right;
                else
                    left = new Unevaluable("runtime-dependent '" + op + "' expression");
            }
            return left;
        }

        object Primary()
        {
            var tok = Cur;
            if (tok.Kind == TK.Number)
            {
                i++;
                string s = tok.Text;
                if (s.StartsWith("0x") || s.StartsWith("0X")) return (double)Convert.ToInt64(s.Substring(2), 16);
                return double.Parse(s, NumberStyles.Float, CultureInfo.InvariantCulture);
            }
            if (tok.Kind == TK.String) { i++; return Unescape(tok.Text); }
            if (IsOp("-")) { i++; object v = Primary(); return v is double ? (object)(-(double)v) : new Unevaluable("unary minus on non-number"); }
            if (IsOp("nil")) { i++; return null; }
            if (IsOp("true")) { i++; return true; }
            if (IsOp("false")) { i++; return false; }
            if (IsOp("not")) { i++; Primary(); return new Unevaluable("boolean logic"); }
            if (IsOp("{")) return TableCons();
            if (IsOp("("))
            {
                i++; object v = Eval(); Expect(")");
                if (IsOp("[")) { i++; Eval(); Expect("]"); return new Unevaluable("indexed lookup (class/race dependent)"); }
                return v;
            }
            if (tok.Kind == TK.Name)
            {
                i++;
                var path = new List<string> { tok.Text };
                while (IsOp(".") || IsOp(":")) { i++; path.Add(Cur.Text); i++; }
                if (IsOp("(") || Cur.Kind == TK.String)
                {
                    // function call
                    var args = new List<object>();
                    if (Cur.Kind == TK.String) { args.Add(Unescape(Cur.Text)); i++; }
                    else
                    {
                        i++;
                        while (!IsOp(")") && Cur.Kind != TK.EOF) { args.Add(Eval()); Sep(); }
                        Expect(")");
                    }
                    if (path.Count == 1 && path[0] == "l10n" && args.Count == 1 && args[0] is string) return args[0];
                    return new Unevaluable("call to " + string.Join(".", path.ToArray()));
                }
                if (path.Count == 2)
                {
                    Dictionary<string, double> e;
                    double v;
                    if (enums.TryGetValue(path[0], out e) && e.TryGetValue(path[1], out v)) return v;
                }
                return new Unevaluable("unknown symbol " + string.Join(".", path.ToArray()));
            }
            i++;
            return new Unevaluable("unexpected token " + tok.Text);
        }

        object TableCons()
        {
            Expect("{");
            var tbl = new LTable();
            Unevaluable bad = null;
            while (!IsOp("}") && Cur.Kind != TK.EOF)
            {
                if (IsOp("["))
                {
                    i++; object k = Eval(); Expect("]"); Expect("=");
                    object v = Eval();
                    if (k is Unevaluable) bad = (Unevaluable)k;
                    else if (v is Unevaluable) bad = (Unevaluable)v;
                    else if (k != null) tbl.Set(k, v);
                }
                else if (Cur.Kind == TK.Name && t[i + 1].Text == "=" && t[i + 1].Kind == TK.Op)
                {
                    string k = Cur.Text; i += 2;
                    object v = Eval();
                    if (v is Unevaluable) bad = (Unevaluable)v; else tbl.Set(k, v);
                }
                else
                {
                    object v = Eval();
                    if (v is Unevaluable) bad = (Unevaluable)v; else tbl.Append(v);
                }
                Sep();
            }
            Expect("}");
            return bad != null ? (object)bad : tbl;
        }

        static string Unescape(string s)
        {
            if (s.IndexOf('\\') < 0) return s;
            var sb = new StringBuilder();
            for (int k = 0; k < s.Length; k++)
            {
                char c = s[k];
                if (c != '\\' || k + 1 >= s.Length) { sb.Append(c); continue; }
                char e = s[++k];
                switch (e)
                {
                    case 'n': sb.Append('\n'); break;
                    case 't': sb.Append('\t'); break;
                    case '"': sb.Append('"'); break;
                    case '\'': sb.Append('\''); break;
                    case '\\': sb.Append('\\'); break;
                    default: sb.Append(e); break;
                }
            }
            return sb.ToString();
        }
    }
}
