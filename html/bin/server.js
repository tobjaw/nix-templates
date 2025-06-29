import { exec } from "node:child_process";
import { constants, accessSync, lstatSync, readFile } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize, resolve } from "node:path";

const HOST = "localhost";
// PORT the server listens on
const PORT = 3000;
// base DIR for static files served
const DIR = "./src";

const root = normalize(resolve(DIR));
const types = {
  html: "text/html",
  css: "text/css",
  js: "application/javascript",
  png: "image/png",
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  gif: "image/gif",
  json: "application/json",
  xml: "application/xml",
};

const main = () => {
  try {
    lstatSync(DIR);
  } catch (err) {
    console.error(err);
    return;
  }

  server.listen(PORT, HOST, () => {
    const url = `http://${HOST}:${PORT}/`;
    console.log(`serving files from ${DIR} on ${url}`);
    const start =
      process.platform === "darwin"
        ? "open"
        : process.platform === "win32"
          ? "start"
          : "xdg-open";
    exec(`${start} ${url}`);
  });
};

const server = createServer((req, res) => {
  console.log(`${req.method} ${req.url}`);

  const extension = extname(req.url).slice(1);
  const type = extension ? types[extension] : types.html;

  if (type == null) {
    return err404(res);
  }

  let fileName = req.url;
  if (req.url === "/") {
    fileName = "index.html";
  }

  if (!extension) {
    try {
      accessSync(join(root, `${req.url}.html`), constants.F_OK);
      fileName = `${req.url}.html`;
    } catch (e) {
      fileName = join(req.url, "index.html");
    }
  }

  const filePath = join(root, fileName);
  const isPathUnderRoot = normalize(resolve(filePath)).startsWith(root);
  if (!isPathUnderRoot) {
    return err404(res);
  }

  readFile(filePath, (err, data) => {
    if (err) {
      return err404(res);
    }
    res.writeHead(200, { "Content-Type": type });
    res.end(data);
  });
});

const err404 = (res) => {
  res.writeHead(404, { "Content-Type": "text/html" });
  res.end("404: File not found");
};

main();
