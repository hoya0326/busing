import { Plus, ArrowRight, Bus } from 'lucide-react';
import { useState } from 'react';

export default function SchedulePage() {
  const [selectedDay, setSelectedDay] = useState('화');
  const [routines, setRoutines] = useState([
    {
      id: 1,
      time: '오전 08:30',
      from: '집',
      to: '학교 (조선대)',
      bus: '수완03',
      enabled: true
    },
    {
      id: 2,
      time: '오후 06:30',
      from: '학교 (조선대)',
      to: '학원',
      bus: '지원151',
      enabled: true
    }
  ]);

  const days = [
    { short: '월', full: '월요일' },
    { short: '화', full: '화요일' },
    { short: '수', full: '수요일' },
    { short: '목', full: '목요일' },
    { short: '금', full: '금요일' },
    { short: '토', full: '토요일' },
    { short: '일', full: '일요일' }
  ];

  const toggleRoutine = (id: number) => {
    setRoutines(routines.map(routine =>
      routine.id === id ? { ...routine, enabled: !routine.enabled } : routine
    ));
  };

  return (
    <div className="flex-1 overflow-y-auto pb-20">
      {/* Header */}
      <div className="bg-white px-5 pt-14 pb-6 shadow-sm">
        <h1 className="text-2xl font-semibold text-gray-900 mb-6">내 루틴 시간표</h1>

        {/* Day Selector */}
        <div className="flex gap-2 overflow-x-auto pb-2 -mx-1 px-1">
          {days.map((day) => (
            <button
              key={day.short}
              onClick={() => setSelectedDay(day.short)}
              className={`flex-shrink-0 px-5 py-3 rounded-xl font-medium transition-all ${
                selectedDay === day.short
                  ? 'bg-blue-500 text-white shadow-md'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {day.short}
            </button>
          ))}
        </div>
      </div>

      {/* Main Content - Timeline */}
      <div className="px-5 py-6 pb-24">
        <div className="space-y-4">
          {routines.map((routine) => (
            <div
              key={routine.id}
              className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden relative"
            >
              <div className="p-5">
                {/* Time */}
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 rounded-full bg-blue-500"></div>
                    <span className="text-2xl font-semibold text-gray-900">{routine.time}</span>
                  </div>

                  {/* Toggle Switch */}
                  <button
                    onClick={() => toggleRoutine(routine.id)}
                    className={`relative w-14 h-8 rounded-full transition-colors ${
                      routine.enabled ? 'bg-blue-500' : 'bg-gray-300'
                    }`}
                  >
                    <div
                      className={`absolute top-1 left-1 w-6 h-6 bg-white rounded-full shadow-md transition-transform ${
                        routine.enabled ? 'translate-x-6' : 'translate-x-0'
                      }`}
                    ></div>
                  </button>
                </div>

                {/* Route */}
                <div className="flex items-center gap-3 mb-3">
                  <span className="text-gray-700 font-medium">{routine.from}</span>
                  <ArrowRight className="w-5 h-5 text-gray-400" />
                  <span className="text-gray-700 font-medium">{routine.to}</span>
                </div>

                {/* Bus Info */}
                <div className="flex items-center gap-2 bg-blue-50 rounded-lg px-3 py-2 border border-blue-100">
                  <Bus className="w-4 h-4 text-blue-600" />
                  <span className="text-sm text-gray-600">선호 버스:</span>
                  <span className="text-sm font-semibold text-blue-600">{routine.bus}</span>
                </div>
              </div>

              {/* Disabled Overlay */}
              {!routine.enabled && (
                <div className="absolute inset-0 bg-white/50 backdrop-blur-[1px]"></div>
              )}
            </div>
          ))}

          {routines.length === 0 && (
            <div className="text-center py-16">
              <p className="text-gray-400">{selectedDay}요일에 예정된 루틴이 없습니다</p>
              <p className="text-sm text-gray-400 mt-1">+ 버튼을 눌러 새 루틴을 추가하세요</p>
            </div>
          )}
        </div>
      </div>

      {/* Floating Action Button */}
      <button className="fixed bottom-24 right-6 max-w-md w-16 h-16 bg-blue-500 hover:bg-blue-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all flex items-center justify-center">
        <Plus className="w-7 h-7" />
      </button>
    </div>
  );
}
