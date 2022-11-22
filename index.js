const express = require("express");
const app = express();

const HTTP_PORT = process.env.HTTP_PORT;
if (!HTTP_PORT) throw new Error("HTTP_PORT is required");

app.get("/", (req, res) => {
  res.send(`This is running on port ${HTTP_PORT}`);
});

app.listen(HTTP_PORT, () => {
  console.log(`App listening on port ${HTTP_PORT}`);
});
