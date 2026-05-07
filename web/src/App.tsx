import { useEffect, useState } from "react";
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
      <div className="flex-1 overflow-auto pb-[70px]">
        {activeTab === "home" && !showSettings && (
          <HomeView
            onSessionTap={(s) => {
              setSelectedSession(s);
              setActiveTab("copy");
            }}
            onCopyTap={() => setActiveTab("copy")}
            onSettingsTap={() => setShowSettings(true)}
          />
        )}
        {activeTab === "copy" && !showSettings && (
          <CopyView session={selectedSession} />
        )}
        {showSettings && (
          <SettingsView
            email={session.user.email ?? ""}
            onClose={() => setShowSettings(false)}
          />
        )}
      </div>

      {/* Bottom tab bar — matches iOS: 2 icon tabs */}
      {!showSettings && (
        <nav className="fixed bottom-0 left-0 right-0 z-40">
          <div className="h-px bg-white/15" />
          <div className="bg-black/80 backdrop-blur-xl">
            <div className="max-w-lg mx-auto flex items-center justify-center gap-[72px] py-3">
              <TabIcon
                active={activeTab === "home"}
                icon={activeTab === "home" ? "house-fill" : "house"}
                onClick={() => { setActiveTab("home"); setShowSettings(false); }}
              />
              <TabIcon
                active={activeTab === "copy"}
                icon={activeTab === "copy" ? "copy-fill" : "copy"}
                onClick={() => { setActiveTab("copy"); setShowSettings(false); }}
              />
            </div>
          </div>
        </nav>
      )}
    </div>
  );
}

function TabIcon({ icon, onClick }: { active: boolean; icon: string; onClick: () => void }) {
  return (
    <button onClick={onClick} className="w-14 h-[50px] flex items-center justify-center">
      {/* SF Symbol: house.fill */}
      {icon === "house-fill" && (
        <svg className="w-[22px] h-[22px]" fill="white" viewBox="0 0 22 22">
          <path d="M11 1.5L1 9.5h3v10h5v-6h4v6h5v-10h3L11 1.5z"/>
        </svg>
      )}
      {/* SF Symbol: house */}
      {icon === "house" && (
        <svg className="w-[22px] h-[22px] opacity-45" fill="none" stroke="white" strokeWidth={1.2} viewBox="0 0 22 22">
          <path d="M2.5 10L11 2.5 19.5 10M5 9.5v9.5h4.5v-5.5h3v5.5H17V9.5"/>
        </svg>
      )}
      {/* SF Symbol: plus.square.on.square.fill */}
      {icon === "copy-fill" && (
        <svg className="w-[22px] h-[22px]" fill="white" viewBox="0 0 22 22">
          <rect x="6" y="6" width="14" height="14" rx="3"/>
          <path d="M4 14.5V4a2.5 2.5 0 012.5-2.5H13" stroke="white" strokeWidth={1.5} fill="none"/>
          <path d="M13 9.5v5M10.5 12h5" stroke="black" strokeWidth={1.5} strokeLinecap="round"/>
        </svg>
      )}
      {/* SF Symbol: plus.square.on.square */}
      {icon === "copy" && (
        <svg className="w-[22px] h-[22px] opacity-45" fill="none" stroke="white" strokeWidth={1.2} viewBox="0 0 22 22">
          <rect x="6" y="6" width="14" height="14" rx="3"/>
          <path d="M4 14.5V4a2.5 2.5 0 012.5-2.5H13"/>
          <path d="M13 9.5v5M10.5 12h5" strokeLinecap="round"/>
        </svg>
      )}
    </button>
  );
}
