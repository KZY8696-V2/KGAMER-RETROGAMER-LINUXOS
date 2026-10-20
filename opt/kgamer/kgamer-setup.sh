#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    exit 1
fi

killall emulationstation 2>/dev/null || true
pkill -f emulationstation 2>/dev/null || true

APPS_DIR="/opt/kgamer/apps"
BACKUP_APPS_DIR="/opt/kgamer/backup_apps"

configure_keyboard_layout() {
    KB_CHOICE=$(dialog --clear --title "KGAMER - KEYBOARD LAYOUT SELECTOR" \
        --menu "Select your keyboard layout / country:" 20 60 11 \
        "us" "English (US) - Standard QWERTY" \
        "uk" "English (UK)" \
        "tr" "Turkish (Q / F Choice)" \
        "de" "German (DE - QWERTZ)" \
        "fr" "French (FR - AZERTY)" \
        "es" "Spanish (ES)" \
        "it" "Italian (IT)" \
        "br" "Portuguese (Brazil)" \
        "jp" "Japanese (JP)" \
        "other" "Other Layout (Manual Code)" 3>&1 1>&2 2>&3)

    if [ "$KB_CHOICE" = "tr" ]; then
        TR_VARIANT=$(dialog --clear --title "TURKISH KEYBOARD VARIANT" \
            --menu "Select Turkish keyboard type:" 10 50 2 \
            "q" "Turkish Q Klavye" \
            "f" "Turkish F Klavye" 3>&1 1>&2 2>&3)
        if [ "$TR_VARIANT" = "f" ]; then
            KB_CHOICE="tr"
            VARIANT_ARG="f"
        else
            KB_CHOICE="tr"
            VARIANT_ARG="q"
        fi
    elif [ "$KB_CHOICE" = "other" ]; then
        CUSTOM_KB=$(dialog --inputbox "Enter keyboard layout code (e.g., us, tr, dk, fi):" 8 50 "us" 3>&1 1>&2 2>&3)
        [ -n "$CUSTOM_KB" ] && KB_CHOICE="$CUSTOM_KB"
    fi

    if [ -n "$KB_CHOICE" ]; then
        if [ "$KB_CHOICE" = "tr" ] && [ "$VARIANT_ARG" = "f" ]; then
            localectl set-x11-keymap tr pc105 f 2>/dev/null || true
            loadkeys trf 2>/dev/null || true
            dialog --msgbox "Keyboard layout successfully updated to Turkish F!" 5 50
        else
            localectl set-x11-keymap "$KB_CHOICE" 2>/dev/null || true
            loadkeys "$KB_CHOICE" 2>/dev/null || true
            dialog --msgbox "Keyboard layout successfully updated to '$KB_CHOICE'!" 5 50
        fi
    fi
}

create_new_user_account() {
    NEW_USER=$(dialog --inputbox "Enter new username:" 8 40 3>&1 1>&2 2>&3)
    if [ -n "$NEW_USER" ]; then
        NEW_PASS=$(dialog --passwordbox "Enter password for $NEW_USER:" 8 40 3>&1 1>&2 2>&3)
        if [ -n "$NEW_PASS" ]; then
            useradd -m -s /bin/bash -G sudo,audio,video,input,games "$NEW_USER" 2>/dev/null
            echo "$NEW_USER:$NEW_PASS" | chpasswd
            dialog --msgbox "User '$NEW_USER' created successfully!" 5 45
        fi
    fi
}

edit_existing_user() {
    TARGET_USER=$(dialog --inputbox "Enter existing username to edit (e.g., kgamer):" 8 50 "kgamer" 3>&1 1>&2 2>&3)
    if id "$TARGET_USER" &>/dev/null; then
        ACTION=$(dialog --clear --title "Edit User: $TARGET_USER" \
            --menu "Select option:" 12 50 2 \
            "1" "Change Username" \
            "2" "Change Password" 3>&1 1>&2 2>&3)
        
        if [ "$ACTION" = "1" ]; then
            NEW_NAME=$(dialog --inputbox "Enter new username for $TARGET_USER:" 8 50 3>&1 1>&2 2>&3)
            if [ -n "$NEW_NAME" ]; then
                usermod -l "$NEW_NAME" "$TARGET_USER" 2>/dev/null
                dialog --msgbox "Username changed to '$NEW_NAME' successfully!" 5 50
            fi
        elif [ "$ACTION" = "2" ]; then
            NEW_P=$(dialog --passwordbox "New password for $TARGET_USER:" 8 50 3>&1 1>&2 2>&3)
            if [ -n "$NEW_P" ]; then
                echo "$TARGET_USER:$NEW_P" | chpasswd
                dialog --msgbox "Password updated successfully!" 5 40
            fi
        fi
    else
        dialog --msgbox "User '$TARGET_USER' not found!" 5 40
    fi
}

change_root_password() {
    ROOT_P=$(dialog --passwordbox "Enter new ROOT password:" 8 50 3>&1 1>&2 2>&3)
    if [ -n "$ROOT_P" ]; then
        echo "root:$ROOT_P" | chpasswd
        dialog --msgbox "Root password updated successfully!" 5 45
    fi
}

start_desktop_environment() {
    clear
    echo "[+] Openbox ve Alttaki XFCE Paneli başlatılıyor..."

    export DISPLAY=:0

    # XFCE panelin altta konumlanması ve pencereler tarafından kapatılmaması için temel ayar
    xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=8;x=0;y=0" --create -t string 2>/dev/null || true

    # XFCE Paneli alt kısımda (bottom) başlat ve arka plana at
    xfce4-panel --display=:0 &

    # Pencere Yöneticisi olarak Openbox'ı çalıştır
    exec openbox-session
}

if [ ! -f "/opt/kgamer/.keyboard_configured" ]; then
    configure_keyboard_layout
    touch "/opt/kgamer/.keyboard_configured"
fi

while true; do
    CHOICE=$(dialog --clear --title "KGAMER-RETROGAMER-LINUXOS CONTROL CENTER" \
        --menu "Select action:" 18 65 7 \
        "1" "RETURN TO EMULATION STATION" \
        "2" "Open GUI Desktop (Openbox & Bottom XFCE Panel)" \
        "3" "Change Keyboard Layout" \
        "4" "Create New User Account" \
        "5" "Edit Existing User (Name/Password)" \
        "6" "Change Root Password" \
        "7" "Exit / Shutdown" 3>&1 1>&2 2>&3)
    case $CHOICE in
        1) clear; su - kgamer -c "emulationstation" & exit 0 ;;
        2) start_desktop_environment ;;
        3) configure_keyboard_layout ;;
        4) create_new_user_account ;;
        5) edit_existing_user ;;
        6) change_root_password ;;
        7) clear; exit 0 ;;
    esac
done
