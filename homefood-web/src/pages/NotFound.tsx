import { EmptyState } from '../components/EmptyState'

export function NotFound() {
  return (
    <main className="page">
      <EmptyState
        title="الصفحة غير موجودة"
        body="الرابط غير صحيح أو أُزيلت الصفحة من هذه المعاينة."
        actionTo="/home"
        actionLabel="العودة للرئيسية"
      />
    </main>
  )
}
