import { useCallback, useEffect, useState } from "react";
import { supabase } from "./lib/supabase";
import { AuthView } from "./components/AuthView";
import { HomeView } from "./components/HomeView";
import { CopyView } from "./components/CopyView";
import { SettingsView } from "./components/SettingsView";
import type { Session as UserSession } from "@supabase/supabase-js";
import type { Session } from "./lib/types";

type Tab = "home" | "copy";

export default function App() {
  const [session, setSession] = useState<UserSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<Tab>("home");
  const [selectedSession, setSelectedSession] = useState<Session | null>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [sessions, setSessions] = useState<Session[]>([]);
  const [sessionsLoading, setSessionsLoading] = useState(false);

  const fetchSessions = useCallback(async () => {
    setSessionsLoading(true);
    const { data, error } = await supabase
      .from("sessions")
      .select("*")
      .order("started_at", { ascending: false })
      .limit(200);
    if (!error && data) setSessions(data as Session[]);
    setSessionsLoading(false);
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setSession(session);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (session) fetchSessions();
    else setSessions([]);
  }, [session, fetchSessions]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-text-muted text-xs font-mono tracking-widest">LOADING...</p>
      </div>
    );
  }

  if (!session) {
    return <AuthView />;
  }

  return (
    <div className="min-h-screen flex flex-col bg-background">
      {/* Content area */}
      <div className="flex-1 overflow-auto pb-[88px]">
        {activeTab === "home" && !showSettings && (
          <HomeView
            sessions={sessions}
            loading={sessionsLoading}
            onRefresh={fetchSessions}
            onSessionTap={(s) => {
              setSelectedSession(s);
              setActiveTab("copy");
            }}
            onCopyTap={() => setActiveTab("copy")}
            onSettingsTap={() => setShowSettings(true)}
          />
        )}
        {activeTab === "copy" && !showSettings && (
          <CopyView session={selectedSession} sessions={sessions} />
        )}
        {showSettings && (
          <SettingsView
            email={session.user.email ?? ""}
            onClose={() => setShowSettings(false)}
          />
        )}
      </div>

      {/* Bottom tab bar — matches iOS: 2 icon+label tabs */}
      {!showSettings && (
        <nav className="fixed bottom-0 left-0 right-0 z-40">
          <div className="h-px bg-white/15" />
          <div className="bg-black/80 backdrop-blur-xl">
            <div className="max-w-lg mx-auto flex items-center justify-center gap-[72px] pt-[6px] pb-3">
              <TabButton
                active={activeTab === "home"}
                icon={activeTab === "home" ? "house-fill" : "house"}
                label="Home"
                onClick={() => { setActiveTab("home"); setShowSettings(false); }}
              />
              <TabButton
                active={activeTab === "copy"}
                icon={activeTab === "copy" ? "copy-fill" : "copy"}
                label="Overlays"
                onClick={() => { setActiveTab("copy"); setShowSettings(false); }}
              />
            </div>
          </div>
        </nav>
      )}
    </div>
  );
}

function TabButton({ active, icon, label, onClick }: { active: boolean; icon: string; label: string; onClick: () => void }) {
  const tint = active ? "white" : "rgba(255,255,255,0.45)";
  return (
    <button
      onClick={onClick}
      className="w-16 h-[50px] flex flex-col items-center justify-center gap-[3px]"
    >
      {/* SF Symbol: house.fill */}
      {icon === "house-fill" && (
        <svg className="w-[22px] h-[22px]" fill={tint} viewBox="0 0 22 22">
          <path d="M11 1.5L1 9.5h3v10h5v-6h4v6h5v-10h3L11 1.5z"/>
        </svg>
      )}
      {/* SF Symbol: house */}
      {icon === "house" && (
        <svg className="w-[22px] h-[22px]" fill="none" stroke={tint} strokeWidth={1.2} viewBox="0 0 22 22">
          <path d="M2.5 10L11 2.5 19.5 10M5 9.5v9.5h4.5v-5.5h3v5.5H17V9.5"/>
        </svg>
      )}
      {/* SF Symbol: plus.square.on.square.fill */}
      {icon === "copy-fill" && (
        <svg className="w-[22px] h-[22px]" fill={tint} viewBox="0 0 22 22">
          <rect x="6" y="6" width="14" height="14" rx="3"/>
          <path d="M4 14.5V4a2.5 2.5 0 012.5-2.5H13" stroke={tint} strokeWidth={1.5} fill="none"/>
          <path d="M13 9.5v5M10.5 12h5" stroke="black" strokeWidth={1.5} strokeLinecap="round"/>
        </svg>
      )}
      {/* SF Symbol: plus.square.on.square */}
      {icon === "copy" && (
        <svg className="w-[22px] h-[22px]" fill="none" stroke={tint} strokeWidth={1.2} viewBox="0 0 22 22">
          <rect x="6" y="6" width="14" height="14" rx="3"/>
          <path d="M4 14.5V4a2.5 2.5 0 012.5-2.5H13"/>
          <path d="M13 9.5v5M10.5 12h5" strokeLinecap="round"/>
        </svg>
      )}
      <span
        className="text-[10px] leading-none"
        style={{ color: tint, fontWeight: active ? 600 : 400 }}
      >
        {label}
      </span>
    </button>
  );
}
