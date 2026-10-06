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

type PushTarget = {
  endpoint: string;
  p256dh: string;
  auth: string;
  area: string;
  destination: string;
};

function normalizePlace(raw: string): string {
  let t = (raw ?? "").trim();
  t = t.replace(/[أإآ]/g, "ا").replace(/ة/g, "ه").replace(/ى/g, "ي");
  if (t.startsWith("ال")) t = t.slice(2);
  return t;
}

function samePlace(a: string, b: string): boolean {
  const left = normalizePlace(a);
  const right = normalizePlace(b);
  if (!left || !right) return false;
  if (left === right) return true;
  if (left.length >= 3 && right.length >= 3) {
    return left.includes(right) || right.includes(left);
  }
  return false;
}

function listingPlaces(
  row: {
    area?: string;
    destination?: string;
    origin_subs?: string[] | null;
    destination_subs?: string[] | null;
  },
  origin: boolean,
): string[] {
  const main = origin ? row.area : row.destination;
  const subs = origin ? row.origin_subs : row.destination_subs;
  const out: string[] = [];
  if (main && main.trim()) out.push(main.trim());
  for (const s of subs ?? []) {
    if (s && s.trim()) out.push(s.trim());
  }
  return out;
}

function placesOverlap(a: string[], b: string[]): boolean {
  for (const x of a) {
    for (const y of b) {
      if (samePlace(x, y)) return true;
    }
  }
  return false;
}

async function notifyRouteMatches(
  supabase: ReturnType<typeof createClient>,
  listingId: string,
  sendAll: (targets: PushTarget[], jsonPayload: string) => Promise<void>,
): Promise<void> {
  const { data: published } = await supabase
    .from("listings")
    .select("id, listing_type, area, destination, origin_subs, destination_subs")
    .eq("id", listingId)
    .maybeSingle();
  if (!published) return;

  const opposite = published.listing_type === "driver" ? "rider" : "driver";
  const { data: candidates } = await supabase
    .from("listings")
    .select(
      "id, owner_account_id, area, destination, origin_subs, destination_subs",
    )
    .eq("listing_type", opposite)
    .eq("status", "published")
    .eq("is_hidden", false)
    .neq("id", listingId)
    .limit(400);

  const pubOrigin = listingPlaces(published, true);
  const pubDest = listingPlaces(published, false);
  const ownerIds = new Set<string>();
  for (const cand of candidates ?? []) {
    if (
      !placesOverlap(pubOrigin, listingPlaces(cand, true)) ||
      !placesOverlap(pubDest, listingPlaces(cand, false))
    ) {
      continue;
    }
    const accountId = cand.owner_account_id as string | undefined;
    if (accountId) ownerIds.add(accountId);
  }
  if (ownerIds.size === 0) return;

  const { data: subs } = await supabase
    .from("publisher_push_subscriptions")
    .select("endpoint, p256dh, auth")
    .in("account_id", [...ownerIds]);

  const targets: PushTarget[] = (subs ?? []).map((s) => ({
    endpoint: s.endpoint,
    p256dh: s.p256dh,
    auth: s.auth,
    area: published.area ?? "",
    destination: published.destination ?? "",
  }));
  if (targets.length === 0) return;

  const area = published.area ?? "";
  const destination = published.destination ?? "";
  await sendAll(
    targets,
    JSON.stringify({
      title: "مطابقة جديدة لخطك",
      body: `${area} ← ${destination} — افتح المطابقات للاطلاع`,
      tag: `khutoot-match-${listingId}`,
    }),
  );
}

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
    const unlockId = body?.unlock_id as string | undefined;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    let rows: PushTarget[] = [];
    let payload = "";

    if (unlockId) {
      const { data: unlock, error: unlockErr } = await supabase
        .from("contact_unlocks")
        .select("id, driver_account_id, rider_request_id")
        .eq("id", unlockId)
        .maybeSingle();
      if (unlockErr) {
        return new Response(JSON.stringify({ error: unlockErr.message }), {
          status: 500,
          headers: { ...cors, "Content-Type": "application/json" },
        });
      }
      const accountId = unlock?.driver_account_id as string | undefined;
      const riderId = unlock?.rider_request_id as string | undefined;
      if (!accountId) {
        return new Response(JSON.stringify({ sent: 0 }), {
          headers: { ...cors, "Content-Type": "application/json" },
        });
      }
      const [{ data: listing }, { data: subs }] = await Promise.all([
        riderId
          ? supabase.from("listings").select("area, destination").eq("id", riderId).maybeSingle()
          : Promise.resolve({ data: null }),
        supabase
          .from("publisher_push_subscriptions")
          .select("endpoint, p256dh, auth")
          .eq("account_id", accountId),
      ]);
      const area = listing?.area ?? "";
      const destination = listing?.destination ?? "";
      rows = (subs ?? []).map((s) => ({
        endpoint: s.endpoint,
        p256dh: s.p256dh,
        auth: s.auth,
        area,
        destination,
      }));
      payload = JSON.stringify({
        title: "تم فتح تواصل الراكب",
        body: `${area} ← ${destination} — افتح البطاقة واتساب أو تلغرام`,
        tag: `khutoot-unlock-${unlockId}`,
      });
    } else if (listingId) {
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
      rows = (targets ?? []) as PushTarget[];
      const area = rows[0]?.area ?? "";
      const destination = rows[0]?.destination ?? "";
      payload = JSON.stringify({
        title: "تم تفعيل خطك",
        body: `${area} ← ${destination} — خطك ظاهر الآن في الدليل`,
        tag: `khutoot-publish-${listingId}`,
      });
    } else {
      return new Response(JSON.stringify({ error: "id_required" }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    let sent = 0;
    const sendAll = async (
      targets: PushTarget[],
      jsonPayload: string,
    ) => {
      for (const row of targets) {
        try {
          await webpush.sendNotification(
            {
              endpoint: row.endpoint,
              keys: { p256dh: row.p256dh, auth: row.auth },
            },
            jsonPayload,
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
    };

    if (unlockId) {
      await sendAll(rows, payload);
    } else if (listingId) {
      await sendAll(rows, payload);
      await notifyRouteMatches(supabase, listingId, sendAll);
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
