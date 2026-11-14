import { Link, Navigate, useParams } from 'react-router-dom'
import { useState } from 'react'
import { useApp } from '../context/AppContext'
import { chefById, formatIqd, mealById, spiceLabel } from '../data/mock'
import { EmptyState } from '../components/EmptyState'

export function MealDetail() {
  const { mealId } = useParams()
  const { zoneId, addToCart } = useApp()
  const [qty, setQty] = useState(1)
  const meal = mealById(mealId ?? '')
  const chef = meal ? chefById(meal.chefId) : undefined

  if (!zoneId) return <Navigate to="/" replace />
  if (!meal || !chef) {
    return (
      <main className="page">
        <EmptyState
          title="الوجبة غير موجودة"
          body="ربما نفدت أو الرابط غير صحيح."
          actionTo="/menu"
          actionLabel="قائمة اليوم"
        />
      </main>
    )
  }

  const sold = meal.remaining === 0

  return (
    <main className="page">
      <Link to="/menu" className="back-link">
        → رجوع للقائمة
      </Link>

      <section
        className="detail-hero anim-fade"
        style={{ background: `linear-gradient(145deg, ${meal.accent}, #1c2418)` }}
      >
        <div className="detail-emoji">{meal.emoji}</div>
        <h1>{meal.name}</h1>
        <p>
          <Link to={`/chef/${chef.id}`}>{chef.kitchenName}</Link> · نافذة {meal.window}
        </p>
      </section>

      <div className="detail-meta anim-rise">
        <span>{formatIqd(meal.priceIqd)}</span>
        <span>{meal.prepMinutes} د تحضير</span>
        <span>حرارة {spiceLabel(meal.spice)}</span>
        <span className={sold ? 'remain sold' : 'remain'}>
          {sold ? 'نفدت' : `متبقي ${meal.remaining}`}
        </span>
      </div>

      <p className="bio">{meal.longDescription}</p>

      <div className="tag-row" style={{ marginBottom: '1rem' }}>
        {meal.tags.map((t) => (
          <span key={t} className="mini-tag">
            {t}
          </span>
        ))}
      </div>

      <div className="section-head">
        <h2>المكونات</h2>
      </div>
      <ul className="ingredient-list">
        {meal.ingredients.map((i) => (
          <li key={i}>{i}</li>
        ))}
      </ul>

      <div className="detail-cta sticky-cta">
        <div className="qty-ctrl">
          <button type="button" onClick={() => setQty((q) => Math.max(1, q - 1))} disabled={sold}>
            −
          </button>
          <span>{qty}</span>
          <button
            type="button"
            onClick={() => setQty((q) => Math.min(meal.remaining || 1, q + 1))}
            disabled={sold}
          >
            +
          </button>
        </div>
        <button
          type="button"
          className="btn btn-primary"
          disabled={sold}
          onClick={() =>
            addToCart(
              {
                id: meal.id,
                kind: 'meal',
                name: meal.name,
                chefName: chef.name,
                priceIqd: meal.priceIqd,
                meta: `استلام ${meal.window}`,
              },
              qty,
            )
          }
        >
          {sold ? 'نفدت الكمية' : `أضف · ${formatIqd(meal.priceIqd * qty)}`}
        </button>
      </div>

      <div style={{ display: 'flex', gap: '0.6rem', marginTop: '0.75rem' }}>
        <Link to="/preorder" className="btn btn-ghost btn-block">
          طلب مسبق لهذه الوجبة
        </Link>
      </div>
    </main>
  )
}
