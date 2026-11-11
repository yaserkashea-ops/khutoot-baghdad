import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { MEALS, chefById, formatIqd } from '../data/mock'

export function TodayMenu() {
  const { zoneId, addToCart } = useApp()
  if (!zoneId) return <Navigate to="/" replace />

  return (
    <main className="page">
      <div className="section-head">
        <div>
          <h2>قائمة اليوم</h2>
          <p style={{ color: 'var(--muted)', fontSize: '0.9rem', marginTop: '0.25rem' }}>
            كميات محدودة — احجز مسبقاً لنافذة الغداء
          </p>
        </div>
        <Link to="/preorder" className="btn btn-primary btn-sm">
          طلب مسبق
        </Link>
      </div>

      <div className="tabs" style={{ marginBottom: '1rem' }}>
        <span className="active" style={{ textAlign: 'center' }}>
          وجبات ساخنة
        </span>
        <Link to="/frozen">مفرزنات</Link>
      </div>

      <div className="meal-grid anim-rise">
        {MEALS.map((meal) => {
          const chef = chefById(meal.chefId)
          const sold = meal.remaining === 0
          return (
            <article key={meal.id} className="meal-item">
              <div className="meal-visual" style={{ background: meal.accent }}>
                {meal.emoji}
              </div>
              <div className="meal-body">
                <h3>{meal.name}</h3>
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
                    {sold ? 'نفدت' : 'أضف للسلة'}
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
