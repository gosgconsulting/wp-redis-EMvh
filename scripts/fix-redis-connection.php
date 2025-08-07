<?php
/**
 * Redis Connection Diagnostic Tool
 * 
 * This script checks and fixes common Redis configuration issues
 * Run from WP-CLI with: wp eval-file scripts/fix-redis-connection.php
 */

// Check if we're running in WP environment
if (!function_exists('add_action')) {
    die('This script must be run within WordPress environment via WP-CLI.');
}

echo "======================================\n";
echo "WordPress Redis Connection Diagnostic\n";
echo "======================================\n\n";

// 1. Check if Redis extensions are installed
echo "Checking PHP Redis extensions...\n";
if (extension_loaded('redis')) {
    echo "✅ PHP Redis extension installed\n";
    echo "   Version: " . phpversion('redis') . "\n";
} else {
    echo "❌ PHP Redis extension NOT installed\n";
    echo "   Redis won't work without this extension\n";
}

if (extension_loaded('igbinary')) {
    echo "✅ PHP igbinary extension installed\n";
    echo "   Version: " . phpversion('igbinary') . "\n";
} else {
    echo "⚠️ PHP igbinary extension NOT installed\n";
    echo "   Redis will work but without optimal serialization\n";
}

// 2. Check Object Cache Pro installation
echo "\nChecking Object Cache Pro installation...\n";
$plugin_path = WP_PLUGIN_DIR . '/object-cache-pro/object-cache-pro.php';
if (file_exists($plugin_path)) {
    echo "✅ Object Cache Pro plugin files found\n";
    
    if (is_plugin_active('object-cache-pro/object-cache-pro.php')) {
        echo "✅ Object Cache Pro plugin is active\n";
    } else {
        echo "❌ Object Cache Pro plugin is installed but NOT active\n";
        echo "   Activating plugin...\n";
        activate_plugin('object-cache-pro/object-cache-pro.php');
        echo "   Plugin activation attempted\n";
    }
} else {
    echo "❌ Object Cache Pro plugin files NOT found at expected location\n";
    echo "   Expected path: $plugin_path\n";
}

// 3. Check Object Cache drop-in
echo "\nChecking object-cache.php drop-in...\n";
$dropin_path = WP_CONTENT_DIR . '/object-cache.php';
if (file_exists($dropin_path)) {
    echo "✅ object-cache.php drop-in exists\n";
    
    // Check if it's from Object Cache Pro
    $dropin_content = file_get_contents($dropin_path);
    if (strpos($dropin_content, 'Object Cache Pro') !== false) {
        echo "✅ Drop-in is from Object Cache Pro\n";
    } else {
        echo "⚠️ Drop-in exists but might not be from Object Cache Pro\n";
        echo "   Consider replacing it with the correct version\n";
    }
} else {
    echo "❌ object-cache.php drop-in NOT found\n";
    echo "   Installing drop-in...\n";
    
    $source_path = WP_PLUGIN_DIR . '/object-cache-pro/stubs/object-cache.php';
    if (file_exists($source_path)) {
        if (copy($source_path, $dropin_path)) {
            echo "✅ Drop-in installed successfully\n";
        } else {
            echo "❌ Failed to install drop-in\n";
        }
    } else {
        echo "❌ Source drop-in file not found at: $source_path\n";
    }
}

// 4. Test Redis connection
echo "\nTesting Redis connection...\n";
if (class_exists('Redis')) {
    try {
        $redis = new Redis();
        $connected = $redis->connect(
            defined('WP_REDIS_HOST') ? WP_REDIS_HOST : 'redis', 
            defined('WP_REDIS_PORT') ? WP_REDIS_PORT : 6379, 
            0.5
        );
        
        if ($connected) {
            echo "✅ Successfully connected to Redis server\n";
            echo "   Redis version: " . $redis->info()['redis_version'] . "\n";
            
            // Try setting and getting a value
            $testKey = 'wp_redis_test_' . time();
            $testValue = 'Working at ' . date('Y-m-d H:i:s');
            
            $redis->set($testKey, $testValue, 60);
            $retrievedValue = $redis->get($testKey);
            
            if ($retrievedValue === $testValue) {
                echo "✅ Redis read/write test successful\n";
            } else {
                echo "❌ Redis read/write test failed\n";
            }
        } else {
            echo "❌ Failed to connect to Redis server\n";
        }
    } catch (Exception $e) {
        echo "❌ Redis connection error: " . $e->getMessage() . "\n";
    }
} else {
    echo "❌ Cannot test connection: Redis class not available\n";
}

// 5. Check WP_REDIS configurations
echo "\nChecking WP_REDIS configuration...\n";
if (defined('WP_REDIS_DISABLED') && WP_REDIS_DISABLED) {
    echo "⚠️ WP_REDIS_DISABLED is set to true - Redis cache is disabled\n";
}

if (defined('WP_REDIS_CONFIG')) {
    echo "✅ WP_REDIS_CONFIG is defined\n";
    echo "   Host: " . (WP_REDIS_CONFIG['host'] ?? 'not set') . "\n";
    echo "   Port: " . (WP_REDIS_CONFIG['port'] ?? 'not set') . "\n";
    echo "   Database: " . (WP_REDIS_CONFIG['database'] ?? 'not set') . "\n";
} else {
    echo "❌ WP_REDIS_CONFIG is not defined in wp-config.php\n";
}

echo "\n======================================\n";
echo "Diagnostic Complete\n";
echo "======================================\n\n";

// Final recommendations
echo "Recommendations:\n";
echo "1. If Redis connection fails, check firewall settings\n";
echo "2. Verify Redis server is running with: docker-compose ps\n";
echo "3. If drop-in installation failed, try manually copying from plugin stubs\n";
echo "4. To temporarily disable Redis cache, add: define('WP_REDIS_DISABLED', true);\n";
echo "5. Run: wp cache flush to clear cache after fixing connection issues\n";
