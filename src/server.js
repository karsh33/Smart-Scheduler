require("dotenv").config();
const { initializeDb } = require("./config/db");

const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/auth.routes");
const resourceRoutes = require("./routes/resource.routes");
const meetingRoutes = require("./routes/meeting.routes");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "Smart Scheduler backend is running" });
});

app.use("/api/auth", authRoutes);
app.use("/api/resources", resourceRoutes);
app.use("/api/meetings", meetingRoutes);

const PORT = process.env.PORT || 5000;
const HOST = "0.0.0.0";

app.listen(PORT, HOST, () => {
  console.log(`Server running on ${HOST}:${PORT}`);
});

initializeDb();
