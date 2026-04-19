import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const SUPABASE_URL = "https://loaallkwmwgqlxhndwrf.supabase.co";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

serve(async (req) => {

  // =========================
  //  CORS (REQUIRED)
  // =========================
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    console.log(" FUNCTION HIT");

    const { email } = await req.json();
    console.log(" EMAIL RECEIVED:", email);

    // =========================
    //  FIND USERNAME
    // =========================
    const userRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?recovery_email=eq.${email}&select=username`,
      {
        headers: {
          "apikey": SERVICE_ROLE_KEY!,
          "Authorization": `Bearer ${SERVICE_ROLE_KEY}`,
        },
      }
    );

    const users = await userRes.json();
    console.log(" USER QUERY RESULT:", users);

    if (!users || users.length === 0) {
      return new Response(
        JSON.stringify({ error: "No user found" }),
        {
          status: 404,
          headers: { "Access-Control-Allow-Origin": "*" },
        }
      );
    }

    const username = users[0].username;
    console.log(" USERNAME FOUND:", username);

    // =========================
    //  SEND EMAIL
    // =========================
    console.log("📤 Sending email...");

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "MyNote <onboarding@mynoteapp.us>",
        to: email,
        subject: "Your MyNote Username",
        html: `
          <h2>Your username is:</h2>
          <p style="font-size:18px; font-weight:bold;">${username}</p>
        `,
      }),
    });

    const data = await response.json();

    console.log(" RESEND STATUS:", response.status);
    console.log(" RESEND RESPONSE:", data);

    if (!response.ok) {
      return new Response(
        JSON.stringify({ error: data }),
        {
          status: 500,
          headers: { "Access-Control-Allow-Origin": "*" },
        }
      );
    }

    // =========================
    //  SUCCESS
    // =========================
    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );

  } catch (err) {
    console.error(" ERROR:", err);

    return new Response(
      JSON.stringify({ error: err.message }),
      {
        status: 500,
        headers: { "Access-Control-Allow-Origin": "*" },
      }
    );
  }
});