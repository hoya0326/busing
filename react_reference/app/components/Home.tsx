import { useState, useRef } from 'react';
import {
  Home, GraduationCap, BookOpen, Dumbbell, Clock,
  Navigation, Search, X, MapPin, ChevronRight, ArrowRight,
} from 'lucide-react';

/* ─────────────────────────────────────────
   Dark map SVG (tap-to-pin enabled)
───────────────────────────────────────── */
interface Pin { x: number; y: number; type: 'depart' | 'arrive' }

const DarkMap = ({
  pins,
  pendingType,
  onTap,
}: {
  pins: Pin[];
  pendingType: 'depart' | 'arrive' | null;
  onTap: (x: number, y: number) => void;
}) => {
  const svgRef = useRef<SVGSVGElement>(null);

  const handleClick = (e: React.MouseEvent<SVGSVGElement>) => {
    if (!pendingType) return;
    const rect = svgRef.current!.getBoundingClientRect();
    onTap(
      ((e.clientX - rect.left) / rect.width) * 390,
      ((e.clientY - rect.top) / rect.height) * 440,
    );
  };

  const depart = pins.find(p => p.type === 'depart') ?? { x: 162, y: 240 };
  const arrive = pins.find(p => p.type === 'arrive');

  return (
    <svg
      ref={svgRef}
      viewBox="0 0 390 440"
      xmlns="http://www.w3.org/2000/svg"
      className="w-full h-full"
      style={{ cursor: pendingType ? 'crosshair' : 'default' }}
      onClick={handleClick}
    >
      <defs>
        <filter id="dm-glow"><feGaussianBlur stdDeviation="3.5" result="b" /><feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge></filter>
        <filter id="dm-shadow"><feDropShadow dx="0" dy="3" stdDeviation="4" floodColor="#000" floodOpacity="0.5" /></filter>
        <radialGradient id="gps-h" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.28" />
          <stop offset="100%" stopColor="#3b82f6" stopOpacity="0" />
        </radialGradient>
        <linearGradient id="map-fade" x1="0" y1="0" x2="0" y2="1">
          <stop offset="55%" stopColor="#1a1a2a" stopOpacity="0" />
          <stop offset="100%" stopColor="#1a1a2a" stopOpacity="0.75" />
        </linearGradient>
      </defs>

      {/* Ground */}
      <rect width="390" height="440" fill="#1a1a2a" />

      {/* Blocks */}
      {([
        [6,6,74,52],[88,6,56,52],[152,6,80,52],[240,6,60,52],[308,6,74,52],
        [6,66,74,38],[88,66,56,38],[240,66,60,38],[308,66,74,38],
        [6,112,74,50],[88,112,56,50],[240,112,60,50],[308,112,74,50],
        [6,170,74,42],[88,170,56,42],[240,170,60,42],[308,170,74,42],
        [6,220,74,36],[88,220,56,36],[240,220,60,36],[308,220,74,36],
        [6,264,74,42],[88,264,56,42],[152,264,80,42],[240,264,60,42],[308,264,74,42],
        [6,314,74,42],[88,314,56,42],[152,314,80,42],[240,314,60,42],[308,314,74,42],
        [6,364,74,68],[88,364,56,68],[152,364,80,68],[240,364,60,68],[308,364,74,68],
      ] as [number,number,number,number][]).map(([x,y,w,h],i) => (
        <rect key={i} x={x} y={y} width={w} height={h} rx="3"
          fill={i%3===0?'#222236':i%3===1?'#1e1e30':'#232338'} />
      ))}

      {/* Roads */}
      {[58,106,162,212,256,306,356].map(y => (
        <rect key={y} x="0" y={y} width="390" height="8" fill="#2e2e46" />
      ))}
      {[80,144,232,300].map(x => (
        <rect key={x} x={x} y="0" width="8" height="440" fill="#2e2e46" />
      ))}
      {/* Boulevard */}
      <rect x="0"   y="210" width="390" height="12" fill="#353550" />
      <rect x="144" y="0"   width="12"  height="440" fill="#353550" />
      <line x1="0" y1="216" x2="390" y2="216" stroke="#4a4a6a" strokeWidth="1" strokeDasharray="14 9" />
      <line x1="150" y1="0" x2="150" y2="440" stroke="#4a4a6a" strokeWidth="1" strokeDasharray="14 9" />

      {/* POIs */}
      <circle cx="42"  cy="36"  r="4" fill="#f97316" opacity="0.85" />
      <circle cx="115" cy="84"  r="3" fill="#a78bfa" opacity="0.8" />
      <circle cx="275" cy="46"  r="4" fill="#f97316" opacity="0.85" />
      <circle cx="330" cy="138" r="3" fill="#60a5fa" opacity="0.8" />
      <circle cx="55"  cy="290" r="3" fill="#a78bfa" opacity="0.8" />
      <circle cx="268" cy="340" r="4" fill="#f97316" opacity="0.85" />

      {/* Route line */}
      {arrive && <>
        <polyline
          points={`${depart.x},${depart.y} ${depart.x},${(depart.y+arrive.y)/2} ${arrive.x},${(depart.y+arrive.y)/2} ${arrive.x},${arrive.y}`}
          fill="none" stroke="#3b82f6" strokeWidth="9"
          strokeLinecap="round" strokeLinejoin="round" strokeOpacity="0.2"
          filter="url(#dm-glow)"
        />
        <polyline
          points={`${depart.x},${depart.y} ${depart.x},${(depart.y+arrive.y)/2} ${arrive.x},${(depart.y+arrive.y)/2} ${arrive.x},${arrive.y}`}
          fill="none" stroke="#60a5fa" strokeWidth="3.5"
          strokeLinecap="round" strokeLinejoin="round" strokeDasharray="10 6"
        />
      </>}

      {/* Tap overlay hint */}
      {pendingType && (
        <rect width="390" height="440"
          fill={pendingType==='depart'?'rgba(59,130,246,0.06)':'rgba(239,68,68,0.06)'} />
      )}

      {/* GPS departure */}
      <circle cx={depart.x} cy={depart.y} r="30" fill="url(#gps-h)" />
      <circle cx={depart.x} cy={depart.y} r="11" fill="#fff" />
      <circle cx={depart.x} cy={depart.y} r="8"  fill="#3b82f6" filter="url(#dm-glow)" />
      <circle cx={depart.x} cy={depart.y} r="4"  fill="#fff" />
      <rect   x={depart.x-36} y={depart.y-46} width="72" height="26" rx="13" fill="#111111" filter="url(#dm-shadow)" />
      <text   x={depart.x} y={depart.y-28} textAnchor="middle" fill="#39ff14" fontSize="11" fontWeight="700" fontFamily="'Inter',sans-serif" letterSpacing="0.8">출발</text>
      <line   x1={depart.x} y1={depart.y-20} x2={depart.x} y2={depart.y-12} stroke="#111111" strokeWidth="2" />

      {/* Arrival pin */}
      {arrive && <>
        <circle cx={arrive.x} cy={arrive.y} r="13" fill="#ef4444" filter="url(#dm-shadow)" />
        <circle cx={arrive.x} cy={arrive.y} r="9"  fill="#dc2626" />
        <circle cx={arrive.x} cy={arrive.y} r="4"  fill="#fff" />
        <rect   x={arrive.x-36} y={arrive.y-48} width="72" height="26" rx="13" fill="#111111" filter="url(#dm-shadow)" />
        <text   x={arrive.x} y={arrive.y-30} textAnchor="middle" fill="#fca5a5" fontSize="11" fontWeight="700" fontFamily="'Inter',sans-serif" letterSpacing="0.8">도착</text>
        <line   x1={arrive.x} y1={arrive.y-22} x2={arrive.x} y2={arrive.y-14} stroke="#111111" strokeWidth="2" />
      </>}

      <rect width="390" height="440" fill="url(#map-fade)" />
    </svg>
  );
};

