import { Navigate, useNavigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { ZONES } from '../data/mock'

export function ZoneGate() {
  const { zoneId, setZone } = useApp()
  const navigate = useNavigate()

  if (zoneId === 'karada') {
    return <Navigate to="/home" replace />
  }

  return (
    <div className="landing">
      <section className="hero-bleed">
        <div className="hero-plate" aria-hidden />
        <div className="hero-steam" aria-hidden>
          <span />
          <span />
          <span />
        </div>
        <div className="hero-content anim-rise">
          <div className="brand-hero">هوم فود</div>
          <h1>غداء بيتي ساخن من مطابخ الكرادة</h1>
          <p>
            طهاة معتمدون، قائمة يوم محدودة، وطلب مسبق يصل ضمن نافذة الظهيرة —
            بطعم البيت لا المطعم.
          </p>
        </div>
      </section>

      <section className="landing-panel anim-rise-delay">
        <h2>أين نوصلك اليوم؟</h2>
        <p>نخدم الآن منطقة واحدة فقط لنضمن وصول الطعام ساخناً.</p>
        <div className="zone-list">
          {ZONES.map((zone) => (
            <button
              key={zone.id}
              type="button"
              className={`zone-option ${zone.available ? 'available' : ''}`}
              disabled={!zone.available}
              onClick={() => {
                if (!zone.available) return
                setZone(zone.id)
                navigate('/home')
              }}
            >
              <div>
                <strong>{zone.name}</strong>
                <span>{zone.tagline}</span>
              </div>
              <span style={{ fontWeight: 700, color: zone.available ? 'var(--saffron)' : 'var(--muted)' }}>
                {zone.available ? 'ابدأ' : 'قريباً'}
              </span>
            </button>
          ))}
        </div>
        <p className="sample-tag">معاينة واجهة — بيانات تجريبية بدون دفع حقيقي</p>
      </section>
    </div>
  )
}
