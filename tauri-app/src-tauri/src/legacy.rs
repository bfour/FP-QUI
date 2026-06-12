use crate::notification::{NotificationButton, NotificationSpec};

/// Parses the legacy FP-QUI "tag" notation, e.g.
/// `<text>Hello</text><bkColor>purple</bkColor><delay>5000</delay>`,
/// into a NotificationSpec. This is the same nesting-aware tag format
/// previously handled by _commandLineInterpreter.au3, kept here so existing
/// integrations (Thunderbird, scripts, etc.) that send this format keep
/// working.
///
/// Only the subset of legacy tags that map onto NotificationSpec is
/// understood; layout/internal-only tags (width, height, x, y, font,
/// dispatcherArea, GUID, ...) are accepted but ignored. AutoIt macros
/// (`@ScriptDir`, `@AutoItPID`, ...) and `%variable%` substitutions are not
/// resolved.
pub fn parse(input: &str) -> NotificationSpec {
    let mut spec = NotificationSpec {
        id: String::new(),
        title: None,
        text: String::new(),
        text_color: None,
        bk_color: None,
        icon: None,
        sound: None,
        talk: None,
        delay_ms: None,
        until_click: false,
        buttons: Vec::new(),
        corner: None,
    };

    for (tag, content) in parse_tags(input) {
        let value = content.trim();
        match tag.as_str() {
            "text" => spec.text = value.to_string(),
            "textColor" => spec.text_color = non_empty(value),
            "bkColor" => spec.bk_color = non_empty(value),
            "ico" => spec.icon = non_empty(value),
            "delay" => spec.delay_ms = value.parse().ok(),
            "untilClick" => spec.until_click = !value.is_empty() && value != "0",
            "talk" => spec.talk = sub_value_or_raw(&content, "string"),
            "audio" => spec.sound = sub_value_or_raw(&content, "path"),
            "button" => spec.buttons = parse_buttons(&content),
            _ => {} // unsupported/internal legacy option, ignored
        }
    }

    spec
}

fn non_empty(value: &str) -> Option<String> {
    if value.is_empty() {
        None
    } else {
        Some(value.to_string())
    }
}

/// `<talk><string>Hi</string><repeat>2</repeat></talk>` -> "Hi"
/// `<talk>Hi</talk>` (no nested tags, legacy shorthand) -> "Hi"
fn sub_value_or_raw(content: &str, key: &str) -> Option<String> {
    let nested = parse_tags(content);
    if nested.is_empty() {
        non_empty(content.trim())
    } else {
        nested
            .into_iter()
            .find(|(tag, _)| tag == key)
            .map(|(_, value)| value.trim().to_string())
            .filter(|value| !value.is_empty())
    }
}

/// `<button><ID1><label>Help</label><cmd>...</cmd></ID1><ID2>...</ID2></button>`
fn parse_buttons(content: &str) -> Vec<NotificationButton> {
    parse_tags(content)
        .into_iter()
        .filter(|(tag, _)| tag.starts_with("ID"))
        .map(|(_, id_content)| {
            let fields = parse_tags(&id_content);
            let label = fields
                .iter()
                .find(|(tag, _)| tag == "label")
                .map(|(_, value)| value.trim().to_string())
                .unwrap_or_default();
            let cmd = fields
                .iter()
                .find(|(tag, _)| tag == "cmd")
                .map(|(_, value)| value.trim().to_string())
                .unwrap_or_default();

            let mut button = NotificationButton { label, cmd: None, url: None };
            let cmd_tags = parse_tags(&cmd);
            if let Some((_, url)) = cmd_tags.iter().find(|(tag, _)| tag == "shellOpen") {
                button.url = non_empty(url.trim());
            } else if cmd_tags.iter().any(|(tag, _)| tag == "internal") {
                // FP-QUI-internal commands aren't portable; drop them.
            } else {
                button.cmd = non_empty(&cmd);
            }
            button
        })
        .collect()
}

/// Splits `input` into top-level `(tag, content)` pairs, where `content` is
/// everything between a tag's opening and matching closing marker
/// (including any nested tags, verbatim). Text outside of recognized tags is
/// ignored, mirroring _commandLineInterpreter.au3.
fn parse_tags(input: &str) -> Vec<(String, String)> {
    let chars: Vec<char> = input.chars().collect();
    let len = chars.len();
    let mut result = Vec::new();
    let mut i = 0;

    while i < len {
        if chars[i] == '<' {
            if let Some(tag_name) = read_opening_tag_name(&chars, i) {
                let content_start = i + tag_name.len() + 2; // '<' + name + '>'
                if let Some(content_end) = find_matching_close(&chars, content_start, &tag_name) {
                    let content: String = chars[content_start..content_end].iter().collect();
                    let next = content_end + tag_name.len() + 3; // '</' + name + '>'
                    result.push((tag_name, content));
                    i = next;
                    continue;
                }
            }
        }
        i += 1;
    }

    result
}

