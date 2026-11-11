import { useState, type FormEvent } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { formatIqd } from '../data/mock'

export function Checkout() {
  const {
    zoneId,
    cart,
    cartTotal,
    order,
    placeOrder,
  } = useApp()
  const navigate = useNavigate()
  const [address, setAddress] = useState('مكتب الكرادة، قرب ساحة الواثق')
  const [phone, setPhone] = useState('07xx xxx xxxx')
  const [windowLabel, setWindowLabel] = useState('١٢:٠٠ – ٢:٠٠')
  const [note, setNote] = useState('')
  const [submitting, setSubmitting] = useState(false)

  if (!zoneId) return <Navigate to="/" replace />
  // After placeOrder clears the cart, prefer the order page over bouncing to /cart.
  if (cart.length === 0 && !submitting) {
    return <Navigate to={order ? '/order' : '/cart'} replace />
  }

  function onSubmit(e: FormEvent) {
    e.preventDefault()
    setSubmitting(true)
    placeOrder({
      address: `${address} · ${phone}`,
      note,
      window: windowLabel,
    })
    navigate('/order', { replace: true })
  }

  return (
    <main className="page page-tight">
      <Link to="/cart" className="back-link">
        → الرجوع للسلة
      </Link>

      <div className="section-head">
        <h2>إتمام الطلب</h2>
      </div>

      <form onSubmit={onSubmit} className="anim-rise">
        <div className="pay-note">
          <div style={{ fontSize: '1.4rem' }}>💵</div>
          <div>
            <strong>الدفع نقداً عند الاستلام</strong>
            <span>زين كاش والمحافظ الإلكترونية قادمة في المرحلة التالية — هذا العرض تجريبي.</span>
          </div>
        </div>

        <div className="field">
          <label htmlFor="phone">رقم الهاتف</label>
          <input
            id="phone"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            required
          />
        </div>

        <div className="field">
          <label htmlFor="address">عنوان التوصيل</label>
          <textarea
            id="address"
            rows={2}
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            required
          />
        </div>

        <div className="field">
          <label htmlFor="window">نافذة الاستلام</label>
          <select
            id="window"
            value={windowLabel}
            onChange={(e) => setWindowLabel(e.target.value)}
          >
            <option>١٢:٠٠ – ٢:٠٠</option>
            <option>مساءً (مفرزنات)</option>
          </select>
        </div>

        <div className="field">
          <label htmlFor="note">ملاحظات</label>
          <textarea
            id="note"
            rows={2}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="تعليمات للمندوب أو للطاهي"
          />
        </div>

        <div className="summary-box">
          <div className="row total">
            <span>المبلغ عند الاستلام</span>
            <span>{formatIqd(cartTotal)}</span>
          </div>
        </div>

        <button type="submit" className="btn btn-primary btn-block">
          تأكيد الطلب
        </button>
      </form>
    </main>
  )
}
