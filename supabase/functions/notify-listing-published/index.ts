// Supabase Edge Function: send Web Push when a listing is published.
// Deploy: supabase functions deploy notify-listing-published
// Secrets (set in Supabase Dashboard → Edge Functions → Secrets):
//   VAPID_PUBLIC_KEY=<from lib/core/notifications/push_config.dart>
//   VAPID_PRIVATE_KEY=<private key — do not commit>
//   VAPID_SUBJECT=mailto:admin@khutoot-baghdad.web.app

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import webpush from "npm:web-push@3.6.7";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const vapidPublic = Deno.env.get("VAPID_PUBLIC_KEY") ?? "";
    const vapidPrivate = Deno.env.get("VAPID_PRIVATE_KEY") ?? "";
    const vapidSubject = Deno.env.get("VAPID_SUBJECT") ??
      "mailto:admin@khutoot-baghdad.web.app";
    if (!vapidPublic || !vapidPrivate) {
      return new Response(JSON.stringify({ error: "missing_vapid" }), {
        status: 500,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    webpush.setVapidDetails(vapidSubject, vapidPublic, vapidPrivate);

    const body = await req.json();
    const listingId = body?.listing_id as string | undefined;
    if (!listingId) {
      return new Response(JSON.stringify({ error: "listing_id_required" }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: targets, error } = await supabase.rpc(
      "admin_push_targets_for_listing",
      { p_listing_id: listingId },
    );
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const rows = (targets ?? []) as Array<{
      endpoint: string;
      p256dh: string;
      auth: string;
      area: string;
      destination: string;
    }>;

    if (rows.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const area = rows[0].area ?? "";
    const destination = rows[0].destination ?? "";
    const payload = JSON.stringify({
      title: "تم تفعيل خطك",
      body: `${area} ← ${destination} — خطك ظاهر الآن في الدليل`,
      tag: `khutoot-publish-${listingId}`,
    });

    let sent = 0;
    for (const row of rows) {
      try {
        await webpush.sendNotification(
          {
            endpoint: row.endpoint,
            keys: { p256dh: row.p256dh, auth: row.auth },
          },
          payload,
          { urgency: "high", TTL: 60 * 60 },
        );
        sent += 1;
      } catch (e) {
        const statusCode = (e as { statusCode?: number })?.statusCode;
        if (statusCode === 404 || statusCode === 410) {
          await supabase
            .from("publisher_push_subscriptions")
            .delete()
            .eq("endpoint", row.endpoint);
        }
      }
    }

    return new Response(JSON.stringify({ sent }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      {
        status: 500,
        headers: { ...cors, "Content-Type": "application/json" },
      },
    );
  }
});
