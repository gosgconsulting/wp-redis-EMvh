#!/bin/bash

# Copy Object Cache Pro Plugin Script
# This script ensures that the Object Cache Pro plugin is correctly installed from the local plugins folder

set -e

echo "🚀 Starting Object Cache Pro local installation..."

# Configuration
PLUGINS_DIR="/var/www/html/wp-content/plugins"
LOCAL_PLUGINS_DIR="/var/www/html/plugins"
OCP_DIR="${PLUGINS_DIR}/object-cache-pro"
LOCAL_OCP_DIR="${LOCAL_PLUGINS_DIR}/object-cache-pro"

# Function to copy plugin from local folder
copy_from_local() {
    echo "📂 Checking for Object Cache Pro in local plugins folder..."
    
    # Check if the local plugin directory exists
    if [ ! -d "$LOCAL_OCP_DIR" ]; then
        echo "⚠️ Object Cache Pro not found in local plugins folder: $LOCAL_OCP_DIR"
        echo "ℹ️ Creating empty directory structure..."
        mkdir -p "$OCP_DIR"
        touch "$OCP_DIR/README.md"
        echo "# Object Cache Pro - Please add plugin files here" > "$OCP_DIR/README.md"
        return 0
    fi
    
    # Create plugins directory if it doesn't exist
    mkdir -p "$PLUGINS_DIR"
    
    # Remove existing plugin directory if it exists
    if [ -d "$OCP_DIR" ]; then
        echo "🗑️ Removing existing Object Cache Pro plugin..."
        rm -rf "$OCP_DIR"
    fi
    
    # Copy the plugin files
    echo "📋 Copying Object Cache Pro from local folder..."
    cp -r "$LOCAL_OCP_DIR" "$OCP_DIR"
    
    # Check if copy was successful
    if [ -d "$OCP_DIR" ] && [ -f "${OCP_DIR}/object-cache-pro.php" ]; then
        echo "✅ Object Cache Pro copied successfully!"
        # Set proper permissions
        chown -R www-data:www-data "$OCP_DIR"
        return 0
    else
        echo "❌ Failed to copy Object Cache Pro plugin!"
        return 1
    fi
}

# Main execution
main() {
    echo "🎯 Starting Object Cache Pro local installation..."
    
    # Copy from local folder
    copy_from_local || {
        echo "❌ Failed to install Object Cache Pro from local folder"
        exit 1
    }
    
    echo "🎉 Object Cache Pro local installation completed successfully!"
}

# Run main function
main "$@"
