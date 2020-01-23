data:extend({
  {
    type = 'shortcut',
    name = 'toggle-instant-upgrade',
    toggleable = true,
    order = 'a[alt-mode]-b[copy]',
    action = 'lua',
    localised_name = {'shortcut.instant-upgrade'},
    icon =
    {
      filename = "__upgrade-planner-instant__/graphics/icons/shortcut-bar/shortcut-32.png",
      priority = 'extra-high-no-scale',
      size = 32,
      scale = 1,
      flags = {'icon'}
    },
    small_icon =
    {
      filename = "__upgrade-planner-instant__/graphics/icons/shortcut-bar/shortcut-24.png",
      priority = 'extra-high-no-scale',
      size = 24,
      scale = 1,
      flags = {'icon'}
    },
    disabled_small_icon =
    {
      filename = "__upgrade-planner-instant__/graphics/icons/shortcut-bar/shortcut-24-disabled.png",
      priority = 'extra-high-no-scale',
      size = 24,
      scale = 1,
      flags = {'icon'}
    },
    style = "green"
  }
})

