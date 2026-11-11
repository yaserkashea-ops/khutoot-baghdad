import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { formatIqd } from '../data/mock'

export function Cart() {
  const {
    zoneId,
    cart,
    updateQty,
    cartSubtotal,
    deliveryFee,
    cartTotal,
  } = useApp()

  if (!zoneId) return <Navigate to="/" replace />

  if (cart.length === 0) {
    return (
      <main className="page">
        <div className="empty anim-rise">
          <h2>سلتك فارغة</h2>
          <p>تصفّح قائمة اليوم أو المفرزنات وأضف ما تشتهي.</p>
          <div style={{ display: 'flex', gap: '0.6rem', justifyContent: 'center', marginTop: '1.1rem' }}>
            <Link to="/menu" className="btn btn-primary">
              قائمة اليوم
            </Link>
            <Link to="/frozen" className="btn btn-ghost">
              مفرزنات
            </Link>
          </div>
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

      <div className="cart-list anim-rise">
        {cart.map((item) => (
          <div key={item.id} className="cart-row">
            <div>
              <h3>{item.name}</h3>
              <div className="meta">
                {item.chefName}
                {item.meta ? ` · ${item.meta}` : ''}
              </div>
              <div className="qty-ctrl">
                <button type="button" onClick={() => updateQty(item.id, item.qty - 1)} aria-label="إنقاص">
                  −
                </button>
                <span>{item.qty}</span>
                <button type="button" onClick={() => updateQty(item.id, item.qty + 1)} aria-label="زيادة">
                  +
                </button>
              </div>
            </div>
            <div className="price">{formatIqd(item.priceIqd * item.qty)}</div>
          </div>
        ))}
      </div>

      <div className="summary-box">
        <div className="row">
          <span>المجموع الفرعي</span>
          <span>{formatIqd(cartSubtotal)}</span>
        </div>
        <div className="row">
          <span>رسوم التوصيل</span>
          <span>{formatIqd(deliveryFee)}</span>
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
