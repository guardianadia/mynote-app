import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import bcrypt from "npm:bcrypt";

const SUPABASE_URL = "https://loaallkwmwgqlxhndwrf.supabase.co";
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY");

//  CORS
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { token, password } = await req.json();

    //  Password validation
    const strongPassword =
      /^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$/;

    if (!strongPassword.test(password)) {
      return new Response(
        JSON.stringify({ error: "Weak password" }),
        { status: 400, headers: corsHeaders }
      );
    }

    //  Find reset token
    const tokenRes = await fetch(
      `${SUPABASE_URL}/rest/v1/password_resets?token=eq.${token}&limit=1`,
      {
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        },
      }
    );

    const tokenData = await tokenRes.json();

    if (!tokenData.length) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 400, headers: corsHeaders }
      );
    }

    const reset = tokenData[0];

    //  Check expiration
    if (new Date(reset.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({ error: "Token expired" }),
        { status: 400, headers: corsHeaders }
      );
    }

    const email = reset.email;

    //  Get user
    const userRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?recovery_email=eq.${email}`,
      {
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        },
      }
    );

    const users = await userRes.json();

    if (!users.length) {
      return new Response(
        JSON.stringify({ error: "User not found" }),
        { status: 404, headers: corsHeaders }
      );
    }

    const user = users[0];

    //  Hash for history
    const newHash = await bcrypt.hash(password, 10);

    //  Prevent reuse
    if (user.password_history) {
      for (const oldHash of user.password_history) {
        const match = await bcrypt.compare(password, oldHash);
        if (match) {
          return new Response(
            JSON.stringify({ error: "Cannot reuse old password" }),
            { status: 400, headers: corsHeaders }
          );
        }
      }
    }

    const updatedHistory = [
      ...(user.password_history || []),
      user.password,
    ];

    //  UPDATE AUTH PASSWORD
    const authUpdate = await fetch(
      `${SUPABASE_URL}/auth/v1/admin/users/${user.id}`,
      {
        method: "PUT",
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          password: password,
        }),
      }
    );

    if (!authUpdate.ok) {
      const err = await authUpdate.text();
      return new Response(
        JSON.stringify({ error: err }),
        { status: 500, headers: corsHeaders }
      );
    }

    //  Update profile history
    await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?id=eq.${user.id}`,
      {
        method: "PATCH",
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          password: newHash,
          password_history: updatedHistory,
        }),
      }
    );

    //  Delete token
    await fetch(
      `${SUPABASE_URL}/rest/v1/password_resets?token=eq.${token}`,
      {
        method: "DELETE",
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        },
      }
    );

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: corsHeaders }
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: corsHeaders }
    );
  }
});