# syntax=docker/dockerfile:1

# ---------- Stage 1: React (Vite) frontend build ----------
FROM node:20-alpine AS frontend-build
WORKDIR /frontend

COPY frontend/package*.json ./
RUN npm ci

COPY frontend/ ./
# Same container se serve hoga, isliye API ka relative path use karte hain
ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# ---------- Stage 2: Production image (Express + built React) ----------
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app

COPY backend/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --chown=node:node backend/ ./
# React build ko backend ke "public" folder mein rakho, Express isay serve karega
COPY --chown=node:node --from=frontend-build /frontend/dist ./public

USER node
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://localhost:'+(process.env.PORT||5000)+'/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server.js"]
