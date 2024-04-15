{pkgs, ...}:
pkgs.writeShellApplication {
  name = "rofi-powermenu";
  runtimeInputs = with pkgs; [rofi-wayland toybox mpc-cli alsa-utils bspwm];
  text = ''
    # CMDs
    uptime=$(${pkgs.toybox}/bin/uptime -p | sed -e 's/up //g')

    # Options
    shutdown=''
    reboot=''
    lock=''
    suspend=''
    logout=''
    yes=''
    no=''

    # Rofi CMD
    rofi_cmd() {
      rofi -dmenu \
        -p "Uptime: $uptime" \
        -mesg "Uptime: $uptime" \
        -theme "$HOME/.config/rofi/powermenu/style.rasi"
    }

    # Confirmation CMD
    confirm_cmd() {
      rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
        -theme-str 'mainbox {children: [ "message", "listview" ];}' \
        -theme-str 'listview {columns: 2; lines: 1;}' \
        -theme-str 'element-text {horizontal-align: 0.5;}' \
        -theme-str 'textbox {horizontal-align: 0.5;}' \
        -dmenu \
        -p 'Confirmation' \
        -mesg 'Are you Sure?' \
        -theme "$HOME/.config/rofi/powermenu/style.rasi"
    }

    # Ask for confirmation
    confirm_exit() {
      echo -e "$yes\n$no" | confirm_cmd
    }

    # Pass variables to rofi dmenu
    run_rofi() {
      echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
    }

    # Execute Command
    run_cmd() {
      selected="$(confirm_exit)"
      if [[ "$selected" == "$yes" ]]; then
        if [[ $1 == '--shutdown' ]]; then
          ${pkgs.systemd}/bin/systemctl poweroff
        elif [[ $1 == '--reboot' ]]; then
          ${pkgs.systemd}/bin/systemctl reboot
        elif [[ $1 == '--suspend' ]]; then
          ${pkgs.mpc-cli}/bin/mpc -q pause
          ${pkgs.alsa-utils}/bin/amixer set Master mute
          ${pkgs.systemd}/bin/systemctl suspend
        elif [[ $1 == '--logout' ]]; then
          if [[ "$DESKTOP_SESSION" == 'bspwm' ]]; then
            bspc quit
          fi
        fi
      else
        exit 0
      fi
    }

    # Actions
    chosen="$(run_rofi)"
    case "$chosen" in
        "$shutdown")
        run_cmd --shutdown
            ;;
        "$reboot")
        run_cmd --reboot
            ;;
        "$lock")
        if [[ -x '/usr/bin/betterlockscreen' ]]; then
          betterlockscreen -l
        elif [[ -x '/usr/bin/i3lock' ]]; then
          i3lock
        fi
            ;;
        "$suspend")
        run_cmd --suspend
            ;;
        "$logout")
        run_cmd --logout
            ;;
    esac
  '';
}
