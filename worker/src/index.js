// apt.flatpark.org — see ../wrangler.jsonc.
const SEGMENT = "[A-Za-z0-9][A-Za-z0-9._+-]*";
const POOL = new RegExp(`^pool/(${SEGMENT})/(${SEGMENT}\\.deb)$`);

const TYPES = {
  html: "text/html; charset=utf-8",
  asc: "text/plain; charset=utf-8",
  sources: "text/plain; charset=utf-8",
  gpg: "application/pgp-keys",
  deb: "application/vnd.debian.binary-package",
  gz: "application/gzip",
  xz: "application/x-xz",
};

export default {
  async fetch(request, env) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method Not Allowed", { status: 405, headers: { Allow: "GET, HEAD" } });
    }
    let key = decodeURIComponent(new URL(request.url).pathname).replace(/^\/+/, "");
    if (key === "") key = "index.html";

    const pool = key.match(POOL);
    if (pool) {
      return Response.redirect(
        `https://github.com/${env.GITHUB_REPO}/releases/download/${pool[1]}/${pool[2]}`, 302);
    }

    const object = request.method === "HEAD"
      ? await env.BUCKET.head(key)
      : await env.BUCKET.get(key, { onlyIf: request.headers });
    if (!object) return new Response("Not Found", { status: 404 });

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set("ETag", object.httpEtag);
    headers.set("Last-Modified", object.uploaded.toUTCString());
    if (!headers.has("Content-Type")) {
      headers.set("Content-Type", TYPES[key.split(".").pop()] ?? "application/octet-stream");
    }
    // by-hash files never change; everything else is re-read on each apt update.
    headers.set("Cache-Control", key.includes("/by-hash/")
      ? "public, max-age=31536000, immutable"
      : "no-cache");

    // get() with onlyIf returns an object without a body when the
    // If-None-Match / If-Modified-Since precondition says "unchanged".
    const fresh = request.method === "GET" && !("body" in object);
    return new Response(fresh || request.method === "HEAD" ? null : object.body,
      { status: fresh ? 304 : 200, headers });
  },
};
