import { useState } from 'react';
import {
  User, MapPin, Bell, Shield, ChevronRight, LogOut,
  Home, GraduationCap, BookOpen, Dumbbell, Plus,
  Moon, Smartphone, HelpCircle, Star, Edit2, Check,
} from 'lucide-react';

const SAVED_PLACES = [
  { icon: Home,          label: '집',    sub: '광주 광산구 수완동 123', color: '#3b82f6' },
  { icon: GraduationCap, label: '학교',  sub: '광주 동구 필문대로 309', color: '#8b5cf6' },
  { icon: BookOpen,      label: '학원',  sub: '광주 광산구 수완로 45',  color: '#f59e0b' },
  { icon: Dumbbell,      label: '헬스장', sub: '광주 광산구 수완지구',   color: '#10b981' },
];

const MENU = [
  { icon: Bell,        label: '알림 설정',      sub: '막차·출발 알림 관리',     color: '#3b82f6' },
  { icon: Moon,        label: '다크 모드',       sub: '앱 테마 변경',            color: '#6366f1' },
  { icon: Smartphone,  label: '위젯 설정',       sub: '홈 화면 위젯 구성',       color: '#10b981' },
  { icon: Shield,      label: '개인정보 보호',   sub: '데이터 및 권한 관리',     color: '#f59e0b' },
  { icon: HelpCircle,  label: '도움말 / 문의',   sub: '자주 묻는 질문 · 1:1 문의', color: '#64748b' },
  { icon: Star,        label: '앱 평가하기',     sub: '스토어에서 리뷰 작성',    color: '#ef4444' },
];

