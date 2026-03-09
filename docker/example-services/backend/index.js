import {SQL} from "bun";

// bun uses DATABASE_URL by default to connect to the database
const sql = new SQL({
  connectionTimeout: 2,
});

// Create demo tables for testing backup and restore
await sql`
  CREATE TABLE IF NOT EXISTS users
  (
    id    SERIAL PRIMARY KEY,
    name  VARCHAR NOT NULL,
    email VARCHAR NOT NULL
  )
`;

await sql`
  INSERT INTO users (id, name, email)
  VALUES (1, 'Max Musterman', 'max@musterman.de')
  ON CONFLICT (id) DO NOTHING
`;


await sql`
  INSERT INTO users (id, name, email)
  VALUES (2, 'Maxine Musterwoman', 'maxine@musterwoman.de')
  ON CONFLICT (id) DO NOTHING
`;

await sql`
  CREATE TABLE IF NOT EXISTS key_val
  (
    key VARCHAR PRIMARY KEY,
    val VARCHAR NOT NULL
  )`;

await sql`
  INSERT INTO key_val
  VALUES ('a', '1'),
         ('b', '2'),
         ('c', '3')
  ON CONFLICT (key) DO NOTHING
`

// Example server to test and demonstrate the backend 
const server = Bun.serve({
  port: 3000,
  routes: {
   "/api": async () => {
     try {
       const query1 = sql`SELECT NOW() AS "current_time"`.execute();
       const query2 = sql`SELECT *
                          FROM users`.execute();
       const query3 = sql`SELECT *
                          FROM key_val`.execute();

       setTimeout(() => query1.cancel(), 100);
       setTimeout(() => query2.cancel(), 100);
       setTimeout(() => query3.cancel(), 100);
       
       return Response.json({
         env: {
           GLOBAL_VARIABLE: process.env.GLOBAL_VARIABLE,
           ENVIRONMENT_SPECIFIC_VARIABLE: process.env.ENVIRONMENT_SPECIFIC_VARIABLE,
         },
         data: [...(await query1), ...(await query2), ...(await query3)],
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