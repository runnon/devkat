import { useState } from "react";
import type { Session } from "../lib/types";
import { formatDuration, formatTokens, linesPerHour } from "../lib/types";
import { OverlayTiles } from "./OverlayTiles";

type CopyTab = "activity" | "totals";

export function CopyView({ session }: { session: Session | null }) {
  const [toast, setToast] = useState<string | null>(null);
  const [tab, setTab] = useState<CopyTab>("activity");
  const [selectedStatId, setSelectedStatId] = useState("duration");
  const [showStatPicker, setShowStatPicker] = useState(false);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 1400);
  }

  return (
    <div className="max-w-lg mx-auto relative">
      {/* When no session: just empty state, no header/tabs */}
      {!session ? (
        <div className="flex flex-col items-center justify-center min-h-[70vh] gap-[16px]">
          <p className="text-[12px] font-bold font-mono text-text-dim tracking-[0.15em]">
            PICK A SESSION ON HOME
          </p>
          <p className="text-[12px] font-mono text-text-muted">
            to start composing an overlay
          </p>
        </div>
      ) : (
        <>
          {/* Header */}
          <div className="text-center py-[14px] space-y-[6px]">
            <div className="flex items-center justify-center gap-[6px] text-text">
              <svg className="w-3 h-3" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />
              </svg>
              <span className="text-[11px] font-bold font-mono tracking-[0.15em]">TAP TO COPY</span>
            </div>
            <div className="flex items-center justify-center gap-[6px] text-text-dim">
              <svg className="w-2.5 h-2.5" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
              </svg>
              <span className="text-[10px] font-bold font-mono tracking-[0.15em]">PRESS + HOLD TO SAVE</span>
            </div>
          </div>

          {/* Tab bar */}
          <div className="flex px-[16px] pb-[4px]">
            <TabButton label="Activity" active={tab === "activity"} onClick={() => setTab("activity")} />
            <TabButton label="Totals" active={tab === "totals"} onClick={() => setTab("totals")} />
          </div>

          {/* Content */}
          {tab === "activity" ? (
            <div className="px-[16px] pt-[12px] pb-[100px]">
              <OverlayTiles
                session={session}
                selectedStatId={selectedStatId}
                onStatPickerOpen={() => setShowStatPicker(true)}
                onCopied={() => showToast("Copied!")}
                onSaved={() => showToast("Saved!")}
              />
            </div>
          ) : (
            <div className="px-[16px] pt-[12px] pb-[100px]">
              <WeeklyTotals session={session} onCopied={() => showToast("Copied!")} />
            </div>
          )}
        </>
      )}

      {/* Toast */}
      {toast && (
        <div className="fixed inset-0 flex items-center justify-center pointer-events-none z-50">
          <span className="text-white font-semibold text-[17px] px-8 py-[18px] bg-white/10 backdrop-blur-xl rounded-2xl">
            {toast}
          </span>
        </div>
      )}

      {/* Stat picker modal */}
      {showStatPicker && session && (
        <StatPickerSheet
          session={session}
          selectedStatId={selectedStatId}
          onSelect={(id) => { setSelectedStatId(id); setShowStatPicker(false); }}
          onClose={() => setShowStatPicker(false)}
        />
      )}
    </div>
  );
}

function TabButton({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button onClick={onClick} className="flex-1">
      <div className="space-y-2">
        <p className={`text-[14px] text-center ${active ? "font-semibold text-white" : "text-white/40"}`}>
          {label}
        </p>
        <div className={`h-px ${active ? "bg-white" : "bg-transparent"}`} />
      </div>
    </button>
  );
}

function StatPickerSheet({
  session,
  selectedStatId,
  onSelect,
  onClose,
}: {
  session: Session;
  selectedStatId: string;
  onSelect: (id: string) => void;
  onClose: () => void;
}) {
  const stats = getStatSlots(session);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center" onClick={onClose}>
      <div className="absolute inset-0 bg-black/50" />
      <div
        className="relative w-full max-w-lg bg-surface-raised rounded-t-2xl px-5 pt-4 pb-8"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="w-9 h-1 bg-white/30 rounded-full mx-auto mb-4" />
        <div className="grid grid-cols-3 gap-3">
          {stats.map((stat) => (
            <button
              key={stat.id}
              onClick={() => onSelect(stat.id)}
              className={`flex flex-col items-center py-[22px] bg-surface rounded-[14px] border ${
                stat.id === selectedStatId ? "border-white" : "border-white/[0.12]"
              }`}
            >
              <span className="text-[12px] text-white/50 font-serif">
                {stat.label}
              </span>
              <span className="text-[17px] text-white mt-1 font-serif">
                {stat.display}
              </span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

function WeeklyTotals({ session }: { session: Session; onCopied: () => void }) {
  const dur = formatDuration(session.active_duration);
  const pace = linesPerHour(session);
  const burn = session.tokens > 0 ? `${formatTokens(session.tokens)} tokens` : "—";

  return (
    <div className="grid grid-cols-2 gap-3">
      <div className="aspect-[1.6] bg-surface rounded-[14px] border border-white/[0.12] flex items-center justify-center px-[14px] py-[12px]">
        <div className="flex flex-col items-start gap-[4px]">
          <p className="text-[9px] font-bold text-white font-serif leading-none">
            This Week
          </p>
          {[dur, `${pace} lines/hr`, burn].map((v, i) => (
            <span
              key={i}
              className="text-[12px] text-white italic font-serif leading-tight whitespace-nowrap"
            >
              {v}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}

interface StatSlotWeb {
  id: string;
  label: string;
  display: string;
}

function getStatSlots(session: Session): StatSlotWeb[] {
  const volume = session.lines_added + session.lines_removed;
  return [
    { id: "duration", label: "Duration", display: formatDuration(session.active_duration) },
    { id: "pace", label: "Pace", display: `${linesPerHour(session)} lines/hr` },
    { id: "scope", label: "Scope", display: `${session.files_touched} files` },
    { id: "volume", label: "Volume", display: `${volume} lines` },
    { id: "burn", label: "Burn", display: session.tokens > 0 ? `${formatTokens(session.tokens)} tokens` : "—" },
  ];
}
