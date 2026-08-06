-- MONITOR CONFIG
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})

hl.gesture({
  fingers = 3,
  direction = "swipe",
  action = "move",
})
hl.gesture({
  fingers = 3,
  direction = "pinch",
  action = "fullscreen",
})
hl.gesture({
  fingers = 4,
  direction = "horizontal",
  action = "workspace",
})
hl.gesture({
  fingers = 4,
  direction = "up",
  action = function()
    hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
  end,
})
hl.gesture({
  fingers = 4,
  direction = "down",
  action = function()
    hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
  end,
})

hl.config({
  gestures = {
    workspace_swipe_distance = 700,
    workspace_swipe_cancel_ratio = 0.2,
    workspace_swipe_min_speed_to_force = 5,
    workspace_swipe_direction_lock = true,
    workspace_swipe_direction_lock_threshold = 10,
    workspace_swipe_create_new = true,
  },

  general = {
    gaps_workspaces = 50,

    border_size = 1,

    col = {
      active_border = "rgba(0DB7D455)",
      inactive_border = "rgba(31313600)",
    },

    resize_on_border = true,
    extend_border_grab_area = 10,
    hover_icon_on_border = false,

    no_focus_fallback = true,
    allow_tearing = true, -- This just allows the `immediate` window rule to work
    snap = {
      enabled = true,
      window_gap = 4,
      monitor_gap = 5,
      respect_gaps = true,
    },
  },
  decoration = {
    rounding_power = 8,
    rounding = 18,

    blur = {
      enabled = false,
      xray = true,
      special = false,
      new_optimizations = true,
      size = 10,
      passes = 3,
      brightness = 1,
      noise = 0.05,
      contrast = 0.89,
      vibrancy = 0.5,
      vibrancy_darkness = 0.5,
      popups = false,
      popups_ignorealpha = 0.6,
      input_methods = true,
      input_methods_ignorealpha = 0.8,
    },
    shadow = {
      enabled = true,
      range = 40,
      offset = { 0, 0 },
      render_power = 2,
      color = "rgba(00000040)",
    },
    -- Dim
    dim_inactive = true,
    dim_strength = 0.25,
    dim_special = 0.2,
  },
  render = {
    new_render_scheduling = true,
  },
  ecosystem = {
    no_donation_nag = true,
    no_update_news = true,
  },
  animations = {
    enabled = true,
  },
  dwindle = {
    preserve_split = true,
    smart_split = true,
    smart_resizing = true,
    precise_mouse_move = true,
  },
})
hl.config({
  input = {
    kb_layout = "us",
    kb_options = "grp:alt_shift_toggle",
    numlock_by_default = true,
    repeat_delay = 250,
    repeat_rate = 35,

    follow_mouse = 1,
    off_window_axis_events = 2,

    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      clickfinger_behavior = true,
      scroll_factor = 0.7,
    },
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vrr = 0,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
    animate_manual_resizes = true,
    animate_mouse_windowdragging = true,
    enable_swallow = false,
    swallow_regex = "(foot|kitty|allacritty|Alacritty)",
    on_focus_under_fullscreen = 2,
    allow_session_lock_restore = true,
    session_lock_xray = true,
    initial_workspace_tracking = false,
    focus_on_activate = true,
  },

  binds = {
    scroll_event_delay = 0,
    hide_special_on_workspace_change = true,
  },

  cursor = {
    zoom_factor = 1,
    zoom_rigid = false,
    zoom_disable_aa = true,
    hotspot_padding = 1,
  },

  xwayland = {
    force_zero_scaling = true,
  },
})
