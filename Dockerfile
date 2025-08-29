# Use Node.js 18 LTS as base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json pnpm-lock.yaml ./

# Install pnpm and dependencies
RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Expose port 8090
EXPOSE 8090

# Set environment to production
ENV NODE_ENV=production

# Start the server
CMD ["node", "server-fixed.js"]
