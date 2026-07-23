const express = require("express");
const { pool } = require("../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { OAuth2Client } = require("google-auth-library");

const router = express.Router();
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/* REGISTER */
router.post("/register", async (req, res) => {
  try {
    console.log("Incoming body:", req.body);

    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: "Missing fields" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (name, email, password)
       VALUES ($1, $2, $3)
       RETURNING id, name, email`,
      [name, email, hashedPassword]
    );

    res.json(result.rows[0]);

  } catch (error) {
    console.error("REGISTER ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/* LOGIN */
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  const result = await pool.query(
    "SELECT * FROM users WHERE email = $1",
    [email]
  );

  if (result.rows.length === 0) {
    return res.status(400).json({ message: "User not found" });
  }

  const user = result.rows[0];

  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    return res.status(400).json({ message: "Invalid credentials" });
  }

  const token = jwt.sign(
    { id: user.id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: "1d" }
  );

  res.json({ token });
});

/* GOOGLE LOGIN */
router.post("/google", async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: "Missing Google ID token" });
    }

    if (!process.env.GOOGLE_CLIENT_ID) {
      return res.status(500).json({ message: "Google auth is not configured on server" });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    if (!payload?.email) {
      return res.status(400).json({ message: "Google account email not available" });
    }

    const email = payload.email.toLowerCase();
    const name = payload.name || email.split("@")[0] || "Google User";
    const googleId = payload.sub;

    let userResult = await pool.query(
      "SELECT id, name, email FROM users WHERE email = $1",
      [email]
    );

    if (userResult.rows.length === 0) {
      const generatedPassword = await bcrypt.hash(`google_${googleId}_${Date.now()}`, 10);
      userResult = await pool.query(
        `INSERT INTO users (name, email, password)
         VALUES ($1, $2, $3)
         RETURNING id, name, email`,
        [name, email, generatedPassword]
      );
    }

    const user = userResult.rows[0];

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    return res.json({
      token,
      user,
      message: "Google login successful",
    });
  } catch (error) {
    console.error("GOOGLE LOGIN ERROR:", error);
    return res.status(401).json({ message: "Invalid Google token" });
  }
});

module.exports = router;
