import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const SUPABASE_URL = "https://loaallkwmwgqlxhndwrf.supabase.co";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

serve(async (req) => {
  console.log(" FUNCTION HIT");

  try {
    let body;

    try {
      body = await req.json();
    } catch {
      console.log(" No JSON body received");
      return new Response("Invalid JSON", { status: 400 });
    }

    const email = body?.email;

    if (!email) {
      console.log(" Email missing");
      return new Response("Email required", { status: 400 });
    }

    console.log(" EMAIL RECEIVED:", email);

    const token = Math.floor(1000000 + Math.random() * 9000000).toString();
    console.log(" TOKEN GENERATED:", token);

    // SAVE TOKEN
    const save = await fetch(`${SUPABASE_URL}/rest/v1/password_resets`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "apikey": SERVICE_ROLE_KEY!,
        "Authorization": `Bearer ${SERVICE_ROLE_KEY}`,
      },
      body: JSON.stringify({
        email,
        token,
        expires_at: new Date(Date.now() + 15 * 60 * 1000),
      }),
    });

    console.log(" SAVE STATUS:", save.status);

    // SEND EMAIL
    console.log(" Sending email...");

    const resend = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "onboarding@resend.dev",
        to: email,
        subject: "Reset your password",
        html: `
          <h2>Password Reset</h2>
          <a href="https://mynote-reset-page.vercel.app/?token=${token}">
            Reset Password
          </a>
        `,
      }),
    });

    const text = await resend.text();

    console.log(" RESEND STATUS:", resend.status);
    console.log(" RESEND RESPONSE:", text);

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error(" ERROR:", err);
    return new Response("Server error", { status: 500 });
  }
});