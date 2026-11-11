import { Link } from 'react-router-dom'

export function EmptyState({
  title,
  body,
  actionTo,
  actionLabel,
}: {
  title: string
  body: string
  actionTo?: string
  actionLabel?: string
}) {
  return (
    <div className="empty anim-rise">
      <div className="empty-glyph" aria-hidden>
        ◌
      </div>
      <h2>{title}</h2>
      <p>{body}</p>
      {actionTo && actionLabel && (
        <Link to={actionTo} className="btn btn-primary" style={{ marginTop: '1rem' }}>
          {actionLabel}
        </Link>
      )}
    </div>
  )
}
