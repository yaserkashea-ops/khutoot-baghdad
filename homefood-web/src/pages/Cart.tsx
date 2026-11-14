import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { FREE_DELIVERY_FROM_IQD, formatIqd } from '../data/mock'
import { EmptyState } from '../components/EmptyState'

export function Cart() {
  const {
    zoneId,
    cart,
    updateQty,
    cartSubtotal,
    deliveryFee,
    cartTotal,
    freeDeliveryRemaining,
  } = useApp()

  if (!zoneId) return <Navigate to="/" replace />

  if (cart.length === 0) {
    return (
      <main className="page">
        <EmptyState
          title="سلتك فارغة"
          body="تصفّح قائمة اليوم أو المفرزنات وأضف ما تشتهي."
          actionTo="/menu"
          actionLabel="قائمة اليوم"
        />
        <div style={{ display: 'flex', justifyContent: 'center', marginTop: '0.75rem' }}>
          <Link to="/frozen" className="btn btn-ghost">
            مفرزنات
          </Link>
        </div>
      </main>
    )
  }

  return (
    <main className="page">
      <div className="section-head">
        <h2>السلة</h2>
        <Link to="/menu" className="linkish">
          متابعة التسوق
        </Link>
      </div>

      {freeDeliveryRemaining > 0 ? (
        <div className="banner-soft anim-fade">
          أضف {formatIqd(freeDeliveryRemaining)} لتحصل على توصيل مجاني داخل الكرادة
          <div className="progress-track">
            <div
              className="progress-fill"
              style={{
                width: `${Math.min(100, ((FREE_DELIVERY_FROM_IQD - freeDeliveryRemaining) / FREE_DELIVERY_FROM_IQD) * 100)}%`,
              }}
            />
          </div>
        </div>
      ) : (
        <div className="banner-soft success">التوصيل مجاني لهذا الطلب ✨</div>
      )}

      <div className="cart-list anim-rise">
        {cart.map((item) => {
          const key = item.lineKey ?? `${item.id}::${item.meta ?? ''}`
          return (
            <div key={key} className="cart-row">
              <div>
                <h3>{item.name}</h3>
                <div className="meta">
                  {item.chefName}
                  {item.meta ? ` · ${item.meta}` : ''}
                </div>
                <div className="qty-ctrl">
                  <button type="button" onClick={() => updateQty(key, item.qty - 1)} aria-label="إنقاص">
                    −
                  </button>
                  <span>{item.qty}</span>
                  <button type="button" onClick={() => updateQty(key, item.qty + 1)} aria-label="زيادة">
                    +
                  </button>
                </div>
              </div>
              <div className="price">{formatIqd(item.priceIqd * item.qty)}</div>
            </div>
          )
        })}
      </div>

      <div className="summary-box">
        <div className="row">
          <span>المجموع الفرعي</span>
          <span>{formatIqd(cartSubtotal)}</span>
        </div>
        <div className="row">
          <span>رسوم التوصيل</span>
          <span>{deliveryFee === 0 ? 'مجاني' : formatIqd(deliveryFee)}</span>
        </div>
        <div className="row total">
          <span>الإجمالي</span>
          <span>{formatIqd(cartTotal)}</span>
        </div>
      </div>

      <Link to="/checkout" className="btn btn-primary btn-block">
        إتمام الطلب · نقد عند الاستلام
      </Link>
    </main>
  )
}
