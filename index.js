const express = require("express");
const app = express();

const HTTP_PORT = process.env.HTTP_PORT;
if (!HTTP_PORT) throw new Error("HTTP_PORT is required");

app.get("/", (req, res) => {
  res.send(`This app is version 1.1.0 and listening on port ${HTTP_PORT}`);
});

const server = app.listen(HTTP_PORT, () => {
  console.log(`App is version 1.1.0 and listening on port ${HTTP_PORT}`);
  process.send("ready");
});

process.on("SIGINT", function () {
  console.log("Shutting down gracefully");
  server.close((err) => {
    if (err) console.error(err.message);
    process.exit(err ? 1 : 0);
  });
});
