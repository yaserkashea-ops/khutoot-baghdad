import { NavLink, Link, Outlet, useLocation } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { IconCart, IconFrozen, IconHome, IconOrder, IconPin } from './Icons'

export function Layout() {
  const { zoneId, cartCount } = useApp()
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
            <span className="zone-chip">
              <IconPin />
              الكرادة
            </span>
            <Link to="/cart" className="icon-btn" aria-label="السلة">
              <IconCart />
              {cartCount > 0 && <span className="badge">{cartCount}</span>}
            </Link>
          </div>
        </header>
      )}

      <Outlet />

      {!hideNav && (
        <nav className="bottom-nav" aria-label="التنقل الرئيسي">
          <NavLink to="/home" className={({ isActive }) => (isActive ? 'active' : '')}>
            <IconHome />
            الرئيسية
          </NavLink>
          <NavLink to="/menu" className={({ isActive }) => (isActive ? 'active' : '')}>
            <IconOrder />
            قائمة اليوم
          </NavLink>
          <NavLink to="/frozen" className={({ isActive }) => (isActive ? 'active' : '')}>
            <IconFrozen />
            مفرزنات
          </NavLink>
          <NavLink to="/cart" className={({ isActive }) => (isActive ? 'active' : '')}>
            <IconCart />
            السلة
          </NavLink>
        </nav>
      )}
    </div>
  )
}
