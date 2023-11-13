#!/usr/bin/env bash

set -e

################################################################################
# Script: dotfiles_install.sh
# Description: Script to install or update dotfiles from the repository.
# Author: Lea <xealea@proton.me>
# Copyright (C) 2023 Lea <xealea@proton.me>
# Repository: https://github.com/xealea/simple-dot
################################################################################

# Set the repository URL and destination directory
repository="https://github.com/xealea/simple-dot"
destination="$HOME/simple-dot"

# Function to check if the repository is already available
is_repository_available() {
    [ -d "$destination" ] && [ -d "$destination/.git" ]
}

# Function to update the dotfiles repository
update_repository() {
    echo "Updating the dotfiles repository..."
    cd "$destination"
    git pull
}

# Function to run the SDDM theme installer
run_sddm_theme_installer() {
    echo "Running SDDM theme installer..."

    # Copy the sddm theme to /usr/share/ with sudo
    echo "Copying sddm theme to /usr/share/..."
    sudo cp -r $HOME/simple-dot/misc/sddm/ /usr/share/

    # Run sddm-greeter with the theme from /usr/share/sddm/themes/decay
    sddm-greeter --theme /usr/share/sddm/themes/decay

    # Install the sddm theme with sddmthemeinstaller using sudo
    echo "Installing the sddm theme..."
    sudo sddmthemeinstaller -i /usr/share/sddm/themes/decay

    # Copy the sddm configuration to /etc/ with sudo
    echo "Copying sddm configuration to /etc/..."
    sudo cp $HOME/simple-dot/misc/sddm.conf.d/sddm.conf /etc/

    # Restart sddm with the updated configuration using sudo
    echo "Restarting sddm..."
    sudo sddm /etc/sddm.conf
}

grub_install_now() {
    echo "Change GRUB theme.."

    # Copy theme first
    sudo cp -r $HOME/simple-dot/misc/grub /usr/share/
    
    # Define the desired GRUB_THEME line
    new_grub_theme='GRUB_THEME="/usr/share/grub/themes/simpleboot/theme.txt"'
    
    # Temporarily store the contents of /etc/default/grub
    current_grub_contents=$(cat /etc/default/grub)
    
    # Check if the line already exists in the file, if not, add it
    if [[ $current_grub_contents != *"$new_grub_theme"* ]]; then
        # Append the new GRUB_THEME line to /etc/default/grub
        echo "$new_grub_theme" | sudo tee -a /etc/default/grub
    fi

    # Regenerate the GRUB configuration
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}


# Display greeting message
echo "Hello there! These dotfiles are made by @Lea."
echo "You are now in the installation step."
echo ""

# Check if the repository is already available
if is_repository_available; then
    echo "The dotfiles repository is already available in $destination."

    # Prompt for confirmation to update the dotfiles
    read -p "Do you want to update the dotfiles repository? (y/n) " confirm

    # Check if the user wants to update the repository
    if [[ "$confirm" = "y" ]]; then
        update_repository
    else
        echo "Installation aborted. Exiting..."
        exit 0
    fi
else
    # Prompt for confirmation to clone the dotfiles repository
    read -p "Do you want to clone the dotfiles repository? (y/n) " confirm

    # Check if the user wants to clone the repository
    if [[ "$confirm" != "y" ]]; then
        echo "Installation aborted. Exiting..."
        exit 0
    fi

    # Clone the repository to the destination directory
    git clone --depth 1 "$repository" "$destination"
fi

# Calculate and display the size of each folder or file
calculate_size() {
    local path="$1"
    if [[ -e "$path" ]]; then
        local size
        size=$(du -sh "$path" | awk '{print $1}')
        local name
        name=$(basename "$path")
        printf "%-10s %s\n" "$size" "$name"
    else
        echo "du: cannot access '$path': No such file or directory"
        echo "           $(basename "$path")"
    fi
}

echo "Folder/File sizes:"
echo "------------------"
calculate_size "$destination"
calculate_size "$destination/misc"
calculate_size "$destination/.config"
calculate_size "$destination/.fehbg"
calculate_size "$destination/.fonts"
calculate_size "$destination/.icons"
calculate_size "$destination/.themes"
calculate_size "$destination/.wall"
calculate_size "$destination/.nanorc"
calculate_size "$destination/.gtkrc-2.0"

# Prompt for confirmation to continue
read -p "Do you want to copy the dotfiles? (y/n) " confirm

