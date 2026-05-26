FROM node:20-bookworm-slim AS build

ENV PUPPETEER_SKIP_DOWNLOAD=true

WORKDIR /app

COPY package*.json ./
RUN npm install --force

COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN npm run build

FROM node:20-bookworm-slim

ENV NODE_ENV=staging
ENV PORT=3000
ENV LOOKER_PUPPETEER_HEADLESS=true
ENV LOOKER_PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_DOWNLOAD=true

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    chromium \
    fonts-liberation \
    fonts-noto-color-emoji \
    ca-certificates \
    xz-utils \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p data uploads logs

COPY package*.json ./
RUN npm install --omit=dev --include=optional --force \
  && npm install --no-save --include=optional --os=linux --cpu=x64 sharp@0.33.5 \
  && node -e "require('sharp'); console.log('sharp linux-x64 ok')" \
  && chromium --version

COPY --from=build /app/dist ./dist
COPY config ./config

EXPOSE 3000

CMD ["node", "dist/main.js"]
