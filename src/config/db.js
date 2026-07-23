require("dotenv").config();
const pg = require("pg");
const { Pool } = pg;

// OID 1114 = timestamp without time zone
pg.types.setTypeParser(1114, (str) => str);

const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: Number(process.env.DB_PORT),
});

pool.on("error", (err) => {
  console.error("Unexpected PostgreSQL pool error:", err);
});

const initializeDb = async () => {
  try {
    await pool.query("SELECT 1");
    console.log("Connected to PostgreSQL");
  } catch (err) {
    console.error("PostgreSQL connection error:", err);
  }
};

module.exports = { pool, initializeDb };
