import { Bus, Clock, Navigation } from 'lucide-react';

export default function NotificationPage() {
  return (
    <div className="flex-1 bg-gradient-to-br from-blue-900 via-purple-900 to-indigo-900 flex items-center justify-center p-4">
      {/* Lock Screen Notification Widget */}
      <div className="w-full max-w-md">
        <div className="bg-white/10 backdrop-blur-2xl border border-white/20 rounded-3xl shadow-2xl p-4">
          {/* Top Row - App Info & Timestamp */}
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              {/* App Icon */}
              <div className="w-7 h-7 bg-blue-500 rounded-lg flex items-center justify-center shadow-md">
                <Bus className="w-4 h-4 text-white" />
              </div>
              <span className="font-medium text-white/90">루틴 버스</span>
            </div>
            <span className="text-sm text-white/60">방금</span>
          </div>

          {/* Main Alert Text */}
          <div className="mb-4">
            <h2 className="text-xl font-bold text-white mb-2">
              학원 가기 위해 출발할 시간입니다!
            </h2>

            {/* Countdown with Green Indicator */}
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 bg-emerald-400 rounded-full shadow-lg shadow-emerald-400/50 animate-pulse"></div>
              <span className="text-3xl font-bold text-white">3분 후 출발</span>
            </div>
          </div>

          {/* Details Section */}
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 border border-white/10 space-y-3">
            {/* Bus Information */}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-blue-500/20 rounded-xl flex items-center justify-center">
                <Bus className="w-5 h-5 text-blue-300" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-white/60">버스 번호</p>
                <p className="font-semibold text-white text-lg">수완03</p>
              </div>
            </div>

            {/* Arrival Time */}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-amber-500/20 rounded-xl flex items-center justify-center">
                <Clock className="w-5 h-5 text-amber-300" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-white/60">정류장 도착</p>
                <p className="font-semibold text-white">6분 후</p>
              </div>
            </div>

            {/* Walking Time */}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-emerald-500/20 rounded-xl flex items-center justify-center">
                <Navigation className="w-5 h-5 text-emerald-300" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-white/60">도보 시간</p>
                <p className="font-semibold text-white">정류장까지 3분</p>
              </div>
            </div>
          </div>

          {/* Optimal Timing Badge */}
          <div className="mt-3 flex items-center justify-center gap-2 bg-emerald-500/20 border border-emerald-400/30 rounded-full px-4 py-2">
            <div className="w-2 h-2 bg-emerald-400 rounded-full"></div>
            <span className="text-sm font-medium text-emerald-100">최적 타이밍 - 지금 출발하세요!</span>
          </div>
        </div>
      </div>
    </div>
  );
}