/// If `chars[start]` begins an opening tag like `<text>`, returns `"text"`.
fn read_opening_tag_name(chars: &[char], start: usize) -> Option<String> {
    let mut j = start + 1;
    if chars.get(j) == Some(&'/') {
        return None;
    }
    let mut name = String::new();
    while let Some(&c) = chars.get(j) {
        if c.is_ascii_alphanumeric() {
            name.push(c);
            j += 1;
        } else {
            break;
        }
    }
    if !name.is_empty() && chars.get(j) == Some(&'>') {
        Some(name)
    } else {
        None
    }
}

/// Finds the index of the `</tag_name>` that closes the tag opened just
/// before `start`, accounting for same-named tags nested inside.
fn find_matching_close(chars: &[char], start: usize, tag_name: &str) -> Option<usize> {
    let open: Vec<char> = format!("<{tag_name}>").chars().collect();
    let close: Vec<char> = format!("</{tag_name}>").chars().collect();
    let mut depth = 1;
    let mut i = start;

    while i < chars.len() {
        if matches_at(chars, i, &close) {
            depth -= 1;
            if depth == 0 {
                return Some(i);
            }
            i += close.len();
        } else if matches_at(chars, i, &open) {
            depth += 1;
            i += open.len();
        } else {
            i += 1;
        }
    }

    None
}

fn matches_at(chars: &[char], pos: usize, pattern: &[char]) -> bool {
    chars.len() >= pos + pattern.len() && chars[pos..pos + pattern.len()] == *pattern
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_simple_fields() {
        let spec = parse("<text>Hello</text><bkColor>purple</bkColor><delay>10000</delay>");
        assert_eq!(spec.text, "Hello");
        assert_eq!(spec.bk_color, Some("purple".to_string()));
        assert_eq!(spec.delay_ms, Some(10000));
    }

    #[test]
    fn until_click_treats_zero_as_false() {
        assert!(!parse("<text>a</text><untilClick>0</untilClick>").until_click);
        assert!(parse("<text>a</text><untilClick>1</untilClick>").until_click);
    }

    #[test]
    fn talk_shorthand_without_nested_tags() {
        let spec = parse("<text>Hi</text><talk>Hi there</talk>");
        assert_eq!(spec.talk, Some("Hi there".to_string()));
    }

    #[test]
    fn talk_with_nested_string_tag() {
        let spec = parse("<text>Hi</text><talk><string>Hi there</string><repeat>2</repeat></talk>");
        assert_eq!(spec.talk, Some("Hi there".to_string()));
    }

    #[test]
    fn parses_buttons_with_shell_open_and_plain_command() {
        let spec = parse(concat!(
            "<text>FP-QUI is running in the background</text>",
            "<bkColor>purple</bkColor>",
            "<button>",
            "<ID1><label>Help</label><cmd><shellOpen>https://example.com/help</shellOpen></cmd></ID1>",
            "<ID2><label>Open log</label><cmd>code build.log</cmd></ID2>",
            "</button>",
            "<untilClick><any>1</any><includeButton>1</includeButton></untilClick>",
        ));

        assert_eq!(spec.text, "FP-QUI is running in the background");
        assert_eq!(spec.bk_color, Some("purple".to_string()));
        assert!(spec.until_click);
        assert_eq!(spec.buttons.len(), 2);

        assert_eq!(spec.buttons[0].label, "Help");
        assert_eq!(spec.buttons[0].url, Some("https://example.com/help".to_string()));
        assert_eq!(spec.buttons[0].cmd, None);

        assert_eq!(spec.buttons[1].label, "Open log");
        assert_eq!(spec.buttons[1].cmd, Some("code build.log".to_string()));
        assert_eq!(spec.buttons[1].url, None);
    }

    #[test]
    fn internal_commands_are_dropped() {
        let spec = parse("<text>x</text><button><ID1><label>Restart</label><cmd><internal>restart</internal></cmd></ID1></button>");
        assert_eq!(spec.buttons[0].cmd, None);
        assert_eq!(spec.buttons[0].url, None);
    }
}
