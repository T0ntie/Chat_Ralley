import * as admin from "firebase-admin";
admin.initializeApp();
import { onRequest } from "firebase-functions/v2/https";

export const callGPT = onRequest({ region: "us-central1" }, async (req, res) => {
  const apiKey = process.env.OPENAI_API_KEY;
  const appCheckToken = req.header("X-Firebase-AppCheck");

  if (!appCheckToken) {
    res.status(403).json({ error: "Missing App Check token" });
    return;
  }

  try {
    await admin.appCheck().verifyToken(appCheckToken);
  } catch (err) {
    console.error("App Check verification failed:", err);
    res.status(403).json({ error: "App Check verification failed" });
    return;
  }

  if (!apiKey) {
    console.error("❌ OPENAI_API_KEY nicht gesetzt!");
    res.status(500).json({ error: "API key fehlt" });
    return;
  }

  const { messages, model = "gpt-4" } = req.body;

  if (!messages || !Array.isArray(messages)) {
    res.status(400).json({ error: "Invalid request body" });
    return;
  }

  try {
    const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ model, messages }),
    });

    const data = await openaiRes.json();

    if (data.error) {
      console.error("OpenAI error:", data.error);
      res.status(500).json({ error: data.error.message });
      return;
    }

    const reply = data.choices?.[0]?.message?.content ?? "Keine Antwort";
    res.status(200).json({ reply });
  } catch (err) {
    console.error("Fehler bei GPT:", err);
    res.status(500).json({ error: "Interner Fehler" });
  }
});
