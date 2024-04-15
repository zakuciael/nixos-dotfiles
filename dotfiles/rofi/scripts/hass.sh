#!/usr/bin/env bash
set -x

ENTITY_FILTER='.[] | select(.entity_id | test("^(switch|light)\\..+$"))'
JSON=$(hass-cli -o json state list 2>/dev/null)
IDX=$(jq -r "${ENTITY_FILTER} | .attributes?.friendly_name?" <<< "$JSON" | rofi -theme "$HOME/.config/rofi/launchers/style.rasi" -dmenu -i -markup-rows -format d)
ITEM=$(jq -r "${ENTITY_FILTER} | .entity_id" <<< "$JSON" | sed "${IDX}q;d")
ITEM_TYPE=$(sed -r 's/\..+$//' <<< "$ITEM")

case "$ITEM_TYPE" in
    light|switch)
        hass-cli state toggle "$ITEM" &>/dev/null
        ;;
    scene)
        hass-cli service call --arguments entity_id="$ITEM" scene.turn_on &>/dev/null
        ;;
    *)
        notify-send "Error" "Event type '$ITEM_TYPE' not implemented yet." 
        ;;
esac
