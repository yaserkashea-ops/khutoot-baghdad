import { Link, Navigate, useParams } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { formatIqd } from '../data/mock'
import { EmptyState } from '../components/EmptyState'

export function OrderStatus() {
  const { orderId } = useParams()
  const { zoneId, order, getOrder } = useApp()
  if (!zoneId) return <Navigate to="/" replace />

  const current = orderId ? getOrder(orderId) : order

  if (!current) {
    return (
      <main className="page">
        <EmptyState
          title="الطلب غير موجود"
          body="لا يوجد طلب بهذا الرقم على هذا الجهاز."
          actionTo="/orders"
          actionLabel="طلباتي"
        />
      </main>
    )
  }

  const currentIndex = current.timeline.findIndex((e) => !e.done)

  return (
    <main className="page">
      <Link to="/orders" className="back-link">
        → كل الطلبات
      </Link>

      <div className="section-head">
        <div>
          <h2>حالة الطلب</h2>
          <p className="subtle">تتبع نصّي بدون خريطة حية (مرحلة لاحقة)</p>
        </div>
      </div>

      <div className="order-card anim-fade">
        <div className="id">{current.id}</div>
        <div className="meta">
          {current.createdDate} · {current.createdAt} · نافذة {current.window}
        </div>
        <div className="price" style={{ marginTop: '0.55rem' }}>
          {formatIqd(current.totalIqd)} · نقد عند الاستلام
        </div>
        <div className="meta" style={{ marginTop: '0.55rem' }}>
          {current.address}
        </div>
        {current.note && (
          <div style={{ marginTop: '0.35rem', fontSize: '0.88rem' }}>ملاحظة: {current.note}</div>
        )}
      </div>

      <div className="order-card">
        <h3 style={{ marginBottom: '1rem', fontSize: '1.05rem' }}>مسار الحالة</h3>
        <ul className="timeline">
          {current.timeline.map((event, index) => {
            const isCurrent =
              index === (currentIndex === -1 ? current.timeline.length - 1 : currentIndex)
            return (
              <li
                key={event.status}
                className={`${event.done ? 'done' : ''} ${isCurrent && !event.done ? 'current' : ''}`}
              >
                <div className="dot" />
                <div>
                  <strong>{event.label}</strong>
                  <span>{event.at}</span>
                  {event.status === 'out_for_delivery' && (
                    <div style={{ marginTop: '0.35rem', fontSize: '0.85rem', color: 'var(--olive)' }}>
                      عند الخروج للتوصيل سيظهر رقم المندوب هنا
                    </div>
                  )}
                </div>
              </li>
            )
          })}
        </ul>
      </div>

      <div className="section-head">
        <h2>محتويات الطلب</h2>
      </div>
      <div className="cart-list">
        {current.items.map((item, idx) => (
          <div key={`${item.id}-${idx}`} className="cart-row">
            <div>
              <h3>
                {item.name} × {item.qty}
              </h3>
              <div className="meta">
                {item.chefName}
                {item.meta ? ` · ${item.meta}` : ''}
              </div>
            </div>
            <div className="price">{formatIqd(item.priceIqd * item.qty)}</div>
          </div>
        ))}
      </div>

      <Link to="/home" className="btn btn-ghost btn-block">
        العودة للرئيسية
      </Link>
    </main>
  )
}
