import { useMemo, useState } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { MEAL_FILTERS, chefById, formatIqd, searchMeals } from '../data/mock'
import { SearchField } from '../components/SearchField'
import { EmptyState } from '../components/EmptyState'

export function TodayMenu() {
  const { zoneId, addToCart } = useApp()
  const [q, setQ] = useState('')
  const [filter, setFilter] = useState<(typeof MEAL_FILTERS)[number]>('متوفر')
  const meals = useMemo(() => searchMeals(q, filter), [q, filter])

  if (!zoneId) return <Navigate to="/" replace />

  return (
    <main className="page">
      <div className="section-head">
        <div>
          <h2>قائمة اليوم</h2>
          <p className="subtle">كميات محدودة — احجز مسبقاً لنافذة الغداء</p>
        </div>
        <Link to="/preorder" className="btn btn-primary btn-sm">
          طلب مسبق
        </Link>
      </div>

      <SearchField value={q} onChange={setQ} placeholder="ابحث في أطباق اليوم…" />

      <div className="cat-scroll" style={{ marginTop: '0.75rem' }}>
        {MEAL_FILTERS.map((f) => (
          <button
            key={f}
            type="button"
            className={`cat-chip ${filter === f ? 'active' : ''}`}
            onClick={() => setFilter(f)}
          >
            {f}
          </button>
        ))}
      </div>

      {meals.length === 0 ? (
        <EmptyState
          title="لا أطباق مطابقة"
          body="غيّر البحث أو التصفية، أو تصفّح المفرزنات."
          actionTo="/frozen"
          actionLabel="المفرزنات"
        />
      ) : (
        <div className="meal-grid anim-rise">
          {meals.map((meal) => {
            const chef = chefById(meal.chefId)
            const sold = meal.remaining === 0
            return (
              <article key={meal.id} className="meal-item">
                <Link to={`/meal/${meal.id}`} className="meal-visual" style={{ background: meal.accent }}>
                  {meal.emoji}
                </Link>
                <div className="meal-body">
                  <h3>
                    <Link to={`/meal/${meal.id}`}>{meal.name}</Link>
                  </h3>
                  <div className="chef">
                    <Link to={`/chef/${meal.chefId}`}>{chef?.kitchenName}</Link>
                  </div>
                  <div className="desc">{meal.description}</div>
                  <div className="meal-foot">
                    <div>
                      <div className="price">{formatIqd(meal.priceIqd)}</div>
                      <div className={`remain ${sold ? 'sold' : ''}`}>
                        {sold ? 'نفدت' : `متبقي ${meal.remaining} · ${meal.window}`}
                      </div>
                    </div>
                    <button
                      type="button"
                      className="btn btn-primary btn-sm"
                      disabled={sold}
                      onClick={() =>
                        addToCart({
                          id: meal.id,
                          kind: 'meal',
                          name: meal.name,
                          chefName: chef?.name ?? '',
                          priceIqd: meal.priceIqd,
                          meta: `استلام ${meal.window}`,
                        })
                      }
                    >
                      {sold ? 'نفدت' : 'أضف'}
                    </button>
                  </div>
                </div>
              </article>
            )
          })}
        </div>
      )}
    </main>
  )
}
