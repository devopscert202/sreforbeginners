# Blue-Green Deployment

## Objective
Implement Blue-Green deployment with nginx. Blue is active initially; switching the root in nginx config to /var/www/green and reloading nginx switches to Green.

## Quick steps
1. SSH into EC2 instance.
2. Copy the contents of this folder to the EC2 host (or git clone).
3. Run: sudo ./setup.sh
4. Verify blue page via: curl http://localhost or browser.
5. To switch to green:
   - Edit /etc/nginx/conf.d/site.conf to `root /var/www/green;`
   - sudo nginx -t && sudo systemctl reload nginx
6. Verify green page.


