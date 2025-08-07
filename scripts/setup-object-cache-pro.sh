#!/bin/bash

# Object Cache Pro Auto-Activation Script
# This script automatically activates a manually uploaded Object Cache Pro plugin
# Works for both new installations and existing WordPress sites

set -e

echo "🚀 Starting Object Cache Pro auto-activation..."

# Configuration
PLUGINS_DIR="/var/www/html/wp-content/plugins"
OCP_DIR="${PLUGINS_DIR}/object-cache-pro"
DROPIN_SOURCE="${OCP_DIR}/stubs/object-cache.php"
DROPIN_TARGET="/var/www/html/wp-content/object-cache.php"
OCP_MAIN_FILE="${OCP_DIR}/object-cache-pro.php"

# Wait for WordPress to be ready
echo "⏳ Waiting for WordPress database to be ready..."
until wp db check --allow-root --quiet 2>/dev/null; do
    echo "Database not ready yet, waiting 3 seconds..."
    sleep 3
done
echo "✅ WordPress database is ready!"

# Function to check if Object Cache Pro is available
check_object_cache_pro() {
    echo "🔍 Checking for Object Cache Pro plugin..."
    
    if [ ! -d "$OCP_DIR" ]; then
        echo "❌ Object Cache Pro plugin directory not found: $OCP_DIR"
        echo "ℹ️ Attempting to install from local plugins folder..."
        
        # Try to run the copy script if it exists
        if [ -f "/docker-entrypoint-initwp.d/copy-object-cache-pro.sh" ]; then
            echo "📦 Running copy script..."
            bash /docker-entrypoint-initwp.d/copy-object-cache-pro.sh
            
            # Check if installation was successful
            if [ ! -d "$OCP_DIR" ] || [ ! -f "$OCP_MAIN_FILE" ]; then
                echo "❌ Local installation failed"
                echo "ℹ️ Please ensure Object Cache Pro plugin files are in the plugins/object-cache-pro/ directory"
                return 1
            fi
        else
            echo "❌ Copy script not found"
            echo "ℹ️ Please ensure Object Cache Pro plugin files are in the plugins/object-cache-pro/ directory"
            return 1
        fi
    fi
    
    if [ ! -f "$OCP_MAIN_FILE" ]; then
        echo "❌ Object Cache Pro main plugin file not found: $OCP_MAIN_FILE"
        echo "ℹ️ Please ensure object-cache-pro.php is in the plugin directory"
        return 1
    fi
    
    echo "✅ Object Cache Pro plugin files found!"
    return 0
}

# Function to activate the plugin
activate_plugin() {
    echo "🔌 Activating Object Cache Pro plugin..."
    
    # Activate the plugin using WP-CLI
    wp plugin activate object-cache-pro --allow-root --quiet || {
        echo "⚠️ Plugin activation failed, but continuing..."
    }
    
    echo "✅ Object Cache Pro plugin activated!"
}

# Function to install the drop-in
install_dropin() {
    echo "💾 Installing Object Cache Pro drop-in..."
    
    if [ -f "$DROPIN_SOURCE" ]; then
        # Copy the drop-in file
        cp "$DROPIN_SOURCE" "$DROPIN_TARGET"
        chown www-data:www-data "$DROPIN_TARGET"
        chmod 644 "$DROPIN_TARGET"
        echo "✅ Object Cache Pro drop-in installed successfully!"
    else
        echo "❌ Drop-in source file not found: $DROPIN_SOURCE"
        return 1
    fi
}

# Function to enable object cache via WP-CLI
enable_object_cache() {
    echo "⚡ Enabling Object Cache Pro..."
    
    # Try to enable object cache using WP-CLI
    wp object-cache enable --allow-root --quiet 2>/dev/null || {
        echo "ℹ️ WP-CLI object-cache command not available, drop-in should work automatically"
    }
    
    echo "✅ Object Cache Pro enabled!"
}

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying Object Cache Pro installation..."
    
    # Check if plugin exists
    if [ ! -d "$OCP_DIR" ]; then
        echo "❌ Object Cache Pro plugin directory not found!"
        return 1
    fi
    
    # Check if drop-in exists
    if [ ! -f "$DROPIN_TARGET" ]; then
        echo "❌ Object Cache Pro drop-in not found!"
        return 1
    fi
    
    # Check plugin status
    if wp plugin is-active object-cache-pro --allow-root --quiet 2>/dev/null; then
        echo "✅ Object Cache Pro plugin is active!"
    else
        echo "⚠️ Object Cache Pro plugin may not be active, but drop-in should still work"
    fi
    
    echo "✅ Object Cache Pro verification complete!"
}

# Main execution
main() {
    echo "🎯 Starting Object Cache Pro auto-activation for $(wp option get siteurl --allow-root 2>/dev/null || echo 'WordPress site')..."
    
    # Check if Object Cache Pro is available
    check_object_cache_pro || {
        echo "ℹ️ Object Cache Pro not available, skipping activation"
        echo "📝 To enable Object Cache Pro:"
        echo "   1. Download plugin from https://objectcache.pro/"
        echo "   2. Extract and place files in the plugins/object-cache-pro/ directory"
        echo "   3. Redeploy container"
        return 0
    }
    
    # Activate the plugin
    activate_plugin
    
    # Install the drop-in
    install_dropin || {
        echo "❌ Failed to install drop-in"
        exit 1
    }
    
    # Enable object cache
    enable_object_cache
    
    # Verify everything is working
    verify_installation
    
    echo "🎉 Object Cache Pro auto-activation completed successfully!"
    echo "🔗 Visit Settings > Object Cache Pro in WordPress Admin to verify status"
}

# Run main function
main "$@"
