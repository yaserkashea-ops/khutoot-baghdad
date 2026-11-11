import { useMemo, useState } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { FROZEN, FROZEN_CATEGORIES, chefById, formatIqd } from '../data/mock'

export function FrozenStore() {
  const { zoneId, addToCart } = useApp()
  const [cat, setCat] = useState<(typeof FROZEN_CATEGORIES)[number]>('الكل')

  const items = useMemo(
    () => (cat === 'الكل' ? FROZEN : FROZEN.filter((p) => p.category === cat)),
    [cat],
  )

  if (!zoneId) return <Navigate to="/" replace />

  return (
    <main className="page">
      <div className="section-head">
        <div>
          <h2>متجر المفرزنات</h2>
          <p style={{ color: 'var(--muted)', fontSize: '0.9rem', marginTop: '0.25rem' }}>
            قطعة أو وزن — مجمّد للقلي أو مبرد للفرن
          </p>
        </div>
        <Link to="/menu" className="linkish">
          قائمة اليوم
        </Link>
      </div>

      <div className="cat-scroll anim-fade">
        {FROZEN_CATEGORIES.map((c) => (
          <button
            key={c}
            type="button"
            className={`cat-chip ${cat === c ? 'active' : ''}`}
            onClick={() => setCat(c)}
          >
            {c}
          </button>
        ))}
      </div>

      <div className="meal-grid anim-rise">
        {items.map((item) => {
          const chef = chefById(item.chefId)
          return (
            <article key={item.id} className="meal-item">
              <div
                className="meal-visual"
                style={{
                  background: `linear-gradient(160deg, ${item.accent}, #1c2418)`,
                  fontSize: '0.95rem',
                  fontWeight: 700,
                }}
              >
                {item.category}
              </div>
              <div className="meal-body">
                <h3>{item.name}</h3>
                <div className="chef">
                  <Link to={`/chef/${item.chefId}`}>{chef?.kitchenName}</Link>
                </div>
                <span className={`state-tag ${item.state}`}>
                  {item.state === 'frozen' ? 'مجمّد جاهز للقلي' : 'مبرد جاهز للفرن'}
                </span>
                <div className="meal-foot">
                  <div className="price">
                    {formatIqd(item.priceIqd)}
                    <span style={{ fontWeight: 500, color: 'var(--muted)', fontSize: '0.8rem' }}>
                      {' '}
                      / {item.unitLabel}
                    </span>
                  </div>
                  <button
                    type="button"
                    className="btn btn-olive btn-sm"
                    onClick={() =>
                      addToCart({
                        id: item.id,
                        kind: 'frozen',
                        name: item.name,
                        chefName: chef?.name ?? '',
                        priceIqd: item.priceIqd,
                        meta: `${item.unitLabel} · ${item.state === 'frozen' ? 'مجمّد' : 'مبرد'}`,
                      })
                    }
                  >
                    أضف
                  </button>
                </div>
              </div>
            </article>
          )
        })}
      </div>
    </main>
  )
}
