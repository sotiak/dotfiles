local wezterm = require("wezterm")
local utils = require("utils")
local config = wezterm.config_builder()

config.ssh_domains = wezterm.default_ssh_domains()
config.launch_menu = {}

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  return utils.format_tab_title(wezterm, tab, max_width)
end)

-- GUIの見た目
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.95
config.tab_bar_at_bottom = true
config.tab_max_width = 25

-- 起動時のウィンドウサイズ
config.initial_rows = 32
config.initial_cols = 100

-- スクロールバー用の余白
config.window_padding = { right = 10, top = 0, bottom = 0 }

-- スクロールバーの見た目
config.enable_scroll_bar = true
config.colors = { scrollbar_thumb = "Gray" }

-- カーソル色を反転
config.force_reverse_video_cursor = true
config.font = wezterm.font_with_fallback({ "Noto Sans Mono", "BIZ UDGothic", "Symbols Nerd Font Mono" })

-- 非アクティブペインの見た目
config.inactive_pane_hsb = {
  saturation = 0.5,
  brightness = 0.8,
}

-- Application settings
config.use_ime = true
config.audible_bell = "Disabled"
config.check_for_updates = false
config.adjust_window_size_when_changing_font_size = false

-- キーバインド
config.keys = {
  -- テキストコピー
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("ClipboardAndPrimarySelection") },
  -- ランチャー
  { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ShowLauncherArgs({ flags = "DOMAINS|LAUNCH_MENU_ITEMS" }) },
}

config.mouse_bindings = {
  -- 右クリックでカーソル下のリンクを開く
  { event = { Up = { streak = 1, button = "Right" } }, action = wezterm.action.OpenLinkAtMouseCursor },

  -- Ctrl+クリックのDownイベントによる誤動作を防ぐ
  { event = { Down = { streak = 1, button = "Left" } }, mods = "CTRL", action = wezterm.action.Nop },

  -- 左クリックだけでリンクを開かない
  { event = { Up = { streak = 1, button = "Left" } }, mods = "", action = wezterm.action.Nop },
}

-- OSごとに設定を切り替える
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.initial_rows = 42
  config.initial_cols = 120
  config.font_size = 13
  config.window_background_opacity = 1
  config.win32_system_backdrop = "Acrylic"

  config.wsl_domains = wezterm.default_wsl_domains()
  config.default_prog = { "pwsh.exe", "-NoLogo" }
  table.insert(config.launch_menu, {
    label = "PowerShell 7",
    args = { "pwsh.exe", "-NoLogo" },
    domain = { DomainName = "local" },
  })
  for _, dom in ipairs(config.wsl_domains) do
    table.insert(config.launch_menu, {
      label = dom.distribution,
      domain = { DomainName = dom.name },
    })
  end
elseif wezterm.target_triple == "x86_64-apple-darwin" then
  config.font_size = 14
  -- macOSで透明度を安定させるための回避策: https://github.com/wez/wezterm/issues/2669
  config.window_background_opacity = 0.9999
  -- スクロールバー幅
  config.window_padding.right = 16
  config.default_prog = { "zsh", "--login" }
else
  config.font_size = 12
  config.enable_wayland = false
  config.window_decorations = "TITLE | RESIZE"
  config.default_prog = { "zsh", "--login" }
end

return config
