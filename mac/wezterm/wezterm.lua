local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Appearance
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font 'FantasqueSansM Nerd Font Mono'
config.font_size = 15.0
config.window_background_opacity = 0.97
config.macos_window_background_blur = 20
config.window_decorations = 'RESIZE'
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}
config.line_height = 1.75

-- Cursor
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- Scrollback
config.scrollback_lines = 10000

-- Keybindings
config.keys = {
  { key = 'Enter', mods = 'CMD', action = wezterm.action.ToggleFullScreen },
}

return config
