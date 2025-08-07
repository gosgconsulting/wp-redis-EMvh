#!/bin/sh
set -e

# Ensure wp-content and its subdirectories are owned by www-data.
# This allows for installing/updating plugins and themes from the WP admin,
# especially when volumes are mounted from the host.
echo "Fixing permissions for wp-content..."
chown -R www-data:www-data /var/www/html/wp-content
echo "Permissions fixed."
