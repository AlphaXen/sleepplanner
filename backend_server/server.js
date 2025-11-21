const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// TODO: Firebase Admin or your DB 연결 (옵션)

// Health check
app.get("/", (req, res) => {
  res.send("SleepPlanner Node.js backend running");
});

// Flutter app → Sleep Plan 보내는 API
app.post("/api/sleep-plan", async (req, res) => {
  const { userId, mainSleepStart, mainSleepEnd } = req.body;

  console.log("Received sleep plan:", userId, mainSleepStart, mainSleepEnd);

  // 1) 필요한 경우 DB 에 저장 (Firebase / MySQL 등)
  // 2) Google Home API 사용해서 automation trigger 준비 (TODO)

  return res.json({ ok: true });
});

// Auto Reply 설정도 backend 로 보낼 수 있음
app.post("/api/auto-reply-settings", (req, res) => {
  const { userId, enabled, message, contacts } = req.body;
  console.log("Auto reply settings:", userId, enabled, message, contacts);
  // TODO: DB 저장 / Google Home routine 과 연결도 가능

  return res.json({ ok: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Backend server listening on port ${PORT}`);
});
