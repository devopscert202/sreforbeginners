# Blue-Green Deployment

## Objective:
To implement blue-green deployment ensuring zero downtime during application upgrades. This setup will start with the **Blue** version and allow seamless switch to the **Green** version.

## Steps:
1. Launch an EC2 instance and SSH into it.
2. Run the setup script to install Nginx, create blue/green versions, and configure Nginx.
3. Verify the blue version is live by visiting the EC2 public IP.
4. Switch to the green version by modifying Nginx configuration and reload.

### Test the Deployment:
- Once the green version is active, refresh your browser to confirm the upgrade.

For more detailed instructions, refer to the lab steps in the provided document.

