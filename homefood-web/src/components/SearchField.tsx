export function SearchField({
  value,
  onChange,
  placeholder = 'ابحث عن طاهٍ أو طبق…',
}: {
  value: string
  onChange: (v: string) => void
  placeholder?: string
}) {
  return (
    <label className="search-field">
      <span className="search-icon" aria-hidden>
        ⌕
      </span>
      <input
        type="search"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        enterKeyHint="search"
      />
      {value && (
        <button type="button" className="search-clear" onClick={() => onChange('')} aria-label="مسح">
          ×
        </button>
      )}
    </label>
  )
}
