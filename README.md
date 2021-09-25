# Dead Drop Delivery

A simple web hook dead drop that allows Github to drop off push events to be polled by another process to be picked up at a later time. This provides some advantages:

- The flow control is controlled by the pickup service.
- The dead drop connections are only input initiated, increasing the security posture of the system. The dead drop exists in the internal network, but as a DMZ like device that has no independent access to anything else in the internal network.
- This service is VERY simple. While Jenkins is not terribly complicated to setup, it has many more moving parts that can be hard to troubleshoot when outside forces aren't working with you.

## Notes

**This is not yet fleshed out, more just a place to jott down things to describe later.**

`dropoff.service`:

```ini
[Unit]
Description=Dropoff

[Service]
ExecStart=/opt/dropoff/serve.sh
Restart=always
User=user
# Note Debian/Ubuntu uses 'nogroup', RHEL/Fedora uses 'nobody'
Group=user
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
WorkingDirectory=/opt/dropoff

[Install]
WantedBy=multi-user.target
```

`config.json`:

```json
{
  "scheme": "https",
  "hostname": "hostname.com",
  "dropoffkey": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
  "pickupkey": "eeeeeeee-dddd-cccc-bbbb-aaaaaaaaaaaa"
}
```

`pickup-url.cfg`:

```text
https://hostname/github-pickup
```

Crontab Example:

```crontab
*/5 * * * * /projects/cicd/deaddropdelivery/pickup/pickup.sh crazychenz/vinnie.work
```
