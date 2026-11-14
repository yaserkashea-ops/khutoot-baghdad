import { useState, type FormEvent } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { PREORDER_WINDOWS, formatIqd } from '../data/mock'

export function Checkout() {
  const { zoneId, cart, cartTotal, order, placeOrder } = useApp()
  const navigate = useNavigate()
  const [address, setAddress] = useState('مكتب الكرادة، قرب ساحة الواثق')
  const [phone, setPhone] = useState('0770 000 0000')
  const [windowLabel, setWindowLabel] = useState(PREORDER_WINDOWS[1].hint)
  const [note, setNote] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  if (!zoneId) return <Navigate to="/" replace />
  if (cart.length === 0 && !submitting) {
    return <Navigate to={order ? `/order/${order.id}` : '/cart'} replace />
  }

  function onSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')
    if (phone.replace(/\D/g, '').length < 10) {
      setError('أدخل رقم هاتف عراقياً صالحاً.')
      return
    }
    if (address.trim().length < 8) {
      setError('العنوان قصير جداً — أضف معلماً قريباً.')
      return
    }
    setSubmitting(true)
    const placed = placeOrder({
      address: `${address} · ${phone}`,
      note,
      window: windowLabel,
    })
    navigate(`/order/${placed.id}`, { replace: true })
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
          <div className="pay-glyph" aria-hidden>
            د.ع
          </div>
          <div>
            <strong>الدفع نقداً عند الاستلام</strong>
            <span>زين كاش لاحقاً — هذه معاينة ببيانات تجريبية.</span>
          </div>
        </div>

        {error && <div className="form-error">{error}</div>}

        <div className="field">
          <label htmlFor="phone">رقم الهاتف</label>
          <input id="phone" value={phone} onChange={(e) => setPhone(e.target.value)} required />
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
            {PREORDER_WINDOWS.map((w) => (
              <option key={w.id} value={w.hint}>
                {w.label} — {w.hint}
              </option>
            ))}
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

        <button type="submit" className="btn btn-primary btn-block" disabled={submitting}>
          تأكيد الطلب
        </button>
      </form>
    </main>
  )
}
