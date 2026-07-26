#!/usr/bin/env python3
"""Подставляет path-scoped правила проекта в контекст агента.

Зачем. Раньше правила складывали в `.claude/rules/*.md` с `paths:` во фронтматтере и
считали, что рантайм подхватит их сам. Он не подхватывает: `CLAUDE.md` импортирует только
корневой канон, нативной автозагрузки каталога правил нет. В итоге правила читались лишь
тогда, когда агент сам решал открыть файл, то есть случайно.

Этот гейт делает обещанное по-настоящему: на PreToolUse смотрит, какой файл сейчас будет
изменён, матчит путь против `paths:` каждого правила и отдаёт тело подходящего правила через
`additionalContext`. Одно правило на сессию отдаётся один раз, иначе каждая правка жгла бы
токены повторной вставкой.

Контракт одинаков для всех рантаймов: JSON со stdin, JSON в stdout, `exit 0`.
Гейт никогда не блокирует работу: он только добавляет контекст.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import tempfile
from pathlib import Path

MARKER_DIR = Path(tempfile.gettempdir()) / "harness-rules-injected"


def glob_to_regex(pattern: str) -> re.Pattern[str]:
    """Переводит glob в регулярку. `**` пересекает разделители, `*` и `?` нет.

    Собственная реализация вместо fnmatch: fnmatch не различает `*` и `**`, из-за чего
    правило для `frontend/src/**` цепляло бы вообще всё.
    """
    out: list[str] = []
    i, n = 0, len(pattern)
    while i < n:
        ch = pattern[i]
        if ch == "*":
            if pattern.startswith("**", i):
                i += 2
                if pattern.startswith("/", i):
                    i += 1
                    out.append("(?:.*/)?")
                else:
                    out.append(".*")
                continue
            out.append("[^/]*")
        elif ch == "?":
            out.append("[^/]")
        elif ch in ".^$+{}[]|()\\":
            out.append("\\" + ch)
        else:
            out.append(ch)
        i += 1
    return re.compile("^" + "".join(out) + "$")


def matches(glob: str, rel_path: str) -> bool:
    """Матчит glob против пути репозитория.

    Паттерн без слеша сверяется ещё и с именем файла: `*.tsx` означает «любой .tsx»,
    как в gitignore, а не «.tsx в корне». Паттерн со слешем матчится строго по пути.
    """
    rx = glob_to_regex(glob)
    if rx.match(rel_path):
        return True
    if "/" not in glob:
        return bool(rx.match(os.path.basename(rel_path)))
    return False


def parse_rule(path: Path) -> tuple[list[str], str]:
    """Возвращает (globs, тело). Правило без `paths:` считается всегда применимым."""
    text = path.read_text(encoding="utf-8")
    globs: list[str] = []
    body = text
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            front, body = text[3:end], text[end + 4 :]
            # `[^\S\n]*` вместо `\s*`: иначе жадный `\s*` перепрыгивает перевод строки
            # и втягивает первый элемент многострочного YAML-списка вместе с дефисом.
            m = re.search(r"^paths:[^\S\n]*(\S.*)$", front, re.MULTILINE)
            if m:
                raw = m.group(1).strip()
                if raw.startswith("["):
                    globs = re.findall(r'["\']([^"\']+)["\']', raw)
                else:
                    globs = [raw.strip("\"'")]
            # Многострочный YAML-список: `paths:` и ниже строки с дефисом
            if not globs and re.search(r"^paths:[^\S\n]*$", front, re.MULTILINE):
                tail = front.split("paths:", 1)[1]
                for line in tail.splitlines():
                    m2 = re.match(r'\s*-\s*["\']?([^"\'\s]+)["\']?\s*$', line)
                    if m2:
                        globs.append(m2.group(1))
                    elif line.strip() and not line.startswith(" "):
                        break
    return globs, body.strip()


def target_paths(payload: dict) -> list[str]:
    """Пути, которых касается вызов. Для Bash разбираем команду грубо, но полезно."""
    ti = payload.get("tool_input") or {}
    found = []
    for key in ("file_path", "path", "notebook_path"):
        if ti.get(key):
            found.append(str(ti[key]))
    for edit in ti.get("edits") or []:
        if isinstance(edit, dict) and edit.get("file_path"):
            found.append(str(edit["file_path"]))
    return found


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    repo = os.environ.get("CLAUDE_PROJECT_DIR") or payload.get("cwd") or os.getcwd()
    rules_dir = Path(repo) / ".harness" / "rules"
    if not rules_dir.is_dir():
        return 0

    paths = target_paths(payload)
    if not paths:
        return 0

    rel_paths = []
    for p in paths:
        try:
            rel_paths.append(str(Path(p).resolve().relative_to(Path(repo).resolve())))
        except (ValueError, OSError):
            rel_paths.append(p)

    session = str(payload.get("session_id") or "nosession")
    MARKER_DIR.mkdir(parents=True, exist_ok=True)

    chunks: list[str] = []
    for rule in sorted(rules_dir.glob("*.md")):
        try:
            globs, body = parse_rule(rule)
        except Exception:
            continue
        if not body:
            continue
        if globs:
            if not any(
                matches(glob, rel) for rel in rel_paths for glob in globs
            ):
                continue

        key = hashlib.sha256(f"{session}:{repo}:{rule.name}".encode()).hexdigest()[:24]
        marker = MARKER_DIR / key
        if marker.exists():
            continue
        marker.write_text("", encoding="utf-8")
        chunks.append(f"### Правило проекта: {rule.stem}\n\n{body}")

    if not chunks:
        return 0

    context = (
        "Правила этого проекта, относящиеся к файлу, который ты сейчас правишь. "
        "Они перекрывают глобальные умолчания.\n\n" + "\n\n---\n\n".join(chunks)
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "additionalContext": context,
            }
        },
        sys.stdout,
        ensure_ascii=False,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
