{pkgs, ...}: {
  package = pkgs.writeShellApplication {
    name = "elgato-mic-fix";
    runtimeInputs = with pkgs; [jq pulseaudio];
    text = ''
      SINK_NAME=$(pactl -f json list sinks | jq --raw-output '.[] | select(.properties."alsa.card_name" == "Elgato Wave:3") | .name')
      SOURCE_NAME=$(pactl -f json list sources | jq --raw-output '.[] | select(.properties."alsa.card_name" == "Elgato Wave:3" and .monitor_source == "") | .name')
      CARD_NAME=$(pactl -f json list cards | jq --raw-output '.[] | select(.properties."api.alsa.card.name" == "Elgato Wave:3") | .name')

      pactl set-source-mute "$SOURCE_NAME" false
      pactl set-card-profile "$CARD_NAME" "output:analog-stereo+input:mono-fallback"
      pactl suspend-sink "$SINK_NAME" true
      pactl suspend-sink "$SINK_NAME" false
    '';
  };
  export = true;
}
