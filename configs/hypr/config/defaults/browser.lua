-- Browser: brave (manual launch via SUPER+I)
-- No auto-start on login

hl.window_rule({
    match = { class = "brave-browser" },
    workspace = "2 silent",
})
