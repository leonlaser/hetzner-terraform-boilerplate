import { SQL } from "bun";

// bun uses DATABASE_URL by default to connect to the database
const sql = new SQL({
  connectionTimeout: 2,
});

const server = Bun.serve({
  port: 3000,
  routes: {
   "/api": async () => {
     try {
       const query = sql`SELECT NOW() AS current_time`.execute();
       setTimeout(() => query.cancel(), 100);
       return Response.json({
         env: {
           GLOBAL_VARIABLE: process.env.GLOBAL_VARIABLE,
           ENVIRONMENT_SPECIFIC_VARIABLE: process.env.ENVIRONMENT_SPECIFIC_VARIABLE,
         },
         data: await query,
       });
     } catch (error) {
       return Response.json({ error: error.message }, { status: 500 });
     }
    },
    "/api/health": async () => {
      try {
        const query = sql`SELECT 1`.execute();
        setTimeout(() => query.cancel(), 100);
        await query;
        
        return Response.json({ status: "ok" });
      } catch (error) {
        return Response.json({ status: "error", message: error.message }, { status: 503 });
      }
    }
  },
  fetch: (request) => {
    return new Response("Hello, Bun!");
  },
});

console.log(`Server running at http://localhost:${server.port}/`);