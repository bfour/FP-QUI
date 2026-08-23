use crate::legacy;
use crate::notification::NotificationSpec;

/// Parses a `--notify <json>` / `--notify=<json>` or `--notify-legacy <tags>`
/// / `--notify-legacy=<tags>` argument into a NotificationSpec. This is the
/// entry point used both for the initial process launch and for follow-up
/// invocations forwarded by the single-instance plugin, replacing the
/// named-pipe based IPC that fpquisend/fpquitip used to talk to the running
/// FP-QUI instance.
///
/// `--notify-legacy` accepts the old FP-QUI tag notation (e.g.
/// `<text>Hello</text><bkColor>purple</bkColor>`), for existing integrations
/// that haven't been updated to send JSON.
pub fn parse_notify_arg(args: &[String]) -> Option<NotificationSpec> {
    let mut iter = args.iter();
    while let Some(arg) = iter.next() {
        if arg == "--notify" {
            let json = iter.next()?;
            return serde_json::from_str(json).ok();
        }
        if let Some(json) = arg.strip_prefix("--notify=") {
            return serde_json::from_str(json).ok();
        }
        if arg == "--notify-legacy" {
            let tags = iter.next()?;
            return Some(legacy::parse(tags));
        }
        if let Some(tags) = arg.strip_prefix("--notify-legacy=") {
            return Some(legacy::parse(tags));
        }
    }
    None
}
