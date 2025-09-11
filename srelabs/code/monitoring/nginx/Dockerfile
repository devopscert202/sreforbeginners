# nginx/Dockerfile
FROM nginx:stable

# Copy our main config and vhost confs
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Ensure log/cache directories exist and are writable
RUN mkdir -p /var/cache/nginx /var/log/nginx \
    && chown -R nginx:nginx /var/cache/nginx /var/log/nginx

# Expose the demo port (make sure your nginx.conf server block listens on 8081)
EXPOSE 8081

# Start nginx in the foreground (standard for containers)
CMD ["nginx", "-g", "daemon off;"]

