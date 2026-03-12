hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "S", function()
  toggle_application("Spotify")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "T", function()
  toggle_application("Trello")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "O", function()
  toggle_application("Microsoft Outlook")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "P", function()
  toggle_application("PyCharm")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "w", function()
  toggle_application("Webstorm")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "5", function()
  toggle_application("Notes")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "M", function()
  toggle_application("Mail")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "4", function()
  toggle_application("WhatsApp")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "1", function()
  toggle_application("Ghostty")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "2", function()
  toggle_application("Google Chrome")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "3", function()
	-- toggle_application("Slack")
	toggle_application("Slack")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "D", function()
  toggle_application("DataGrip")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "G", function()
  toggle_application("GoLand")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "C", function()
  hs.urlevent.openURL("https://console.cloud.google.com/home/dashboard?authuser=0&project=sqnc-wrkld-ugc-monitoring&supportedpurview=project")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "F", function()
  toggle_application("Finder")
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "-", function()
	device = hs.audiodevice.defaultOutputDevice()
	muted = device:muted()
	device:setMuted(not muted)
end)

hs.hotkey.bind({"cmd", "alt",  "ctrl"}, "0", function()
	hs.caffeinate.systemSleep()
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)

function toggle_application(name)
  local app = hs.application.get(name)
  if not app then
    print("Launching app " .. name)
    hs.application.launchOrFocus(name)
    return
  end

  local frontmost = hs.application.frontmostApplication()
  local is_frontmost = frontmost and frontmost:name() == name

  if app:isHidden() or not is_frontmost then
    print("Focusing app " .. name)
    hs.application.launchOrFocus(name)
    app = hs.application.get(name)
    if app then
      app:activate(true)
    end
  else
    print("Hiding app " .. name)
    app:hide()
  end
end

hs.alert.show("Config loaded")
