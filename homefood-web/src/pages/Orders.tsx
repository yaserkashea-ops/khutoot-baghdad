import { Link, Navigate } from 'react-router-dom'
import { useApp } from '../context/AppContext'
import { formatIqd } from '../data/mock'
import { EmptyState } from '../components/EmptyState'

const STATUS_AR: Record<string, string> = {
  received: 'مستلم',
  preparing: 'قيد التحضير',
  ready: 'جاهز',
  out_for_delivery: 'خرج للتوصيل',
  delivered: 'تم التسليم',
}

export function Orders() {
  const { zoneId, orders } = useApp()
  if (!zoneId) return <Navigate to="/" replace />

  if (orders.length === 0) {
    return (
      <main className="page">
        <EmptyState
          title="لا طلبات بعد"
          body="عند إتمام طلب نقداً عند الاستلام سيظهر هنا مع خط زمني للحالة."
          actionTo="/menu"
          actionLabel="تصفّح القائمة"
        />
      </main>
    )
  }

  return (
    <main className="page">
      <div className="section-head">
        <div>
          <h2>طلباتي</h2>
          <p className="subtle">سجل محلي على هذا الجهاز · بيانات تجريبية</p>
        </div>
      </div>

      <div className="order-list anim-rise">
        {orders.map((o) => (
          <Link key={o.id} to={`/order/${o.id}`} className="order-card order-link">
            <div className="order-card-top">
              <div className="id">{o.id}</div>
              <span className="status-pill">{STATUS_AR[o.status] ?? o.status}</span>
            </div>
            <div className="meta">
              {o.createdDate} · {o.createdAt} · {o.window}
            </div>
            <div className="meal-foot" style={{ marginTop: '0.55rem' }}>
              <div className="price">{formatIqd(o.totalIqd)}</div>
              <span className="subtle">{o.items.length} صنف · نقد عند الاستلام</span>
            </div>
          </Link>
        ))}
      </div>
    </main>
  )
}
