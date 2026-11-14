import { useMemo, useState, type FormEvent } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { MEALS, PREORDER_WINDOWS, chefById, formatIqd } from '../data/mock'

export function PreOrder() {
  const { zoneId, addToCart } = useApp()
  const navigate = useNavigate()
  const [windowId, setWindowId] = useState(PREORDER_WINDOWS[0].id)
  const [mealId, setMealId] = useState(MEALS.find((m) => m.remaining > 0)?.id ?? '')
  const [address, setAddress] = useState('مكتب الكرادة، شارع أبو نواس')
  const [note, setNote] = useState('')

  const meal = useMemo(() => MEALS.find((m) => m.id === mealId), [mealId])
  const chef = meal ? chefById(meal.chefId) : undefined
  const win = PREORDER_WINDOWS.find((w) => w.id === windowId)

  if (!zoneId) return <Navigate to="/" replace />

  function onSubmit(e: FormEvent) {
    e.preventDefault()
    if (!meal || !chef || meal.remaining === 0 || !win) return
    addToCart({
      id: meal.id,
      kind: 'meal',
      name: meal.name,
      chefName: chef.name,
      priceIqd: meal.priceIqd,
      meta: `طلب مسبق · ${win.label}`,
      lineKey: `${meal.id}::preorder::${win.id}`,
    })
    navigate('/cart')
  }

  return (
    <main className="page">
      <Link to="/menu" className="back-link">
        → رجوع لقائمة اليوم
      </Link>

      <div className="section-head">
        <div>
          <h2>طلب مسبق للغداء</h2>
          <p className="subtle">احجز حصتك قبل نفاد الكمية — نوافذ توصيل واضحة</p>
        </div>
      </div>

      <form onSubmit={onSubmit} className="anim-rise">
        <div className="field">
          <label>نافذة الحجز</label>
          <div className="window-stack">
            {PREORDER_WINDOWS.map((w) => (
              <button
                key={w.id}
                type="button"
                className={`window-card ${windowId === w.id ? 'active' : ''}`}
                onClick={() => setWindowId(w.id)}
              >
                <strong>{w.label}</strong>
                <span>{w.hint}</span>
                <em>{w.cutoff}</em>
              </button>
            ))}
          </div>
        </div>

        <div className="field">
          <label htmlFor="meal">الوجبة</label>
          <select id="meal" value={mealId} onChange={(e) => setMealId(e.target.value)}>
            {MEALS.map((m) => (
              <option key={m.id} value={m.id} disabled={m.remaining === 0}>
                {m.name} — {chefById(m.chefId)?.name} (
                {m.remaining === 0 ? 'نفدت' : `متبقي ${m.remaining}`})
              </option>
            ))}
          </select>
        </div>

        {meal && (
          <Link to={`/meal/${meal.id}`} className="order-card" style={{ display: 'block', marginBottom: '1rem' }}>
            <strong>{meal.name}</strong>
            <div className="meta">
              {chef?.kitchenName} · {meal.description}
            </div>
            <div className="price">{formatIqd(meal.priceIqd)}</div>
          </Link>
        )}

        <div className="field">
          <label htmlFor="address">عنوان التوصيل (عمل / منزل)</label>
          <input id="address" value={address} onChange={(e) => setAddress(e.target.value)} required />
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
    </main>
  )
}
