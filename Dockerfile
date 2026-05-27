FROM node:20-bookworm-slim AS build

WORKDIR /app

COPY package*.json ./
RUN npm install --force 

COPY tsconfig.json nest-cli.json ./
COPY src ./src
RUN npm run build

FROM node:20-bookworm-slim

ENV NODE_ENV=staging
ENV PORT=3000
ENV LOOKER_PUPPETEER_HEADLESS=true
ENV LOOKER_PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    chromium \
    fonts-liberation \
    fonts-noto-color-emoji \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p data uploads logs

COPY package*.json ./
RUN npm install --omit=dev --force \
  && npm run install:browser --force

COPY --from=build /app/dist ./dist
COPY config ./config
COPY firebase ./firebase

EXPOSE 3000

CMD ["node", "dist/main.js"]
