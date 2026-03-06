FROM oven/bun:alpine

WORKDIR /app

COPY --chown=bun:bun index.js .

USER bun

EXPOSE 3000

HEALTHCHECK --interval=2s --timeout=3s --start-period=5s --retries=3 \
  CMD bun -e "const res = await fetch('http://localhost:3000/api/health'); if (!res.ok) throw new Error();" || exit 1

CMD ["bun", "index.js"]