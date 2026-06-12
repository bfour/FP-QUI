use crate::notification::NotificationSpec;

/// Parses a `--notify <json>` / `--notify=<json>` argument into a
/// NotificationSpec. This is the entry point used both for the initial
/// process launch and for follow-up invocations forwarded by the
/// single-instance plugin, replacing the named-pipe based IPC that
/// fpquisend/fpquitip used to talk to the running FP-QUI instance.
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
    }
    None
}
