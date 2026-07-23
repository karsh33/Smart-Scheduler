const express = require("express");
const router = express.Router();
const { pool } = require("../config/db");
const authMiddleware = require("../middleware/auth.middleware");
const axios = require("axios");

/* CREATE MEETING */
router.post("/", authMiddleware, async (req, res) => {
  try {
    const { title, resource_id, start_time, end_time } = req.body;

    if (!title || !resource_id || !start_time || !end_time) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (new Date(start_time) >= new Date(end_time)) {
      return res.status(400).json({ message: "Start time must be before end time" });
    }

    const conflictCheck = await pool.query(
      `SELECT * FROM meetings
       WHERE resource_id = $1
       AND start_time < $3::timestamp
       AND end_time > $2::timestamp`,
      [resource_id, start_time, end_time]
    );

    if (conflictCheck.rows.length > 0) {
      return res.status(400).json({
        message: "Resource already booked for this time slot",
      });
    }

    const result = await pool.query(
      `INSERT INTO meetings (title, resource_id, start_time, end_time, created_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [title, resource_id, start_time, end_time, req.user.id]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error("CREATE MEETING ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/* GET ALL MEETINGS */
router.get("/", authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        m.id,
        COALESCE(m.title, 'Untitled Meeting') AS title,
        m.start_time,
        m.end_time,
        m.created_at,
        r.id AS resource_id,
        COALESCE(r.name, 'Unknown') AS resource_name,
        COALESCE(r.type, 'unknown') AS resource_type,
        u.id AS created_by,
        COALESCE(u.name, 'Unknown') AS created_by_name
      FROM meetings m
      LEFT JOIN resources r ON m.resource_id = r.id
      LEFT JOIN users u ON m.created_by = u.id
      ORDER BY m.start_time ASC
    `);

    res.json(result.rows);
  } catch (error) {
    console.error("GET MEETINGS ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/* GET MEETINGS FOR ONE RESOURCE */
router.get("/resource/:resourceId", authMiddleware, async (req, res) => {
  try {
    const { resourceId } = req.params;

    const result = await pool.query(
      `SELECT *
       FROM meetings
       WHERE resource_id = $1
       ORDER BY start_time ASC`,
      [resourceId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error("GET RESOURCE MEETINGS ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/* UPDATE MEETING */
router.put("/:id", authMiddleware, async (req, res) => {
  try {
    const meetingId = parseInt(req.params.id, 10);
    const resourceId = parseInt(req.body.resource_id, 10);
    const { title, start_time, end_time } = req.body;

    if (!meetingId || !title || !resourceId || !start_time || !end_time) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (new Date(start_time) >= new Date(end_time)) {
      return res.status(400).json({ message: "Start time must be before end time" });
    }

    const currentMeetingResult = await pool.query(
      "SELECT * FROM meetings WHERE id = $1 AND created_by = $2",
      [meetingId, req.user.id]
    );

    if (currentMeetingResult.rows.length === 0) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    const conflictCheck = await pool.query(
      `SELECT *
       FROM meetings
       WHERE resource_id = $1
         AND id <> $4
         AND start_time < $3::timestamp
         AND end_time > $2::timestamp`,
      [resourceId, start_time, end_time, meetingId]
    );

    if (conflictCheck.rows.length > 0) {
      return res.status(400).json({
        message: "Resource already booked for this time slot",
        conflict: conflictCheck.rows[0],
      });
    }

    const result = await pool.query(
      `UPDATE meetings
       SET title = $1,
           resource_id = $2,
           start_time = $3,
           end_time = $4
       WHERE id = $5 AND created_by = $6
       RETURNING *`,
      [title, resourceId, start_time, end_time, meetingId, req.user.id]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error("UPDATE MEETING ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

/* OPTIMIZE AND CREATE MEETING */
router.post("/optimize", authMiddleware, async (req, res) => {
  try {
    const { title, requested_start_time, requested_end_time } = req.body;

    if (!title || !requested_start_time || !requested_end_time) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (new Date(requested_start_time) >= new Date(requested_end_time)) {
      return res.status(400).json({ message: "Start time must be before end time" });
    }

    const resourcesResult = await pool.query(`
      SELECT id, name, type, capacity, priority
      FROM resources
      ORDER BY priority DESC, capacity ASC
    `);

    const meetingsResult = await pool.query(`
      SELECT id, resource_id, start_time, end_time
      FROM meetings
    `);

    const optimizationResponse = await axios.post(
      process.env.OPTIMIZATION_SERVICE_URL + "/optimize",
      {
        requested_start_time,
        requested_end_time,
        resources: resourcesResult.rows,
        existing_meetings: meetingsResult.rows,
      }
    );

    const optimizationData = optimizationResponse.data;

    if (!optimizationData.success) {
      return res.status(400).json({
        message: optimizationData.message || "No available resource found",
        suggestions: optimizationData.suggestions || [],
      });
    }

    const selectedResource = optimizationData.resource;

    const insertResult = await pool.query(
      `INSERT INTO meetings (title, resource_id, start_time, end_time, created_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        title,
        selectedResource.id,
        requested_start_time,
        requested_end_time,
        req.user.id,
      ]
    );

    res.json({
      message: "Meeting scheduled successfully",
      assigned_resource: selectedResource,
      meeting: insertResult.rows[0],
      suggestions: [],
    });
  } catch (error) {
    console.error("OPTIMIZE MEETING ERROR:", error.message);
    res.status(500).json({ error: error.message });
  }
});

/* DELETE MEETING */
router.delete("/:id", authMiddleware, async (req, res) => {
  try {
    const meetingId = req.params.id;

    const result = await pool.query(
      "DELETE FROM meetings WHERE id = $1 AND created_by = $2 RETURNING *",
      [meetingId, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Meeting not found" });
    }

    res.json({ message: "Meeting deleted successfully" });
  } catch (error) {
    console.error("DELETE MEETING ERROR:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
