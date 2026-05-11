import posthog from "posthog-js";

const PROJECT_TOKEN = import.meta.env.VITE_POSTHOG_PROJECT_TOKEN;
const HOST = import.meta.env.VITE_POSTHOG_HOST ?? "https://us.i.posthog.com";

let initialized = false;

export function initPostHog() {
  if (initialized) return;
  if (!PROJECT_TOKEN) {
    if (import.meta.env.DEV) {
      console.warn(
        "[PostHog] VITE_POSTHOG_PROJECT_TOKEN not set; analytics disabled.",
      );
    }
    return;
  }
  posthog.init(PROJECT_TOKEN, {
    api_host: HOST,
    capture_pageview: true,
    capture_pageleave: true,
    person_profiles: "identified_only",
  });
  initialized = true;
}

export function identify(
  distinctId: string,
  userProperties?: Record<string, unknown>,
) {
  if (!initialized) return;
  posthog.identify(distinctId, userProperties);
}

export function reset() {
  if (!initialized) return;
  posthog.reset();
}

export function capture(
  event: string,
  properties?: Record<string, unknown>,
) {
  if (!initialized) return;
  posthog.capture(event, properties);
}

export { posthog };
