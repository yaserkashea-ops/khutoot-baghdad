import { Link, Navigate, useParams } from 'react-router-dom'
import { useMemo, useState } from 'react'
import { useApp } from '../context/AppContext'
import { chefById, formatIqd, frozenById } from '../data/mock'
import { EmptyState } from '../components/EmptyState'

export function FrozenDetail() {
  const { productId } = useParams()
  const { zoneId, addToCart } = useApp()
  const product = frozenById(productId ?? '')
  const chef = product ? chefById(product.chefId) : undefined

  const [weightId, setWeightId] = useState(product?.weightOptions?.[0]?.id ?? '')
  const [qty, setQty] = useState(product?.unit === 'piece' ? 10 : 1)

  const selectedWeight = useMemo(
    () => product?.weightOptions?.find((w) => w.id === weightId) ?? product?.weightOptions?.[0],
    [product, weightId],
  )

  const unitPrice = useMemo(() => {
    if (!product) return 0
    if (product.unit === 'weight' && selectedWeight) {
      return Math.round(product.priceIqd * selectedWeight.multiplier)
    }
    return product.priceIqd
  }, [product, selectedWeight])

  const unitMeta =
    product?.unit === 'weight'
      ? selectedWeight?.label ?? product.unitLabel
      : product?.unitLabel ?? ''

  if (!zoneId) return <Navigate to="/" replace />
  if (!product || !chef) {
    return (
      <main className="page">
        <EmptyState
          title="المنتج غير موجود"
          body="تحقق من الرابط أو عد إلى متجر المفرزنات."
          actionTo="/frozen"
          actionLabel="المفرزنات"
        />
      </main>
    )
  }

  const minPiece = product.unit === 'piece' && product.category === 'سمبوسك' ? 10 : 1

  return (
    <main className="page">
      <Link to="/frozen" className="back-link">
        → رجوع للمفرزنات
      </Link>

      <section
        className="detail-hero anim-fade"
        style={{ background: `linear-gradient(145deg, ${product.accent}, #1c2418)` }}
      >
        <span className={`state-tag on-dark ${product.state}`}>{product.stateLabel}</span>
        <h1>{product.name}</h1>
        <p>
          <Link to={`/chef/${chef.id}`}>{chef.kitchenName}</Link> · {product.category}
        </p>
      </section>

      <p className="bio">{product.description}</p>
      <p className="subtle" style={{ marginBottom: '1rem' }}>
        {product.packHint}
      </p>

      {product.unit === 'weight' && product.weightOptions && (
        <>
          <div className="section-head">
            <h2>اختر الوزن / الحجم</h2>
          </div>
          <div className="window-pills">
            {product.weightOptions.map((w) => (
              <button
                key={w.id}
                type="button"
                className={selectedWeight?.id === w.id ? 'active' : ''}
                onClick={() => setWeightId(w.id)}
              >
                {w.label} · {formatIqd(Math.round(product.priceIqd * w.multiplier))}
              </button>
            ))}
          </div>
        </>
      )}

      {product.unit === 'piece' && (
        <>
          <div className="section-head">
            <h2>الكمية بالقطعة</h2>
          </div>
          <p className="subtle" style={{ marginBottom: '0.6rem' }}>
            سعر القطعة {formatIqd(product.priceIqd)}
            {minPiece > 1 ? ` · حد أدنى ${minPiece}` : ''}
          </p>
        </>
      )}

      <div className="detail-cta sticky-cta">
        <div className="qty-ctrl">
          <button
            type="button"
            onClick={() => setQty((q) => Math.max(minPiece, q - (product.unit === 'piece' ? 1 : 1)))}
          >
            −
          </button>
          <span>{qty}</span>
          <button type="button" onClick={() => setQty((q) => q + 1)}>
            +
          </button>
        </div>
        <button
          type="button"
          className="btn btn-olive"
          onClick={() =>
            addToCart(
              {
                id: product.id,
                kind: 'frozen',
                name: product.name,
                chefName: chef.name,
                priceIqd: unitPrice,
                meta: `${unitMeta} · ${product.stateLabel}`,
                lineKey: `${product.id}::${unitMeta}`,
              },
              qty,
            )
          }
        >
          أضف · {formatIqd(unitPrice * qty)}
        </button>
      </div>
    </main>
  )
}
