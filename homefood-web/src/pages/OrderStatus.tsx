import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { formatIqd } from '../data/mock'

export function OrderStatus() {
  const { zoneId, order } = useApp()
  if (!zoneId) return <Navigate to="/" replace />

  if (!order) {
    return (
      <main className="page">
        <div className="empty anim-rise">
          <h2>لا يوجد طلب حالياً</h2>
          <p>بعد إتمام الدفع التجريبي ستظهر هنا حالات الطلب النصية.</p>
          <Link to="/home" className="btn btn-primary" style={{ marginTop: '1rem' }}>
            ابدأ التسوق
          </Link>
        </div>
      </main>
    )
  }

  const currentIndex = order.timeline.findIndex((e) => !e.done)

  return (
    <main className="page">
      <div className="section-head">
        <div>
          <h2>حالة الطلب</h2>
          <p style={{ color: 'var(--muted)', fontSize: '0.9rem', marginTop: '0.25rem' }}>
            تتبع نصّي بدون خريطة حية (مرحلة لاحقة)
          </p>
        </div>
      </div>

      <div className="order-card anim-fade">
        <div className="id">{order.id}</div>
        <div style={{ color: 'var(--muted)', marginTop: '0.35rem', fontSize: '0.9rem' }}>
          طُلب الساعة {order.createdAt} · نافذة {order.window}
        </div>
        <div className="price" style={{ marginTop: '0.55rem' }}>
          {formatIqd(order.totalIqd)} · نقد عند الاستلام
        </div>
        <div style={{ marginTop: '0.55rem', fontSize: '0.9rem', color: 'var(--muted)' }}>
          {order.address}
        </div>
        {order.note && (
          <div style={{ marginTop: '0.35rem', fontSize: '0.88rem' }}>ملاحظة: {order.note}</div>
        )}
      </div>

      <div className="order-card">
        <h3 style={{ marginBottom: '1rem', fontSize: '1.05rem' }}>مسار الحالة</h3>
        <ul className="timeline">
          {order.timeline.map((event, index) => {
            const isCurrent = index === (currentIndex === -1 ? order.timeline.length - 1 : currentIndex)
            const done = event.done || (currentIndex === -1 && index < order.timeline.length)
            return (
              <li
                key={event.status}
                className={`${done ? 'done' : ''} ${isCurrent && !event.done ? 'current' : ''}`}
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
        {order.items.map((item) => (
          <div key={item.id} className="cart-row">
            <div>
              <h3>
                {item.name} × {item.qty}
              </h3>
              <div className="meta">{item.chefName}</div>
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
