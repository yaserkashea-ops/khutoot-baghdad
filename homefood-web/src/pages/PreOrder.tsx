import { useMemo, useState, type FormEvent } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { MEALS, chefById, formatIqd } from '../data/mock'

const WINDOWS = [
  { id: 'tonight', label: 'احجز الليلة لغدٍ · ١٢–٢' },
  { id: 'morning', label: 'احجز صباحاً · قبل ١٠:٠٠' },
]

export function PreOrder() {
  const { zoneId, addToCart } = useApp()
  const navigate = useNavigate()
  const [windowId, setWindowId] = useState(WINDOWS[0].id)
  const [mealId, setMealId] = useState(MEALS.find((m) => m.remaining > 0)?.id ?? '')
  const [address, setAddress] = useState('مكتب الكرادة، شارع أبو نواس')
  const [note, setNote] = useState('')
  const [done, setDone] = useState(false)

  const meal = useMemo(() => MEALS.find((m) => m.id === mealId), [mealId])
  const chef = meal ? chefById(meal.chefId) : undefined

  if (!zoneId) return <Navigate to="/" replace />

  function onSubmit(e: FormEvent) {
    e.preventDefault()
    if (!meal || !chef || meal.remaining === 0) return
    const windowLabel = WINDOWS.find((w) => w.id === windowId)?.label ?? ''
    addToCart({
      id: meal.id,
      kind: 'meal',
      name: meal.name,
      chefName: chef.name,
      priceIqd: meal.priceIqd,
      meta: `طلب مسبق · ${windowLabel}`,
    })
    setDone(true)
    window.setTimeout(() => navigate('/cart'), 900)
  }

  return (
    <main className="page">
      <Link to="/menu" className="back-link">
        → رجوع لقائمة اليوم
      </Link>

      <div className="section-head">
        <div>
          <h2>طلب مسبق للغداء</h2>
          <p style={{ color: 'var(--muted)', fontSize: '0.9rem', marginTop: '0.25rem' }}>
            احجز حصتك قبل نفاد الكمية — التوصيل ضمن نافذة ١٢–٢
          </p>
        </div>
      </div>

      <form onSubmit={onSubmit} className="anim-rise">
        <div className="field">
          <label>نافذة الحجز</label>
          <div className="window-pills">
            {WINDOWS.map((w) => (
              <button
                key={w.id}
                type="button"
                className={windowId === w.id ? 'active' : ''}
                onClick={() => setWindowId(w.id)}
              >
                {w.label}
              </button>
            ))}
          </div>
        </div>

        <div className="field">
          <label htmlFor="meal">الوجبة</label>
          <select
            id="meal"
            value={mealId}
            onChange={(e) => setMealId(e.target.value)}
          >
            {MEALS.map((m) => (
              <option key={m.id} value={m.id} disabled={m.remaining === 0}>
                {m.name} — {chefById(m.chefId)?.name} ({m.remaining === 0 ? 'نفدت' : `متبقي ${m.remaining}`})
              </option>
            ))}
          </select>
        </div>

        {meal && (
          <div className="order-card" style={{ marginBottom: '1rem' }}>
            <strong>{meal.name}</strong>
            <div style={{ color: 'var(--muted)', fontSize: '0.88rem', margin: '0.25rem 0' }}>
              {chef?.kitchenName} · {meal.description}
            </div>
            <div className="price">{formatIqd(meal.priceIqd)}</div>
          </div>
        )}

        <div className="field">
          <label htmlFor="address">عنوان التوصيل (عمل / منزل)</label>
          <input
            id="address"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            required
          />
        </div>

        <div className="field">
          <label htmlFor="note">ملاحظة للطاهي (اختياري)</label>
          <textarea
            id="note"
            rows={3}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="مثال: بدون فلفل حار"
          />
        </div>

        <button type="submit" className="btn btn-primary btn-block" disabled={!meal || meal.remaining === 0}>
          أضف للسلة وأكمل الطلب
        </button>
      </form>

      {done && <div className="toast">أُضيفت الوجبة للسلة — تابع للدفع نقداً عند الاستلام</div>}
    </main>
  )
}
