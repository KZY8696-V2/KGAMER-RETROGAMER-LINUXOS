#!/bin/bash
APPS_SRC="/usr/share/applications"
APPS_DEST="/home/kgamer/RetroPie/roms/apps"
SPEC_FILE="/opt/kgamer/apps_filter.spec"

mkdir -p "$APPS_DEST"

desktop_files=()
while IFS= read -r file; do
    if [ -f "$file" ]; then
        if grep -q "NoDisplay=true" "$file"; then
            continue
        fi
        desktop_files+=("$file")
    fi
done < <(find "$APPS_SRC" -name "*.desktop")

dialog_args=()
for file in "${desktop_files[@]}"; do
    desktop_name=$(basename "$file")
    app_title=$(grep -m 1 "^Name=" "$file" | cut -d '=' -f2-)
    [ -z "$app_title" ] && app_title="$desktop_name"
    
    status="ON"
    if [ -f "$SPEC_FILE" ]; then
        if grep -q "$desktop_name:OFF" "$SPEC_FILE"; then
            status="OFF"
        fi
    fi
    dialog_args+=("$desktop_name" "$app_title" "$status")
done

CHOICES=$(dialog --clear --title "KGAMER - APPS VISIBILITY FILTER" \
    --checklist "Select applications to show in EmulationStation APPS menu:" 22 70 12 \
    "${dialog_args[@]}" 3>&1 1>&2 2>&3)

clear

visible_apps=()
for file in "${desktop_files[@]}"; do
    desktop_name=$(basename "$file")
    if echo "$CHOICES" | grep -q "\"$desktop_name\""; then
        visible_apps+=("$desktop_name")
    fi
done

SORT_CHOICE=$(dialog --clear --title "KGAMER - APPS SORTING" \
    --menu "Select sorting method for apps:" 12 50 3 \
    "1" "Alphabetical Order (A-Z)" \
    "2" "Reverse Alphabetical Order (Z-A)" \
    "3" "Keep Default / Custom Spec Order" 3>&1 1>&2 2>&3)

clear

if [ "$SORT_CHOICE" = "1" ]; then
    IFS=$'\n' sorted_apps=($(sort <<< "${visible_apps[*]}"))
    unset IFS
elif [ "$SORT_CHOICE" = "2" ]; then
    IFS=$'\n' sorted_apps=($(sort -r <<< "${visible_apps[*]}"))
    unset IFS
else
    sorted_apps=("${visible_apps[@]}")
fi

find "$APPS_DEST" -name "*.desktop" ! -name "00-Filter-Apps.desktop" -delete
> "$SPEC_FILE"

for desktop_name in "${desktop_files[@]}"; do
    base_name=$(basename "$desktop_name")
    if echo "$CHOICES" | grep -q "\"$base_name\""; then
        echo "$base_name:ON" >> "$SPEC_FILE"
    else
        echo "$base_name:OFF" >> "$SPEC_FILE"
    fi
done

for app in "${sorted_apps[@]}"; do
    ln -sf "$APPS_SRC/$app" "$APPS_DEST/$app"
done

dialog --msgbox "Application filter and sorting updated successfully!" 6 50
