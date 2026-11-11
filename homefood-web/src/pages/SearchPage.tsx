import { useMemo, useState } from 'react'
import { Link, Navigate, useSearchParams } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import {
  CHEF_SORTS,
  MEAL_FILTERS,
  chefById,
  formatIqd,
  searchChefs,
  searchMeals,
} from '../data/mock'
import { SearchField } from '../components/SearchField'
import { EmptyState } from '../components/EmptyState'

export function SearchPage() {
  const { zoneId } = useApp()
  const [params, setParams] = useSearchParams()
  const [q, setQ] = useState(params.get('q') ?? '')
  const tab = params.get('tab') === 'chefs' ? 'chefs' : 'meals'
  const [mealFilter, setMealFilter] = useState<(typeof MEAL_FILTERS)[number]>('الكل')
  const [chefSort, setChefSort] = useState<(typeof CHEF_SORTS)[number]['id']>('near')

  const meals = useMemo(() => searchMeals(q, mealFilter), [q, mealFilter])
  const chefs = useMemo(() => searchChefs(q, chefSort), [q, chefSort])

  if (!zoneId) return <Navigate to="/" replace />

  function setTab(next: 'meals' | 'chefs') {
    const p = new URLSearchParams(params)
    p.set('tab', next)
    if (q) p.set('q', q)
    setParams(p)
  }

  return (
    <main className="page">
      <div className="section-head">
        <div>
          <h2>بحث وتصفية</h2>
          <p className="subtle">طهاة وأطباق داخل نطاق الكرادة</p>
        </div>
      </div>

      <SearchField
        value={q}
        onChange={(v) => {
          setQ(v)
          const p = new URLSearchParams(params)
          if (v) p.set('q', v)
          else p.delete('q')
          setParams(p, { replace: true })
        }}
      />

      <div className="tabs" style={{ marginTop: '0.9rem' }}>
        <button type="button" className={tab === 'meals' ? 'active' : ''} onClick={() => setTab('meals')}>
          الأطباق ({meals.length})
        </button>
        <button type="button" className={tab === 'chefs' ? 'active' : ''} onClick={() => setTab('chefs')}>
          الطهاة ({chefs.length})
        </button>
      </div>

      {tab === 'meals' ? (
        <>
          <div className="cat-scroll">
            {MEAL_FILTERS.map((f) => (
              <button
                key={f}
                type="button"
                className={`cat-chip ${mealFilter === f ? 'active' : ''}`}
                onClick={() => setMealFilter(f)}
              >
                {f}
              </button>
            ))}
          </div>
          {meals.length === 0 ? (
            <EmptyState
              title="لا نتائج"
              body="جرّب كلمة أخرى أو أزل التصفية."
              actionTo="/menu"
              actionLabel="قائمة اليوم"
            />
          ) : (
            <div className="meal-grid anim-rise">
              {meals.map((meal) => {
                const chef = chefById(meal.chefId)
                const sold = meal.remaining === 0
                return (
                  <Link key={meal.id} to={`/meal/${meal.id}`} className="meal-item meal-link">
                    <div className="meal-visual" style={{ background: meal.accent }}>
                      {meal.emoji}
                    </div>
                    <div className="meal-body">
                      <h3>{meal.name}</h3>
                      <div className="chef">{chef?.kitchenName}</div>
                      <div className="tag-row">
                        {meal.tags.slice(0, 2).map((t) => (
                          <span key={t} className="mini-tag">
                            {t}
                          </span>
                        ))}
                      </div>
                      <div className="meal-foot">
                        <div className="price">{formatIqd(meal.priceIqd)}</div>
                        <div className={`remain ${sold ? 'sold' : ''}`}>
                          {sold ? 'نفدت' : `متبقي ${meal.remaining}`}
                        </div>
                      </div>
                    </div>
                  </Link>
                )
              })}
            </div>
          )}
        </>
      ) : (
        <>
          <div className="cat-scroll">
            {CHEF_SORTS.map((s) => (
              <button
                key={s.id}
                type="button"
                className={`cat-chip ${chefSort === s.id ? 'active' : ''}`}
                onClick={() => setChefSort(s.id)}
              >
                {s.label}
              </button>
            ))}
          </div>
          {chefs.length === 0 ? (
            <EmptyState title="لا طهاة" body="عدّل البحث أو تصفّح الكل من الرئيسية." actionTo="/home" actionLabel="الرئيسية" />
          ) : (
            <div className="chef-list anim-rise">
              {chefs.map((chef) => (
                <Link key={chef.id} to={`/chef/${chef.id}`} className="chef-list-item">
                  <div className="chef-avatar" style={{ background: chef.accent }}>
                    {chef.name.slice(0, 1)}
                  </div>
                  <div className="grow">
                    <strong>{chef.kitchenName}</strong>
                    <div className="meta">
                      {chef.name} · ★ {chef.rating} · {chef.distanceKm} كم · {chef.yearsCooking} سنة خبرة
                    </div>
                    <div className="tag-row">
                      {chef.specialties.map((s) => (
                        <span key={s} className="mini-tag">
                          {s}
                        </span>
                      ))}
                    </div>
                  </div>
                  {chef.certified && <span className="cert-badge">معتمد</span>}
                </Link>
              ))}
            </div>
          )}
        </>
      )}
    </main>
  )
}
