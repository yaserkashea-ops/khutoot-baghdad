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
  FREE_DELIVERY_FROM_IQD,
  type CartItem,
  type OrderEvent,
  type OrderStatus,
  type ZoneId,
} from '../data/mock'

export interface PlacedOrder {
  id: string
  items: CartItem[]
  totalIqd: number
  subtotalIqd: number
  deliveryFeeIqd: number
  address: string
  note: string
  window: string
  payment: 'cod'
  timeline: OrderEvent[]
  status: OrderStatus
  createdAt: string
  createdDate: string
}

interface AppState {
  zoneId: ZoneId | null
  setZone: (id: ZoneId) => void
  clearZone: () => void
  cart: CartItem[]
  addToCart: (item: Omit<CartItem, 'qty'> & { lineKey?: string }, qty?: number) => void
  updateQty: (lineKey: string, qty: number) => void
  clearCart: () => void
  cartCount: number
  cartSubtotal: number
  deliveryFee: number
  cartTotal: number
  freeDeliveryRemaining: number
  orders: PlacedOrder[]
  order: PlacedOrder | null
  placeOrder: (input: {
    address: string
    note: string
    window: string
  }) => PlacedOrder
  getOrder: (id: string) => PlacedOrder | undefined
  toast: string | null
  showToast: (msg: string) => void
  dismissToast: () => void
}

const AppContext = createContext<AppState | null>(null)

const ZONE_KEY = 'homefood-zone'
const CART_KEY = 'homefood-cart'
const ORDERS_KEY = 'homefood-orders'
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

function lineId(item: { id: string; lineKey?: string; meta?: string }) {
  return item.lineKey ?? `${item.id}::${item.meta ?? ''}`
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [zoneId, setZoneId] = useState<ZoneId | null>(() => {
    const saved = localStorage.getItem(ZONE_KEY)
    return saved === 'karada' || saved === 'mansour' ? saved : null
  })
  const [cart, setCart] = useState<CartItem[]>(() => {
    const items = readJson<CartItem[]>(CART_KEY, [])
    return items.map((i) => ({ ...i, lineKey: lineId(i) }))
  })
  const [orders, setOrders] = useState<PlacedOrder[]>(() => {
    const list = readJson<PlacedOrder[]>(ORDERS_KEY, [])
    if (list.length) return list
    const legacy = readJson<PlacedOrder | null>(ORDER_KEY, null)
    return legacy ? [legacy] : []
  })
  const [toast, setToast] = useState<string | null>(null)

  const showToast = useCallback((msg: string) => {
    setToast(msg)
    window.setTimeout(() => setToast(null), 2400)
  }, [])

  const dismissToast = useCallback(() => setToast(null), [])

  const setZone = useCallback((id: ZoneId) => {
    setZoneId(id)
    localStorage.setItem(ZONE_KEY, id)
  }, [])

  const clearZone = useCallback(() => {
    setZoneId(null)
    localStorage.removeItem(ZONE_KEY)
  }, [])

  const persistCart = useCallback((next: CartItem[]) => {
    setCart(next)
    localStorage.setItem(CART_KEY, JSON.stringify(next))
  }, [])

  const addToCart = useCallback(
    (item: Omit<CartItem, 'qty'> & { lineKey?: string }, qty = 1) => {
      const key = lineId(item)
      setCart((prev) => {
        const existing = prev.find((p) => lineId(p) === key)
        const next = existing
          ? prev.map((p) =>
              lineId(p) === key ? { ...p, qty: p.qty + qty } : p,
            )
          : [...prev, { ...item, qty, lineKey: key }]
        localStorage.setItem(CART_KEY, JSON.stringify(next))
        return next
      })
      showToast('أُضيف إلى السلة')
    },
    [showToast],
  )

  const updateQty = useCallback((key: string, qty: number) => {
    setCart((prev) => {
      const next =
        qty <= 0
          ? prev.filter((p) => lineId(p) !== key)
          : prev.map((p) => (lineId(p) === key ? { ...p, qty } : p))
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
  const deliveryFee =
    cart.length === 0
      ? 0
      : cartSubtotal >= FREE_DELIVERY_FROM_IQD
        ? 0
        : DELIVERY_FEE_IQD
  const cartTotal = cartSubtotal + deliveryFee
  const freeDeliveryRemaining = Math.max(0, FREE_DELIVERY_FROM_IQD - cartSubtotal)

  const placeOrder = useCallback(
    (input: { address: string; note: string; window: string }) => {
      const now = new Date()
      const placed: PlacedOrder = {
        id: `HF-${Math.floor(1000 + Math.random() * 9000)}`,
        items: cart,
        totalIqd: cartTotal,
        subtotalIqd: cartSubtotal,
        deliveryFeeIqd: deliveryFee,
        address: input.address,
        note: input.note,
        window: input.window,
        payment: 'cod',
        status: 'preparing',
        timeline: buildOrderTimeline(
          now.toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' }),
          'preparing',
        ),
        createdAt: now.toLocaleTimeString('ar-IQ', {
          hour: '2-digit',
          minute: '2-digit',
        }),
        createdDate: now.toLocaleDateString('ar-IQ'),
      }
      setOrders((prev) => {
        const next = [placed, ...prev]
        localStorage.setItem(ORDERS_KEY, JSON.stringify(next))
        localStorage.setItem(ORDER_KEY, JSON.stringify(placed))
        return next
      })
      persistCart([])
      showToast('تم تأكيد طلبك · نقد عند الاستلام')
      return placed
    },
    [cart, cartTotal, cartSubtotal, deliveryFee, persistCart, showToast],
  )

  const getOrder = useCallback(
    (id: string) => orders.find((o) => o.id === id),
    [orders],
  )

  const order = orders[0] ?? null

  const value: AppState = {
    zoneId,
    setZone,
    clearZone,
    cart,
    addToCart,
    updateQty,
    clearCart,
    cartCount,
    cartSubtotal,
    deliveryFee,
    cartTotal,
    freeDeliveryRemaining,
    orders,
    order,
    placeOrder,
    getOrder,
    toast,
    showToast,
    dismissToast,
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
