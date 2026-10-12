# fish_variables is gitignored, so fisher's state (_fisher_plugins) doesn't travel
# with the repo even though plugins/ and fish_plugins do. Seed it from fish_plugins
# so `fisher list` works after a clone/pull and `fisher update` sees the vendored
# plugins as updates instead of conflicting installs.
set --local fish_plugins $__fish_config_dir/fish_plugins
test -e $fish_plugins || exit

for plugin in (string match --regex -- '^[^\s]+$' <$fish_plugins | string replace -- \~ ~)
    set plugin (test -e "$plugin" && realpath $plugin || string lower -- $plugin)
    contains -- $plugin $_fisher_plugins || set --universal --append _fisher_plugins $plugin
end
