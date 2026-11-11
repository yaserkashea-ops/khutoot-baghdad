import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  buildOrderTimeline,
  chefById,
  DELIVERY_FEE_IQD,
  type CartItem,
  type OrderEvent,
  type ZoneId,
} from '../data/mock'

interface PlacedOrder {
  id: string
  items: CartItem[]
  totalIqd: number
  address: string
  note: string
  window: string
  payment: 'cod'
  timeline: OrderEvent[]
  createdAt: string
}

interface AppState {
  zoneId: ZoneId | null
  setZone: (id: ZoneId) => void
  cart: CartItem[]
  addToCart: (item: Omit<CartItem, 'qty'>, qty?: number) => void
  updateQty: (id: string, qty: number) => void
  clearCart: () => void
  cartCount: number
  cartSubtotal: number
  deliveryFee: number
  cartTotal: number
  order: PlacedOrder | null
  placeOrder: (input: {
    address: string
    note: string
    window: string
  }) => PlacedOrder
}

const AppContext = createContext<AppState | null>(null)

const ZONE_KEY = 'homefood-zone'
const CART_KEY = 'homefood-cart'
const ORDER_KEY = 'homefood-order'

function readJson<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return fallback
    return JSON.parse(raw) as T
  } catch {
    return fallback
  }
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [zoneId, setZoneId] = useState<ZoneId | null>(() => {
    const saved = localStorage.getItem(ZONE_KEY)
    return saved === 'karada' || saved === 'mansour' ? saved : null
  })
  const [cart, setCart] = useState<CartItem[]>(() =>
    readJson<CartItem[]>(CART_KEY, []),
  )
  const [order, setOrder] = useState<PlacedOrder | null>(() =>
    readJson<PlacedOrder | null>(ORDER_KEY, null),
  )

  const setZone = useCallback((id: ZoneId) => {
    setZoneId(id)
    localStorage.setItem(ZONE_KEY, id)
  }, [])

  const persistCart = useCallback((next: CartItem[]) => {
    setCart(next)
    localStorage.setItem(CART_KEY, JSON.stringify(next))
  }, [])

  const addToCart = useCallback(
    (item: Omit<CartItem, 'qty'>, qty = 1) => {
      setCart((prev) => {
        const existing = prev.find((p) => p.id === item.id)
        const next = existing
          ? prev.map((p) =>
              p.id === item.id ? { ...p, qty: p.qty + qty } : p,
            )
          : [...prev, { ...item, qty }]
        localStorage.setItem(CART_KEY, JSON.stringify(next))
        return next
      })
    },
    [],
  )

  const updateQty = useCallback((id: string, qty: number) => {
    setCart((prev) => {
      const next =
        qty <= 0 ? prev.filter((p) => p.id !== id) : prev.map((p) => (p.id === id ? { ...p, qty } : p))
      localStorage.setItem(CART_KEY, JSON.stringify(next))
      return next
    })
  }, [])

  const clearCart = useCallback(() => persistCart([]), [persistCart])

  const cartCount = useMemo(
    () => cart.reduce((sum, i) => sum + i.qty, 0),
    [cart],
  )
  const cartSubtotal = useMemo(
    () => cart.reduce((sum, i) => sum + i.priceIqd * i.qty, 0),
    [cart],
  )
  const deliveryFee = cart.length ? DELIVERY_FEE_IQD : 0
  const cartTotal = cartSubtotal + deliveryFee

  const placeOrder = useCallback(
    (input: { address: string; note: string; window: string }) => {
      const placed: PlacedOrder = {
        id: `HF-${Math.floor(1000 + Math.random() * 9000)}`,
        items: cart,
        totalIqd: cartTotal,
        address: input.address,
        note: input.note,
        window: input.window,
        payment: 'cod',
        timeline: buildOrderTimeline(),
        createdAt: new Date().toLocaleTimeString('ar-IQ', {
          hour: '2-digit',
          minute: '2-digit',
        }),
      }
      setOrder(placed)
      localStorage.setItem(ORDER_KEY, JSON.stringify(placed))
      persistCart([])
      return placed
    },
    [cart, cartTotal, persistCart],
  )

  const value: AppState = {
    zoneId,
    setZone,
    cart,
    addToCart,
    updateQty,
    clearCart,
    cartCount,
    cartSubtotal,
    deliveryFee,
    cartTotal,
    order,
    placeOrder,
  }

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>
}

export function useApp() {
  const ctx = useContext(AppContext)
  if (!ctx) throw new Error('useApp must be used within AppProvider')
  return ctx
}

export function useChefName(chefId: string) {
  return chefById(chefId)?.name ?? 'طاهٍ'
}