# Copy folders/files to the destination directory
if [[ "$confirm" = "y" ]]; then
    # Copy dotfiles to the destination directory
    rsync -a --exclude=".git" --exclude="README-ID.md" --exclude="README-EN.md" --exclude="README.md" --exclude="README-KEYBIND.md" --exclude="PACKAGE-LIST.md" --exclude="dotfiles_install.sh" "$destination/" "$HOME"

    # Place the LICENSE file in $HOME/.config directory
    cp "$HOME/LICENSE" "$HOME/.config/LICENSE-SIMPLE-DOT"

    # Display success message
    echo "Copying completed successfully!"
    echo ""

    # Prompt for Nemo default terminal
    echo "WARNING!!! IT WILL NOT WORK TO APPLY (y) IF YOU NOT INSTALLING NEMO, SO INSTALL FIRST BEFORE RUN!!"
    read -p "Set (if use) Nemo file manager default terminal to Alacritty? (y/n) " nemo_terminal_prompt
    # Set Nemo default terminal to Alacritty if user chooses 'y'
    if [[ "$nemo_terminal_prompt" = "y" ]]; then
        gsettings set org.cinnamon.desktop.default-applications.terminal exec alacritty
    fi
    echo ""

    # Prompt for Thunar default terminal
    echo "WARNING!!! IT WILL NOT WORK TO APPLY (y) IF YOU NOT INSTALLING THUNAR, SO INSTALL FIRST BEFORE RUN!!"
    read -p "Set (if use) Thunar default terminal to Alacritty? (y/n) " thunar_terminal_prompt

    # Set Thunar default terminal to Alacritty if user chooses 'y'
    if [[ "$thunar_terminal_prompt" = "y" ]]; then
        # Assuming Thunar's command to set the default terminal is similar to Nemo
        # Replace the following line with the appropriate command for Thunar if needed
        gsettings set org.xfce.Terminal.Settings exec alacritty
    fi
    echo ""

    # Extract Fonts from $HOME/.fonts directory
    echo "Extracting Fonts..."
    tar -xf "$HOME/.fonts/glyph-font.tar.xz" -C "$HOME/.fonts"
    echo "Fonts extracted."

    # Remove the tar.xz file
    rm "$HOME/.fonts/glyph-font.tar.xz"
    echo "glyph-font binary deleted."
    echo ""

    # Extract GTK theme from $HOME/.themes directory
    echo "Extracting GTK theme..."
    tar -xf "$HOME/.themes/decay.tar.xz" -C "$HOME/.themes"
    echo "GTK theme extracted."

    # Remove the tar.xz file
    rm "$HOME/.themes/decay.tar.xz"
    echo "decay binary deleted."
    echo ""

    # Extract icons from $HOME/.icons directory
    echo "Extracting icons..."
    tar -xf "$HOME/.icons/adecay.tar.xz" -C "$HOME/.icons"
    echo "Icons extracted."

    # Remove the tar.xz file
    rm "$HOME/.icons/adecay.tar.xz"
    echo "icons binary deleted."
    echo ""

    # Extract icons from $HOME/.icons directory
    echo "Extracting icons..."
    tar -xf "$HOME/.icons/xdecay.tar.xz" -C "$HOME/.icons"
    echo "cursor extracted."

    # Remove the tar.xz file
    rm "$HOME/.icons/xdecay.tar.xz"
    echo "cursor binary deleted."
    echo ""

    # Prompt to refresh font cache
    read -p "Do you want to refresh the font cache? (y/n) " refresh

    # Refresh font cache if selected
    if [[ "$refresh" = "y" ]]; then
        echo "Running fc-cache..."
        fc-cache -r
    fi
    echo ""

    # Prompt to refresh font cache
    read -p "Do you want to change the shell to startship fish? (y/n) " shell
    if [[ "$shell" = "y" ]]; then
        # Set shell to fish shell
        echo "Setting the shell to fish shell..."
        chsh -s "$(command -v fish)"
    fi
    echo ""

    # Prompt to change the GRUB theme
    read -p "Do you want to change the GRUB theme to custom by @xealea? (y/n) " grub_install
    if [[ "$grub_install" = "y" ]]; then
        grub_install_now
    fi

    # Prompt to run the SDDM theme installer
    read -p "Do you want to run the SDDM theme installer? (y/n) " theme_installer
    if [[ "$theme_installer" = "y" ]]; then
        run_sddm_theme_installer
    fi
    echo ""

    echo "Installation completed!"
else
    echo "Installation aborted. Exiting..."
    exit 0
fi

