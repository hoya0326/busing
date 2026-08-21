import { Outlet, Link, useLocation } from 'react-router';
import { Home, Calendar, Bell, User } from 'lucide-react';

const navItems = [
  { path: '/', label: '홈', icon: Home },
  { path: '/schedule', label: '일정', icon: Calendar },
  { path: '/notification', label: '알림', icon: Bell },
  { path: '/profile', label: '프로필', icon: User },
];

export default function Root() {
  const location = useLocation();

  return (
    <div className="size-full flex flex-col max-w-md mx-auto relative overflow-hidden" style={{ background: '#111827' }}>
      <Outlet />

      {/* Bottom Tab Bar */}
      <div
        className="fixed bottom-0 left-0 right-0 max-w-md mx-auto z-30"
        style={{
          background: 'rgba(255,255,255,0.97)',
          backdropFilter: 'blur(16px)',
          borderTop: '1px solid rgba(0,0,0,0.07)',
          paddingBottom: 'env(safe-area-inset-bottom, 0px)',
        }}
      >
        <div className="flex items-center justify-around px-2 py-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;

            return (
              <Link
                key={item.path}
                to={item.path}
                className="flex flex-col items-center gap-0.5 py-1 px-5 rounded-xl transition-all"
                style={{ textDecoration: 'none' }}
              >
                <div
                  className="flex items-center justify-center w-8 h-8 rounded-xl transition-all"
                  style={{
                    background: isActive ? '#111827' : 'transparent',
                    transform: isActive ? 'scale(1.08)' : 'scale(1)',
                  }}
                >
                  <Icon
                    size={17}
                    color={isActive ? '#39ff14' : '#9ca3af'}
                    strokeWidth={isActive ? 2.5 : 2}
                  />
                </div>
                <span
                  style={{
                    fontFamily: "'Inter', sans-serif",
                    fontSize: '10px',
                    fontWeight: isActive ? 700 : 400,
                    color: isActive ? '#111827' : '#9ca3af',
                    letterSpacing: '0.1px',
                  }}
                >
                  {item.label}
                </span>
              </Link>
            );
          })}
        </div>
      </div>
    </div>
  );
}
