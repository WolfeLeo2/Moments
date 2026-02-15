import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Plivo Credentials from Environment Variables
const PLIVO_AUTH_ID = Deno.env.get("PLIVO_AUTH_ID")!;
const PLIVO_AUTH_TOKEN = Deno.env.get("PLIVO_AUTH_TOKEN")!;
const PLIVO_SOURCE_NUMBER = Deno.env.get("PLIVO_SOURCE_NUMBER") || "MomentsApp"; // Sender ID or Number

interface SmsHookParams {
  user: {
    id: string;
    phone: string;
  };
  otp: string;
  metadata?: any;
}

serve(async (req) => {
  try {
    const { user, otp } = await req.json() as SmsHookParams;

    if (!user || !user.phone || !otp) {
      return new Response(JSON.stringify({ error: "Missing user, phone, or otp" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`Sending OTP ${otp} to ${user.phone}`);

    // Construct Basic Auth Header
    const authString = btoa(`${PLIVO_AUTH_ID}:${PLIVO_AUTH_TOKEN}`);

    // Call Plivo API
    const response = await fetch(
      `https://api.plivo.com/v1/Account/${PLIVO_AUTH_ID}/Message/`,
      {
        method: "POST",
        headers: {
          "Authorization": `Basic ${authString}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          src: PLIVO_SOURCE_NUMBER,
          dst: user.phone,
          text: `Your Moments verification code is: ${otp}`,
        }),
      }
    );

    const result = await response.json();

    if (!response.ok) {
      console.error("Plivo Error:", result);
      return new Response(JSON.stringify({ error: "Failed to send SMS via Plivo", details: result }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log("Plivo Success:", result);

    return new Response(JSON.stringify({ success: true, messageId: result.message_uuid }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Function Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
