require("mod-gui")
local Event = require("__stdlib__/stdlib/event/event")

local function player_upgrade(player, belt, upgrade, bool)
  if not belt then
    return
  end
  local target_name = upgrade.name
  if not target_name then
    log("Tried to upgrade when entry had no entity: " .. serpent.line(upgrade))
    return
  end
  local surface = player.surface
  local amount = 1
  if player.get_item_count(target_name) >= amount or player.cheat_mode then
    local d = belt.direction
    local f = belt.force
    local p = belt.position
    local new_item
    script.raise_event(defines.events.on_pre_player_mined_item, {player_index = player.index, entity = belt})
    local props = {
      name = target_name,
      position = belt.position,
      force = belt.force,
      fast_replace = true,
      direction = belt.direction,
      player = player,
      spill = false
    }
    if belt.type == "underground-belt" then
      if belt.neighbours and bool then
        player_upgrade(player, belt.neighbours, upgrade, false)
      end
      props.type = belt.belt_to_ground_type
      player.print(belt.prototype.max_underground_distance)
      new_item = surface.create_entity(props)
    elseif belt.type == "loader" then
      props.type = belt.loader_type
      new_item = surface.create_entity(props)
    elseif belt.type == "inserter" then
      local drop = {x = belt.drop_position.x, y = belt.drop_position.y}
      local pickup = {x = belt.pickup_position.x, y = belt.pickup_position.y}
      new_item = surface.create_entity(props)
      if new_item.valid then
        new_item.pickup_position = pickup
        new_item.drop_position = drop
      end
    elseif belt.type == "straight-rail" or belt.type == "curved-rail" then
      belt.destroy()
      new_item =
        surface.create_entity {
        name = target_name,
        position = p,
        force = f,
        direction = d
      }
    else
      new_item = surface.create_entity(props)
    end
    if belt.valid then
      --If the create entity fast replace didn't work, we use this blueprint technique
      if new_item and new_item.valid then
        new_item.destroy()
      end
      local a = belt.bounding_box
      player.cursor_stack.set_stack {name = "blueprint", count = 1}
      player.cursor_stack.create_blueprint {surface = surface, force = belt.force, area = a}
      local old_blueprint = player.cursor_stack.get_blueprint_entities()
      local record_index = nil
      for index, entity in pairs(old_blueprint) do
        if (entity.name == belt.name) then
          record_index = index
        else
          old_blueprint[index] = nil
        end
      end
      if record_index == nil then
        player.print("Blueprint index error line " .. debug.getinfo(1).currentline)
        return
      end
      old_blueprint[record_index].name = target_name
      old_blueprint[record_index].position = p
      player.cursor_stack.set_stack {name = "blueprint", count = 1}
      player.cursor_stack.set_blueprint_entities({old_blueprint[record_index]})
      if not player.cheat_mode then
        player.insert {name = belt.name, count = amount}
      end
      script.raise_event(
        defines.events.on_player_mined_item,
        {
          player_index = player.index,
          item_stack = {
            name = belt.name,
            count = amount
          }
        }
      )
      --And then copy the inventory to some table
      local inventories = {}
      for index = 1, 10 do
        if belt.get_inventory(index) ~= nil then
          inventories[index] = {}
          inventories[index].name = index
          inventories[index].contents = belt.get_inventory(index).get_contents()
        end
      end
      belt.destroy()
      player.cursor_stack.build_blueprint {surface = surface, force = f, position = {0, 0}}
      local ghost = surface.find_entities_filtered {area = a, name = "entity-ghost"}
      player.remove_item {name = belt.name, count = amount}
      local p_x = player.position.x
      local p_y = player.position.y
      while ghost[1] ~= nil do
        ghost[1].revive()
        player.teleport({math.random(p_x - 5, p_x + 5), math.random(p_y - 5, p_y + 5)})
        ghost = surface.find_entities_filtered {area = a, name = "entity-ghost"}
      end
      player.teleport({p_x, p_y})
      local assembling = surface.find_entities_filtered {area = a, name = target_name}[1]
      if not assembling then
        player.print("Upgrade planner error - Entity to raise was not found")
        player.cursor_stack.set_stack {name = "upgrade-builder", count = 1}
        player.insert {name = belt.name, count = amount}
        return
      end
      script.raise_event(defines.events.on_built_entity, {player_index = player.index, created_entity = assembling})
      --Give back the inventory to the new entity
      for j, items in pairs(inventories) do
        for l, contents in pairs(items.contents) do
          if assembling ~= nil then
            local inv = assembling.get_inventory(items.name)
            if inv then
              inv.insert {name = l, count = contents}
            end
          end
        end
      end
      local proxy = surface.find_entities_filtered {area = a, name = "item-request-proxy"}
      if proxy[1] ~= nil then
        proxy[1].destroy()
      end
      player.cursor_stack.set_stack {name = "upgrade-builder", count = 1}
    else
      player.remove_item {name = target_name, count = amount}
      --player.insert{name = upgrade.item_from, count = amount}
      script.raise_event(
        defines.events.on_player_mined_item,
        {player_index = player.index, item_stack = {name = target_name, count = 1}}
      )
      script.raise_event(
        defines.events.on_built_entity,
        {player_index = player.index, created_entity = new_item, stack = player.cursor_stack}
      )
    end
  else
    belt.cancel_upgrade(player.force)
    for key, value in pairs(global.timeouts) do
      if value < game.tick then
        global.timeouts[key] = nil
      end
    end
    if not global.timeouts[target_name] then
      global.timeouts[target_name] = game.tick + defines.time.second * 2
      surface.create_entity {
        name = "flying-text",
        position = {belt.position.x - 1.3, belt.position.y - 0.5},
        text = "Insufficient items",
        color = {r = 1, g = 0.6, b = 0.6}
      }
    end
    rendering.draw_circle {
      color = {r = 0.8, a = 0.3},
      radius = 0.5,
      width = 3,
      filled = false,
      target = belt,
      surface = player.surface,
      players = {player},
      time_to_live = defines.time.second * 3
    }
  end
end

Event.register(
  Event.core_events.init,
  function()
    global.timeouts = {}
  end
)

Event.register(
  defines.events.on_marked_for_upgrade,
  function(event)
    local player = game.players[event.player_index]
    player_upgrade(player, event.entity, event.target, true)
  end,
  function(event)
    local player = game.players[event.player_index]
    return player.is_shortcut_toggled("toggle-instant-upgrade")
  end
)

Event.register(
  defines.events.on_lua_shortcut,
  function(event)
    local player = game.players[event.player_index]
    local sc = event.prototype_name
    player.set_shortcut_toggled(sc, not player.is_shortcut_toggled(sc))
  end,
  function(event)
    return event.prototype_name == "toggle-instant-upgrade"
  end
)
