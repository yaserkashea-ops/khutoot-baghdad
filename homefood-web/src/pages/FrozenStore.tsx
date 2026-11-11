import { useMemo, useState } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { FROZEN, FROZEN_CATEGORIES, chefById, formatIqd } from '../data/mock'
import { SearchField } from '../components/SearchField'
import { EmptyState } from '../components/EmptyState'

export function FrozenStore() {
  const { zoneId } = useApp()
  const [cat, setCat] = useState<(typeof FROZEN_CATEGORIES)[number]>('الكل')
  const [q, setQ] = useState('')
  const [stateFilter, setStateFilter] = useState<'all' | 'frozen' | 'chilled'>('all')

  const items = useMemo(() => {
    return FROZEN.filter((p) => {
      if (cat !== 'الكل' && p.category !== cat) return false
      if (stateFilter !== 'all' && p.state !== stateFilter) return false
      if (!q.trim()) return true
      const chef = chefById(p.chefId)
      return `${p.name} ${p.category} ${chef?.name ?? ''}`.includes(q.trim())
    })
  }, [cat, q, stateFilter])

  if (!zoneId) return <Navigate to="/" replace />

  return (
    <main className="page">
      <div className="section-head">
        <div>
          <h2>متجر المفرزنات</h2>
          <p className="subtle">قطعة أو وزن — مجمّد للقلي أو مبرد للفرن/للتقديم</p>
        </div>
        <Link to="/menu" className="linkish">
          قائمة اليوم
        </Link>
      </div>

      <SearchField value={q} onChange={setQ} placeholder="ابحث في المفرزنات…" />

      <div className="cat-scroll" style={{ marginTop: '0.75rem' }}>
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

      <div className="cat-scroll">
        {(
          [
            ['all', 'الكل'],
            ['frozen', 'مجمّد'],
            ['chilled', 'مبرد'],
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            className={`cat-chip ${stateFilter === id ? 'active' : ''}`}
            onClick={() => setStateFilter(id)}
          >
            {label}
          </button>
        ))}
      </div>

      {items.length === 0 ? (
        <EmptyState title="لا منتجات" body="لا نتائج لهذه التصفية." actionTo="/frozen" actionLabel="إعادة الضبط" />
      ) : (
        <div className="meal-grid anim-rise">
          {items.map((item) => {
            const chef = chefById(item.chefId)
            return (
              <Link key={item.id} to={`/frozen/${item.id}`} className="meal-item meal-link">
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
                  <div className="chef">{chef?.kitchenName}</div>
                  <span className={`state-tag ${item.state}`}>{item.stateLabel}</span>
                  <div className="meal-foot">
                    <div className="price">
                      {formatIqd(item.priceIqd)}
                      <span className="unit-hint"> / {item.unitLabel}</span>
                    </div>
                    <span className="linkish">تفاصيل</span>
                  </div>
                </div>
              </Link>
            )
          })}
        </div>
      )}
    </main>
  )
}
