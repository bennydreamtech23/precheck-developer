// Precheck badge service.
//
// Routes:
//   POST /badge/<owner>/<repo>        body: {"score": 92}   -> stores the score
//   GET  /badge/<owner>/<repo>.json   -> returns shields.io "endpoint" JSON
//
// Color thresholds (score is 0-100):
//   0-39   -> red
//   40-69  -> yellow
//   70-100 -> green

function colorForScore(score) {
  if (score < 40) return "red";
  if (score < 70) return "yellow";
  return "green";
}

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*", // required or shields.io won't render it
      "Cache-Control": "no-cache",
    },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const parts = url.pathname.split("/").filter(Boolean); // ["badge", "<owner>", "<repo...>"]

    if (parts[0] !== "badge" || parts.length < 3) {
      return new Response("Not found", { status: 404 });
    }

    const owner = parts[1];
    const rest = parts.slice(2).join("/");
    const isJsonRequest = rest.endsWith(".json");
    const repo = isJsonRequest ? rest.slice(0, -".json".length) : rest;
    const key = `${owner}/${repo}`;

    // --- precheck reports a score after a CI run ---
    if (request.method === "POST") {
      const token = request.headers.get("x-precheck-token");
      if (!env.PRECHECK_TOKEN || token !== env.PRECHECK_TOKEN) {
        return new Response("Unauthorized", { status: 401 });
      }

      let body;
      try {
        body = await request.json();
      } catch {
        return new Response("Invalid JSON body", { status: 400 });
      }

      const score = Number(body.score);
      if (!Number.isFinite(score) || score < 0 || score > 100) {
        return new Response("Invalid score (expected 0-100)", { status: 400 });
      }

      await env.PRECHECK_SCORES.put(
        key,
        JSON.stringify({ score, updatedAt: new Date().toISOString() })
      );

      return jsonResponse({ ok: true, repo: key, score });
    }

    // --- shields.io fetches this to render the badge ---
    if (request.method === "GET" && isJsonRequest) {
      const stored = await env.PRECHECK_SCORES.get(key);
      const score = stored ? JSON.parse(stored).score : null;

      return jsonResponse({
        schemaVersion: 1,
        label: "precheck",
        message: score === null ? "no data" : `${score}%`,
        color: score === null ? "lightgrey" : colorForScore(score),
      });
    }

    return new Response("Not found", { status: 404 });
  },
};