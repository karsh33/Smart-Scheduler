const express = require("express");
const { pool } = require("../config/db");
const authMiddleware = require("../middleware/auth.middleware");

const router = express.Router();

/* CREATE RESOURCE */
router.post("/", authMiddleware, async (req, res) => {
  try {
    const {
      name,
      type,
      capacity,
      availability_start,
      availability_end,
      priority,
    } = req.body;

    if (!name || !type) {
      return res.status(400).json({ message: "Name and type are required" });
    }

    if ((capacity ?? 0) <= 0) {
      return res.status(400).json({ message: "Capacity must be greater than 0" });
    }

    const result = await pool.query(
      `INSERT INTO resources 
       (name, type, capacity, availability_start, availability_end, priority)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [name, type, capacity, availability_start, availability_end, priority]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error("CREATE RESOURCE ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/* GET ALL RESOURCES */
router.get("/", authMiddleware, async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM resources ORDER BY id ASC");
    res.json(result.rows);
  } catch (error) {
    console.error("GET RESOURCES ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/* UPDATE RESOURCE */
router.put("/:id", authMiddleware, async (req, res) => {
  try {
    const resourceId = req.params.id;
    const {
      name,
      type,
      capacity,
      availability_start,
      availability_end,
      priority,
    } = req.body;

    if (!name || !type) {
      return res.status(400).json({ message: "Name and type are required" });
    }

    if ((capacity ?? 0) <= 0) {
      return res.status(400).json({ message: "Capacity must be greater than 0" });
    }

    const result = await pool.query(
      `UPDATE resources
       SET name = $1,
           type = $2,
           capacity = $3,
           availability_start = $4,
           availability_end = $5,
           priority = $6
       WHERE id = $7
       RETURNING *`,
      [name, type, capacity, availability_start, availability_end, priority, resourceId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Resource not found" });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error("UPDATE RESOURCE ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/* DELETE RESOURCE */
router.delete("/:id", authMiddleware, async (req, res) => {
  try {
    const resourceId = req.params.id;

    const meetingsUsingResource = await pool.query(
      "SELECT * FROM meetings WHERE resource_id = $1",
      [resourceId]
    );

    if (meetingsUsingResource.rows.length > 0) {
      return res.status(400).json({
        message: "Cannot delete resource because meetings are assigned to it",
      });
    }

    const result = await pool.query(
      "DELETE FROM resources WHERE id = $1 RETURNING *",
      [resourceId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Resource not found" });
    }

    res.json({ message: "Resource deleted successfully" });
  } catch (error) {
    console.error("DELETE RESOURCE ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
