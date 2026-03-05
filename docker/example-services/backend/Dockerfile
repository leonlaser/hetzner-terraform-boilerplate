FROM node:alpine

WORKDIR /app

COPY --chown=node:node index.js .

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO /dev/null http://localhost:3000/ || exit 1

CMD ["node", "index.js"]
