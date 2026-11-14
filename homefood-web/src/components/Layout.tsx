import { NavLink, Link, Outlet, useLocation } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { IconCart, IconFrozen, IconHome, IconOrder, IconPin } from './Icons'

export function Layout() {
  const { zoneId, cartCount, toast, dismissToast, clearZone } = useApp()
  const location = useLocation()
  const hideNav =
    location.pathname === '/' ||
    location.pathname.startsWith('/checkout') ||
    !zoneId

  return (
    <div className="app-shell">
      {zoneId && (
        <header className="topbar">
          <Link to="/home" className="brand-mark">
            <div className="logo">هـ</div>
            <div>
              <strong>هوم فود</strong>
              <span>أكل بيتي قريب منك</span>
            </div>
          </Link>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.55rem' }}>
            <button type="button" className="zone-chip" onClick={clearZone} title="تغيير المنطقة">
              <IconPin />
              الكرادة
            </button>
            <Link to="/orders" className="icon-btn" aria-label="طلباتي">
              <IconOrder />
            </Link>
            <Link to="/cart" className="icon-btn" aria-label="السلة">
              <IconCart />
              {cartCount > 0 && <span className="badge">{cartCount}</span>}
            </Link>
          </div>
        </header>
      )}

      <Outlet />

      {toast && (
        <button type="button" className="toast" onClick={dismissToast}>
          {toast}
        </button>
      )}

      {!hideNav && (
        <nav className="bottom-nav" aria-label="التنقل الرئيسي">
          <NavLink to="/home" className={({ isActive }) => (isActive ? 'active' : '')}>
            <IconHome />
            الرئيسية
          </NavLink>
          <NavLink to="/menu" className={({ isActive }) => (isActive ? 'active' : '')}>
            <IconOrder />
            القائمة
          </NavLink>
          <NavLink to="/frozen" className={({ isActive }) => (isActive ? 'active' : '')}>
            <IconFrozen />
            مفرزنات
          </NavLink>
          <NavLink to="/orders" className={({ isActive }) => (isActive ? 'active' : '')}>
            <IconCart />
            طلباتي
          </NavLink>
        </nav>
      )}
    </div>
  )
}
