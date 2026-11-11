import { Link, Navigate, useParams } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import {
  chefById,
  formatIqd,
  frozenForChef,
  mealsForChef,
  reviewsForChef,
} from '../data/mock'

export function ChefProfile() {
  const { chefId } = useParams()
  const { zoneId, addToCart } = useApp()
  if (!zoneId) return <Navigate to="/" replace />

  const chef = chefById(chefId ?? '')
  if (!chef) {
    return (
      <main className="page">
        <p>الطاهي غير موجود.</p>
        <Link to="/home">العودة</Link>
      </main>
    )
  }

  const meals = mealsForChef(chef.id)
  const frozen = frozenForChef(chef.id)
  const reviews = reviewsForChef(chef.id)

  return (
    <main className="page">
      <Link to="/home" className="back-link">
        → العودة للرئيسية
      </Link>

      <section
        className="profile-cover anim-fade"
        style={{ background: `linear-gradient(145deg, ${chef.accent}, #1c2418)` }}
      >
        <div className="kitchen-photos" aria-hidden>
          <span>مطبخ</span>
          <span>أطباق</span>
          <span>تحضير</span>
        </div>
        <div className="brand-hero" style={{ fontSize: '2.2rem', marginBottom: '0.25rem' }}>
          {chef.kitchenName}
        </div>
        <p style={{ opacity: 0.9 }}>{chef.name} · {chef.distanceKm} كم منك</p>
      </section>

      <div className="rating-line">
        <span className="stars">{'★'.repeat(Math.round(chef.rating))}</span>
        <strong style={{ color: 'var(--olive-deep)' }}>{chef.rating}</strong>
        <span>({chef.reviewCount} تقييم)</span>
        {chef.certified && <span className="cert-badge">مطبخ معتمد ومفحوص</span>}
      </div>

      <p className="bio">{chef.bio}</p>

      <div className="section-head">
        <h2>تخصصات</h2>
      </div>
      <div className="cat-scroll" style={{ marginBottom: '1.25rem' }}>
        {chef.specialties.map((s) => (
          <span key={s} className="cat-chip active">
            {s}
          </span>
        ))}
      </div>

      {meals.length > 0 && (
        <>
          <div className="section-head">
            <h2>قائمة اليوم</h2>
            <Link to="/preorder">طلب مسبق</Link>
          </div>
          <div className="meal-grid" style={{ marginBottom: '1.4rem' }}>
            {meals.map((meal) => (
              <article key={meal.id} className="meal-item">
                <div className="meal-visual" style={{ background: meal.accent }}>
                  {meal.emoji}
                </div>
                <div className="meal-body">
                  <h3>{meal.name}</h3>
                  <div className="desc">{meal.description}</div>
                  <div className="meal-foot">
                    <div>
                      <div className="price">{formatIqd(meal.priceIqd)}</div>
                      <div className={`remain ${meal.remaining === 0 ? 'sold' : ''}`}>
                        {meal.remaining === 0 ? 'نفدت' : `متبقي ${meal.remaining}`}
                      </div>
                    </div>
                    <button
                      type="button"
                      className="btn btn-primary btn-sm"
                      disabled={meal.remaining === 0}
                      onClick={() =>
                        addToCart({
                          id: meal.id,
                          kind: 'meal',
                          name: meal.name,
                          chefName: chef.name,
                          priceIqd: meal.priceIqd,
                          meta: `استلام ${meal.window}`,
                        })
                      }
                    >
                      {meal.remaining === 0 ? 'نفدت' : 'أضف'}
                    </button>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </>
      )}

      {frozen.length > 0 && (
        <>
          <div className="section-head">
            <h2>مفرزنات هذا المطبخ</h2>
            <Link to="/frozen">المتجر</Link>
          </div>
          <div className="meal-grid" style={{ marginBottom: '1.4rem' }}>
            {frozen.map((item) => (
              <article key={item.id} className="meal-item">
                <div className="meal-visual" style={{ background: item.accent, fontSize: '1rem' }}>
                  مفرزن
                </div>
                <div className="meal-body">
                  <h3>{item.name}</h3>
                  <span className={`state-tag ${item.state}`}>
                    {item.stateLabel}
                  </span>
                  <div className="meal-foot">
                    <div className="price">
                      {formatIqd(item.priceIqd)} / {item.unitLabel}
                    </div>
                    <button
                      type="button"
                      className="btn btn-olive btn-sm"
                      onClick={() =>
                        addToCart({
                          id: item.id,
                          kind: 'frozen',
                          name: item.name,
                          chefName: chef.name,
                          priceIqd: item.priceIqd,
                          meta: item.unitLabel,
                        })
                      }
                    >
                      أضف
                    </button>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </>
      )}

      <div className="section-head">
        <h2>آراء الزبائن</h2>
      </div>
      <div className="review-list">
        {reviews.length === 0 && <p className="empty">لا تقييمات بعد.</p>}
        {reviews.map((r) => (
          <article key={r.id} className="review">
            <header>
              <strong>{r.author}</strong>
              <span>
                {'★'.repeat(r.rating)} · {r.date}
              </span>
            </header>
            <p>{r.text}</p>
          </article>
        ))}
      </div>
    </main>
  )
}
