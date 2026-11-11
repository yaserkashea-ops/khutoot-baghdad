import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { CHEFS, MEALS, chefById, formatIqd } from '../data/mock'
import { SearchField } from '../components/SearchField'
import { useState } from 'react'

export function Home() {
  const { zoneId, addToCart } = useApp()
  const [q, setQ] = useState('')
  if (!zoneId) return <Navigate to="/" replace />

  const available = MEALS.filter((m) => m.remaining > 0).slice(0, 4)
  const chefs = CHEFS.slice(0, 5)

  return (
    <main className="page">
      <section className="home-hero anim-fade">
        <div className="brand-hero">هوم فود</div>
        <p>قائمة اليوم من طهاة قريبين في الكرادة — احجز قبل ما تنفد الحصص.</p>
        <div className="hero-actions">
          <Link to="/preorder" className="btn btn-primary btn-sm">
            طلب مسبق
          </Link>
          <Link to="/search" className="btn btn-ghost-light btn-sm">
            بحث متقدم
          </Link>
        </div>
      </section>

      <div className="home-search anim-rise">
        <SearchField
          value={q}
          onChange={setQ}
          placeholder="ابحث ثم اضغط بحث متقدم…"
        />
        {q.trim() && (
          <Link className="search-jump" to={`/search?q=${encodeURIComponent(q.trim())}`}>
            عرض نتائج «{q.trim()}»
          </Link>
        )}
      </div>

      <div className="tabs">
        <Link to="/menu" className="active">
          قائمة اليوم
        </Link>
        <Link to="/frozen">مفرزنات</Link>
      </div>

      <div className="section-head">
        <h2>طهاة قريبون</h2>
        <Link to="/search?tab=chefs">عرض الكل</Link>
      </div>

      <div className="chef-row anim-rise">
        {chefs.map((chef) => (
          <Link key={chef.id} to={`/chef/${chef.id}`} className="chef-tile">
            <div className="chef-avatar" style={{ background: chef.accent }}>
              {chef.name.slice(0, 1)}
            </div>
            <div>
              <strong>{chef.kitchenName}</strong>
              <div className="meta">
                ★ {chef.rating} · {chef.distanceKm} كم
              </div>
            </div>
            {chef.certified && <span className="cert-badge">مطبخ معتمد</span>}
          </Link>
        ))}
      </div>

      <div className="section-head">
        <h2>وجبات اليوم</h2>
        <span className="linkish">نافذة ١٢–٢</span>
      </div>

      <div className="meal-grid anim-rise-delay">
        {available.map((meal) => {
          const chef = chefById(meal.chefId)
          return (
            <article key={meal.id} className="meal-item">
              <Link to={`/meal/${meal.id}`} className="meal-visual" style={{ background: meal.accent }}>
                {meal.emoji}
              </Link>
              <div className="meal-body">
                <h3>
                  <Link to={`/meal/${meal.id}`}>{meal.name}</Link>
                </h3>
                <div className="chef">{chef?.name}</div>
                <div className="desc">{meal.description}</div>
                <div className="meal-foot">
                  <div>
                    <div className="price">{formatIqd(meal.priceIqd)}</div>
                    <div className="remain">متبقي {meal.remaining}</div>
                  </div>
                  <button
                    type="button"
                    className="btn btn-primary btn-sm"
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
                    اطلب
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
