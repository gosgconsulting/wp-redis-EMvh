# Cloudflare Tunnel Integration

This project includes a Cloudflare Tunnel integration that securely exposes your WordPress application to the internet without opening any inbound ports on your firewall.

## How It Works

The setup uses Cloudflare's `cloudflared` Docker container to establish a secure outbound-only connection between your WordPress application and Cloudflare's edge network. This provides:

1. End-to-end encryption
2. Protection from direct attacks (your origin server is not directly exposed)
3. Automatic HTTPS
4. Cloudflare's security features (WAF, Bot Management, etc.)

## Configuration

The Cloudflare Tunnel is configured in the `docker-compose.yml` file as a service named `cloudflared`. It uses a pre-configured tunnel token for authentication.

```yaml
cloudflared:
  image: cloudflare/cloudflared:latest
  restart: always
  command: tunnel --no-autoupdate run --token YOUR_TUNNEL_TOKEN
  depends_on:
    - wp
```

## Important Security Notes

- The tunnel token in the docker-compose file is sensitive information that grants access to your Cloudflare account and should be treated as a secret.
- For production environments, consider using Docker secrets or environment variables to manage the token.
- The current token is configured to connect to a specific Cloudflare Tunnel that was created in your Cloudflare account.

## Monitoring and Management

You can manage your tunnel from the Cloudflare Zero Trust dashboard:
https://one.dash.cloudflare.com/

## Troubleshooting

If you experience issues with the tunnel:

1. Check the logs of the cloudflared container:
   ```
   docker-compose logs cloudflared
   ```

2. Verify that the WordPress container is running properly:
   ```
   docker-compose logs wp
   ```

3. Ensure your Cloudflare Tunnel is properly configured in the Cloudflare dashboard.
