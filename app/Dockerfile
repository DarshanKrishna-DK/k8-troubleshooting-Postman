FROM node:18-alpine

WORKDIR /app

# Create user first before copying files
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy source code
COPY server.js ./

# Labels
LABEL maintainer="Postman Meetup Demo"
LABEL version="1.0.0"
LABEL description="K8s Troubleshooting Demo API"

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Change ownership and switch to non-root user
RUN chown -R nodejs:nodejs /app
USER nodejs

CMD ["npm", "start"]
