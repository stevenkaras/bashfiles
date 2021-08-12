
-- Configuration hot reload
hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

-- just keeping this here as an example. do not use!!!
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  hs.notify.new({title="Hammerspoon", informativeText="Hello World"}):send()
end)