export default function ProfilePage() {
  const [editingName, setEditingName] = useState(false);
  const [name, setName] = useState('루틴버스 사용자');
  const [tempName, setTempName] = useState(name);
  const [darkMode, setDarkMode] = useState(false);
  const [notifOn, setNotifOn] = useState(true);

  const handleNameSave = () => {
    setName(tempName.trim() || name);
    setEditingName(false);
  };

  return (
    <div className="flex-1 overflow-y-auto pb-24" style={{ background: '#f3f4f6', scrollbarWidth: 'none' }}>

      {/* ── Header card ── */}
      <div style={{ background: '#111827', paddingTop: '56px', paddingBottom: '28px', paddingLeft: '20px', paddingRight: '20px' }}>
        <div className="flex items-center gap-4">
          {/* Avatar */}
          <div className="relative">
            <div className="w-18 h-18 rounded-full flex items-center justify-center"
              style={{ width: 72, height: 72, background: 'linear-gradient(135deg,#3b82f6,#6366f1)' }}>
              <User size={36} color="#ffffff" />
            </div>
            <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full flex items-center justify-center"
              style={{ background: '#39ff14' }}>
              <span style={{ fontSize: '10px', fontWeight: 800, color: '#111111' }}>✓</span>
            </div>
          </div>

          {/* Name / location */}
          <div className="flex-1">
            {editingName ? (
              <div className="flex items-center gap-2">
                <input
                  autoFocus
                  value={tempName}
                  onChange={e => setTempName(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && handleNameSave()}
                  className="flex-1 px-2 py-1 rounded-lg outline-none"
                  style={{ background: '#1f2937', color: '#f1f5f9', fontFamily: "'DM Sans',sans-serif", fontSize: '16px', fontWeight: 700, border: '1px solid #374151' }}
                />
                <button onClick={handleNameSave} className="p-1.5 rounded-full" style={{ background: '#39ff14' }}>
                  <Check size={14} color="#111111" />
                </button>
              </div>
            ) : (
              <div className="flex items-center gap-2">
                <p style={{ fontFamily: "'DM Sans',sans-serif", fontSize: '18px', fontWeight: 700, color: '#f1f5f9' }}>{name}</p>
                <button onClick={() => { setTempName(name); setEditingName(true); }}>
                  <Edit2 size={14} color="#6b7280" />
                </button>
              </div>
            )}
            <div className="flex items-center gap-1 mt-1">
              <MapPin size={12} color="#39ff14" />
              <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '12px', color: '#9ca3af' }}>광주광역시, 대한민국</p>
            </div>
          </div>
        </div>

        {/* Stats row */}
        <div className="flex mt-5 rounded-2xl overflow-hidden" style={{ background: '#1f2937' }}>
          {[
            { label: '저장된 경로', value: '4' },
            { label: '이번 달 탑승', value: '23회' },
            { label: '절약한 시간', value: '1.2h' },
          ].map((s, i) => (
            <div key={i} className="flex-1 flex flex-col items-center py-3"
              style={{ borderRight: i < 2 ? '1px solid #374151' : 'none' }}>
              <p style={{ fontFamily: "'DM Sans',sans-serif", fontSize: '17px', fontWeight: 800, color: '#f1f5f9' }}>{s.value}</p>
              <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '10px', color: '#6b7280', marginTop: '2px' }}>{s.label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* ── Saved places ── */}
      <div className="mx-4 mt-4 rounded-2xl overflow-hidden" style={{ background: '#ffffff', boxShadow: '0 1px 4px rgba(0,0,0,0.06)' }}>
        <div className="flex items-center justify-between px-4 pt-4 pb-2">
          <p style={{ fontFamily: "'DM Sans',sans-serif", fontSize: '14px', fontWeight: 700, color: '#111827' }}>내 장소</p>
          <button className="flex items-center gap-1 px-2.5 py-1 rounded-full" style={{ background: '#f3f4f6' }}>
            <Plus size={12} color="#374151" />
            <span style={{ fontFamily: "'Inter',sans-serif", fontSize: '11px', fontWeight: 600, color: '#374151' }}>추가</span>
          </button>
        </div>
        <div className="grid grid-cols-2 gap-2 px-4 pb-4">
          {SAVED_PLACES.map(p => {
            const Icon = p.icon;
            return (
              <div key={p.label} className="flex items-center gap-3 px-3 py-3 rounded-xl"
                style={{ background: '#f9fafb', border: '1px solid #f3f4f6' }}>
                <div className="w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0"
                  style={{ background: p.color + '18' }}>
                  <Icon size={16} color={p.color} />
                </div>
                <div className="min-w-0">
                  <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '13px', fontWeight: 600, color: '#111827' }}>{p.label}</p>
                  <p className="truncate" style={{ fontFamily: "'Inter',sans-serif", fontSize: '10px', color: '#9ca3af', marginTop: '1px' }}>{p.sub}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* ── Quick toggles ── */}
      <div className="mx-4 mt-3 rounded-2xl overflow-hidden" style={{ background: '#ffffff', boxShadow: '0 1px 4px rgba(0,0,0,0.06)' }}>
        {/* Notification toggle */}
        <div className="flex items-center gap-3 px-4 py-4" style={{ borderBottom: '1px solid #f3f4f6' }}>
          <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0" style={{ background: '#eff6ff' }}>
            <Bell size={18} color="#3b82f6" />
          </div>
          <div className="flex-1">
            <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '14px', fontWeight: 600, color: '#111827' }}>막차 알림</p>
            <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '12px', color: '#9ca3af' }}>출발 10분 전 자동 알림</p>
          </div>
          <button
            onClick={() => setNotifOn(v => !v)}
            className="relative flex-shrink-0 transition-all"
            style={{
              width: 44, height: 26, borderRadius: 999,
              background: notifOn ? '#111827' : '#e5e7eb',
            }}
          >
            <div className="absolute top-1 transition-all"
              style={{
                width: 18, height: 18, borderRadius: '50%',
                background: notifOn ? '#39ff14' : '#ffffff',
                left: notifOn ? 22 : 4,
                boxShadow: '0 1px 4px rgba(0,0,0,0.2)',
              }} />
          </button>
        </div>

        {/* Dark mode toggle */}
        <div className="flex items-center gap-3 px-4 py-4">
          <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0" style={{ background: '#eef2ff' }}>
            <Moon size={18} color="#6366f1" />
          </div>
          <div className="flex-1">
            <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '14px', fontWeight: 600, color: '#111827' }}>다크 모드</p>
            <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '12px', color: '#9ca3af' }}>앱 전체 테마 변경</p>
          </div>
          <button
            onClick={() => setDarkMode(v => !v)}
            className="relative flex-shrink-0 transition-all"
            style={{
              width: 44, height: 26, borderRadius: 999,
              background: darkMode ? '#111827' : '#e5e7eb',
            }}
          >
            <div className="absolute top-1 transition-all"
              style={{
                width: 18, height: 18, borderRadius: '50%',
                background: darkMode ? '#39ff14' : '#ffffff',
                left: darkMode ? 22 : 4,
                boxShadow: '0 1px 4px rgba(0,0,0,0.2)',
              }} />
          </button>
        </div>
      </div>

      {/* ── Menu list ── */}
      <div className="mx-4 mt-3 rounded-2xl overflow-hidden" style={{ background: '#ffffff', boxShadow: '0 1px 4px rgba(0,0,0,0.06)' }}>
        {MENU.filter(m => m.label !== '알림 설정' && m.label !== '다크 모드').map((item, i, arr) => {
          const Icon = item.icon;
          return (
            <button key={item.label} className="w-full flex items-center gap-3 px-4 py-4 transition-colors hover:bg-gray-50"
              style={{ borderBottom: i < arr.length - 1 ? '1px solid #f3f4f6' : 'none' }}>
              <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0"
                style={{ background: item.color + '15' }}>
                <Icon size={18} color={item.color} />
              </div>
              <div className="flex-1 text-left">
                <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '14px', fontWeight: 600, color: '#111827' }}>{item.label}</p>
                <p style={{ fontFamily: "'Inter',sans-serif", fontSize: '12px', color: '#9ca3af', marginTop: '1px' }}>{item.sub}</p>
              </div>
              <ChevronRight size={16} color="#d1d5db" />
            </button>
          );
        })}
      </div>

      {/* ── App version ── */}
      <p className="text-center mt-4 mb-2" style={{ fontFamily: "'Inter',sans-serif", fontSize: '11px', color: '#d1d5db' }}>
        Routine Bus v1.0.0
      </p>

      {/* ── Logout ── */}
      <div className="mx-4 mb-4 rounded-2xl overflow-hidden" style={{ background: '#ffffff', boxShadow: '0 1px 4px rgba(0,0,0,0.06)' }}>
        <button className="w-full flex items-center gap-3 px-4 py-4 hover:bg-red-50 transition-colors">
          <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0" style={{ background: '#fef2f2' }}>
            <LogOut size={18} color="#ef4444" />
          </div>
          <span style={{ fontFamily: "'Inter',sans-serif", fontSize: '14px', fontWeight: 600, color: '#ef4444' }}>로그아웃</span>
        </button>
      </div>

    </div>
  );
}
