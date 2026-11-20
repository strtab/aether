HOME = os.getenv("HOME")

function is_file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then
      io.close(f)
      return true
   else
      return false
   end
end

function create_if_not_exists(path)
   if not is_file_exists(path) then
      os.execute("mkdir -p \"$(dirname \"" .. path .. "\")\"")
      os.execute("echo '-- This file will not be overwritten across dots-hyprland updates.\n-- The file name is for the sake of organization and does not matter\n-- See the corresponding files in ~/.config/hypr/hyprland for examples' > \"" .. path .. "\"")
      return true
   end
   return false
end

function workspace_in_group(i)
    local curr = hl.get_active_workspace().id
    local newVal = math.floor((curr - 1) / WorkspaceGroupSize) * WorkspaceGroupSize + i
    -- hl.notification.create({ text = "curr " .. curr .. " floor " .. math.floor(curr / 10) .. " new " .. newVal, duration = 5000 })
    return newVal
end

local function shell_quote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

function exec_tray_cmd(cmd, timeout)
  if type(cmd) ~= "string" or cmd == "" then
    return
  end

  local limit = tonumber(timeout) or 15
  if limit < 0 then
    limit = 0
  end

  local wait_script = string.format(
    "deadline=$((SECONDS + %d)); " ..
    "while (( SECONDS < deadline )); do " ..
      "if busctl --user list --no-legend 2>/dev/null | grep -qE '^org\\.kde\\.StatusNotifierHost'; then " ..
        "break; " ..
      "fi; " ..
      "sleep 0.25; " ..
    "done; " ..
    "exec sh -c %s",
    math.floor(limit),
    shell_quote(cmd)
  )

  hl.exec_cmd(wait_script)
end
