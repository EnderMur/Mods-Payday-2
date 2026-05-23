Hooks:PostHook(BlackMarketGui, "create_steam_inventory", "post_steam_inventory_creation", function(self)
    managers.network.account._inventory_loaded = false
    managers.network.account:inventory_load()
    --log("in inventory, setting inventory load to false.")
end)