/* ─────────────────────────────────────────
   Search overlay (dark theme)
───────────────────────────────────────── */
const SUGGESTIONS = [
  { icon: Home,          label: '우리집',         sub: '광주 광산구 수완동 123' },
  { icon: GraduationCap, label: '조선대학교',      sub: '광주 동구 필문대로 309' },
  { icon: MapPin,        label: '수완버스터미널',  sub: '광주 광산구 수완동' },
  { icon: BookOpen,      label: '수완학원',         sub: '광주 광산구 수완로 45' },
  { icon: Dumbbell,      label: '스포애니 헬스장', sub: '광주 광산구 수완지구' },
  { icon: MapPin,        label: '광주송정역',       sub: '광주 광산구 송정2동' },
  { icon: MapPin,        label: '조선대학교 후문',  sub: '광주 동구 서석동' },
];

const SearchOverlay = ({
  mode, value, onChange, onClose, onSelect,
}: {
  mode: 'depart' | 'arrive';
  value: string;
  onChange: (v: string) => void;
  onClose: () => void;
  onSelect: (label: string) => void;
}) => {
  const filtered = SUGGESTIONS.filter(s =>
    !value || s.label.includes(value) || s.sub.includes(value)
  );
  return (
    <div className="absolute inset-0 z-50 flex flex-col" style={{ background: '#181824' }}>
      <div className="px-4 pt-14 pb-4" style={{ borderBottom: '1px solid #2e2e46' }}>
        <div className="flex items-center gap-2 mb-4">
          <button onClick={onClose} className="p-1.5 rounded-full" style={{ background: '#2e2e46' }}>
            <X size={18} color="#e2e8f0" />
          </button>
          <span style={{ fontFamily:"'DM Sans',sans-serif", fontSize:'16px', fontWeight:700, color:'#f1f5f9' }}>
            {mode==='depart' ? '출발지 설정' : '도착지 설정'}
          </span>
        </div>
        <div className="flex items-center gap-3 px-4 py-3 rounded-2xl" style={{
          background:'#222236',
          border:`1.5px solid ${mode==='depart'?'#3b82f6':'#ef4444'}`,
          boxShadow:`0 0 0 3px ${mode==='depart'?'rgba(59,130,246,0.15)':'rgba(239,68,68,0.15)'}`,
        }}>
          <div className="w-3 h-3 rounded-full flex-shrink-0"
            style={{ background: mode==='depart'?'#3b82f6':'#ef4444' }} />
          <input autoFocus
            placeholder={mode==='depart'?'출발지 입력...':'도착지 입력...'}
            value={value} onChange={e=>onChange(e.target.value)}
            className="flex-1 outline-none bg-transparent"
            style={{ fontFamily:"'Inter',sans-serif", fontSize:'14px', color:'#f1f5f9' }}
          />
          {value && <button onClick={()=>onChange('')}><X size={14} color="#64748b" /></button>}
        </div>
        <button onClick={onClose} className="mt-3 w-full flex items-center justify-center gap-2 py-2.5 rounded-xl"
          style={{ background:'#2e2e46', border:'1px solid #3e3e5e' }}>
          <MapPin size={14} color="#60a5fa" />
          <span style={{ fontFamily:"'Inter',sans-serif", fontSize:'13px', fontWeight:500, color:'#93c5fd' }}>
            지도에서 직접 선택하기
          </span>
        </button>
      </div>
      <div className="flex-1 overflow-y-auto" style={{ scrollbarWidth:'none' }}>
        <p className="px-4 pt-4 pb-2" style={{ fontFamily:"'Inter',sans-serif", fontSize:'11px', fontWeight:600, color:'#4a4a6a', letterSpacing:'0.5px', textTransform:'uppercase' }}>
          즐겨찾는 장소
        </p>
        {filtered.map((s,i)=>{
          const Icon=s.icon;
          return (
            <button key={i} className="w-full flex items-center gap-3 px-4 py-3.5"
              style={{ borderBottom:'1px solid #1e1e30' }}
              onClick={()=>onSelect(s.label)}>
              <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0" style={{ background:'#2e2e46' }}>
                <Icon size={17} color="#94a3b8" />
              </div>
              <div className="text-left flex-1">
                <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'14px', fontWeight:600, color:'#f1f5f9' }}>{s.label}</p>
                <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'12px', color:'#64748b', marginTop:'1px' }}>{s.sub}</p>
              </div>
              <ChevronRight size={16} color="#3e3e5e" />
            </button>
          );
        })}
      </div>
    </div>
  );
};

/* ─────────────────────────────────────────
   Main HomePage
───────────────────────────────────────── */
const PLACES = [
  { label:'집',    icon:Home },
  { label:'학교',  icon:GraduationCap },
  { label:'학원',  icon:BookOpen },
  { label:'헬스장', icon:Dumbbell },
];

export default function HomePage() {
  const [activePlace, setActivePlace] = useState(0);
  const [departLabel, setDepartLabel] = useState('현재 위치');
  const [arriveLabel, setArriveLabel] = useState('');
  const [departInput, setDepartInput] = useState('');
  const [arriveInput, setArriveInput]  = useState('');
  const [searchMode, setSearchMode]   = useState<'depart'|'arrive'|null>(null);
  const [mapPending, setMapPending]   = useState<'depart'|'arrive'|null>(null);
  const [pins, setPins] = useState<Pin[]>([{ x:162, y:240, type:'depart' }]);

  const handleMapTap = (x: number, y: number) => {
    if (!mapPending) return;
    setPins(prev => [...prev.filter(p=>p.type!==mapPending), { x, y, type:mapPending }]);
    if (mapPending==='depart') setDepartLabel('지도에서 선택한 위치');
    else setArriveLabel('지도에서 선택한 위치');
    setMapPending(null);
  };

  const handleSelect = (label: string) => {
    if (searchMode==='depart') { setDepartLabel(label); setDepartInput(''); }
    else { setArriveLabel(label); setArriveInput(''); }
    setSearchMode(null);
  };

  const hasRoute = departLabel !== '' && arriveLabel !== '';

  return (
    <div className="flex-1 flex flex-col overflow-hidden relative" style={{ background:'#1a1a2a' }}>

      {/* Search overlay */}
      {searchMode && (
        <SearchOverlay
          mode={searchMode}
          value={searchMode==='depart'?departInput:arriveInput}
          onChange={searchMode==='depart'?setDepartInput:setArriveInput}
          onClose={()=>setSearchMode(null)}
          onSelect={handleSelect}
        />
      )}

      {/* ── Map (top ~58%) ── */}
      <div style={{ height:'58%', position:'relative', flexShrink:0, overflow:'hidden' }}>
        <DarkMap pins={pins} pendingType={mapPending} onTap={handleMapTap} />

        {/* App name */}
        <div className="absolute top-0 left-0 right-0 px-5 pt-14 pointer-events-none z-10">
          <h1 style={{ fontFamily:"'DM Sans',sans-serif", fontSize:'20px', fontWeight:700, color:'#f1f5f9' }}>
            Routine Bus
          </h1>
        </div>

        {/* Floating search bar */}
        <div className="absolute left-4 right-4 z-10" style={{ top:'88px' }}>
          <div className="flex gap-2">
            {/* Depart */}
            <button onClick={()=>{ setMapPending(null); setSearchMode('depart'); }}
              className="flex-1 flex items-center gap-2 px-3 py-2.5 rounded-xl"
              style={{ background:'rgba(255,255,255,0.95)', boxShadow:'0 2px 16px rgba(0,0,0,0.22)', border:'1.5px solid #e5e7eb' }}>
              <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ background:'#22c55e' }} />
              <span className="truncate" style={{ fontFamily:"'Inter',sans-serif", fontSize:'12px', fontWeight:departLabel?600:400, color:departLabel?'#111827':'#9ca3af' }}>
                {departLabel || '출발지'}
              </span>
            </button>
            <div className="flex items-center"><ArrowRight size={14} color="#9ca3af" /></div>
            {/* Arrive */}
            <button onClick={()=>{ setMapPending(null); setSearchMode('arrive'); }}
              className="flex-1 flex items-center gap-2 px-3 py-2.5 rounded-xl"
              style={{ background:'rgba(255,255,255,0.95)', boxShadow:'0 2px 16px rgba(0,0,0,0.22)', border:`1.5px solid ${arriveLabel?'#3b82f6':'#e5e7eb'}` }}>
              <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ background: arriveLabel?'#ef4444':'#d1d5db' }} />
              <span className="truncate" style={{ fontFamily:"'Inter',sans-serif", fontSize:'12px', fontWeight:arriveLabel?600:400, color:arriveLabel?'#111827':'#9ca3af' }}>
                {arriveLabel || '도착지'}
              </span>
              {arriveLabel && (
                <button onClick={e=>{ e.stopPropagation(); setArriveLabel(''); setPins(p=>p.filter(x=>x.type!=='arrive')); }}
                  className="ml-auto flex-shrink-0"><X size={12} color="#9ca3af" /></button>
              )}
            </button>
          </div>
          {/* Map pin buttons */}
          <div className="flex gap-2 mt-1.5">
            <button onClick={()=>setMapPending(mapPending==='depart'?null:'depart')}
              className="flex items-center gap-1 px-2.5 py-1 rounded-full"
              style={{ background: mapPending==='depart'?'#1d4ed8':'rgba(30,30,48,0.85)', border:'1px solid rgba(255,255,255,0.1)' }}>
              <MapPin size={11} color={mapPending==='depart'?'#93c5fd':'#60a5fa'} />
              <span style={{ fontFamily:"'Inter',sans-serif", fontSize:'10px', fontWeight:600, color:mapPending==='depart'?'#bfdbfe':'#93c5fd' }}>지도에서 출발 선택</span>
            </button>
            <button onClick={()=>setMapPending(mapPending==='arrive'?null:'arrive')}
              className="flex items-center gap-1 px-2.5 py-1 rounded-full"
              style={{ background: mapPending==='arrive'?'#991b1b':'rgba(30,30,48,0.85)', border:'1px solid rgba(255,255,255,0.1)' }}>
              <MapPin size={11} color={mapPending==='arrive'?'#fca5a5':'#f87171'} />
              <span style={{ fontFamily:"'Inter',sans-serif", fontSize:'10px', fontWeight:600, color:mapPending==='arrive'?'#fecaca':'#fca5a5' }}>지도에서 도착 선택</span>
            </button>
          </div>
        </div>

        {/* Map-tap banner */}
        {mapPending && (
          <div className="absolute left-1/2 z-20 flex items-center gap-2 px-4 py-2 rounded-full"
            style={{ top:'168px', transform:'translateX(-50%)',
              background: mapPending==='depart'?'#1d4ed8':'#b91c1c',
              boxShadow:'0 4px 20px rgba(0,0,0,0.4)' }}>
            <MapPin size={13} color="#fff" />
            <span style={{ fontFamily:"'Inter',sans-serif", fontSize:'12px', fontWeight:600, color:'#fff', whiteSpace:'nowrap' }}>
              {mapPending==='depart'?'지도를 탭해 출발지를 설정하세요':'지도를 탭해 도착지를 설정하세요'}
            </span>
            <button onClick={()=>setMapPending(null)}><X size={13} color="rgba(255,255,255,0.7)" /></button>
          </div>
        )}

        {/* GPS recenter */}
        <button className="absolute bottom-4 right-4 w-10 h-10 rounded-full flex items-center justify-center z-10"
          style={{ background:'#222236', boxShadow:'0 2px 12px rgba(0,0,0,0.4)', border:'1px solid #2e2e46' }}>
          <Navigation size={16} color="#60a5fa" />
        </button>
      </div>

      {/* ── Bottom Sheet (version 7 style) ── */}
      <div className="flex flex-col overflow-hidden"
        style={{
          height:'42%',
          background:'#f9fafb',
          borderRadius:'22px 22px 0 0',
          boxShadow:'0 -4px 28px rgba(0,0,0,0.22)',
          position:'relative',
          zIndex:20,
          marginTop:'-18px',
        }}>

        {/* Handle */}
        <div className="flex justify-center pt-3 pb-1">
          <div style={{ width:36, height:4, borderRadius:999, background:'#d1d5db' }} />
        </div>

        {/* My Places */}
        <div className="px-4 pt-1 pb-3">
          <div className="flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth:'none' }}>
            {PLACES.map((p,i)=>{
              const Icon=p.icon; const active=i===activePlace;
              return (
                <button key={p.label} onClick={()=>setActivePlace(i)}
                  className="flex items-center gap-1.5 px-3 py-2 rounded-full flex-shrink-0 transition-all"
                  style={{
                    background: active?'#111827':'#ffffff',
                    color: active?'#ffffff':'#374151',
                    border: active?'1.5px solid #111827':'1.5px solid #e5e7eb',
                    fontFamily:"'Inter',sans-serif", fontSize:'13px',
                    fontWeight: active?600:500,
                    boxShadow: active?'0 2px 8px rgba(0,0,0,0.18)':'0 1px 3px rgba(0,0,0,0.05)',
                  }}>
                  <Icon size={13} color={active?'#39ff14':'#6b7280'} />
                  {p.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Title */}
        <div className="px-4 mb-2">
          <p style={{ fontFamily:"'DM Sans',sans-serif", fontSize:'14px', fontWeight:700, color:'#111827' }}>
            집으로 가는 가장 빠른 경로
          </p>
        </div>

        {/* Route cards */}
        <div className="px-4 flex flex-col gap-2.5 overflow-y-auto pb-24" style={{ scrollbarWidth:'none' }}>

          {/* Card 1 — Green */}
          <div style={{ background:'#ffffff', borderRadius:'16px', padding:'14px 16px', border:'1.5px solid #d1fae5', boxShadow:'0 2px 12px rgba(16,185,129,0.08)' }}>
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span style={{ fontFamily:"'DM Sans',sans-serif", fontSize:'20px', fontWeight:800, color:'#111827' }}>수완03</span>
                  <span style={{ background:'#10b981', color:'#fff', fontSize:'11px', fontWeight:700, fontFamily:"'Inter',sans-serif", padding:'2px 9px', borderRadius:'999px' }}>
                    안정 탑승
                  </span>
                </div>
                <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'17px', fontWeight:700, color:'#065f46', marginBottom:'2px' }}>7분 남음</p>
                <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'12px', color:'#6b7280' }}>정류장까지 도보 3분</p>
              </div>
              <div className="flex items-center gap-1 mt-1">
                <Clock size={12} color="#10b981" />
                <span style={{ fontFamily:"'Inter',sans-serif", fontSize:'13px', fontWeight:600, color:'#10b981' }}>20분</span>
              </div>
            </div>
          </div>

          {/* Card 2 — Amber */}
          <div style={{ background:'#ffffff', borderRadius:'16px', padding:'14px 16px', border:'1.5px solid #fde68a', boxShadow:'0 2px 12px rgba(245,158,11,0.08)' }}>
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span style={{ fontFamily:"'DM Sans',sans-serif", fontSize:'20px', fontWeight:800, color:'#111827' }}>지원151</span>
                  <span style={{ background:'#f59e0b', color:'#fff', fontSize:'11px', fontWeight:700, fontFamily:"'Inter',sans-serif", padding:'2px 9px', borderRadius:'999px' }}>
                    서두르세요
                  </span>
                </div>
                <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'17px', fontWeight:700, color:'#92400e', marginBottom:'2px' }}>5분 남음</p>
                <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'12px', color:'#6b7280' }}>도보 4분</p>
              </div>
              <div className="flex items-center gap-1 mt-1">
                <Clock size={12} color="#f59e0b" />
                <span style={{ fontFamily:"'Inter',sans-serif", fontSize:'13px', fontWeight:600, color:'#f59e0b' }}>35분</span>
              </div>
            </div>
          </div>

          {/* Card 3 — Red */}
          <div style={{ background:'#ffffff', borderRadius:'16px', padding:'14px 16px', border:'1.5px solid #fee2e2', boxShadow:'0 2px 12px rgba(239,68,68,0.08)' }}>
            <div className="flex items-start justify-between mb-2">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span style={{ fontFamily:"'DM Sans',sans-serif", fontSize:'20px', fontWeight:800, color:'#111827' }}>풍암16</span>
                  <span style={{ background:'#dc2626', color:'#fff', fontSize:'11px', fontWeight:700, fontFamily:"'Inter',sans-serif", padding:'2px 9px', borderRadius:'999px' }}>
                    탑승 어려움
                  </span>
                </div>
                <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'17px', fontWeight:700, color:'#991b1b', marginBottom:'2px' }}>2분 남음</p>
                <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'12px', color:'#6b7280' }}>도보 5분</p>
              </div>
              <div className="flex items-center gap-1 mt-1">
                <Clock size={12} color="#dc2626" />
                <span style={{ fontFamily:"'Inter',sans-serif", fontSize:'13px', fontWeight:600, color:'#dc2626' }}>35분</span>
              </div>
            </div>
            <div style={{ background:'#fff7ed', borderRadius:'8px', padding:'7px 10px', border:'1px solid #fed7aa' }}>
              <p style={{ fontFamily:"'Inter',sans-serif", fontSize:'11.5px', fontWeight:500, color:'#92400e', lineHeight:1.4 }}>
                다음 버스 12분 후 도착 — <span style={{ fontWeight:700 }}>가장 빠른 도착을 위해 권장</span>
              </p>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
