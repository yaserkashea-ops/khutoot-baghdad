export type ZoneId = 'karada' | 'mansour'

export interface Zone {
  id: ZoneId
  name: string
  tagline: string
  available: boolean
}

export interface Chef {
  id: string
  name: string
  kitchenName: string
  bio: string
  rating: number
  reviewCount: number
  distanceKm: number
  certified: boolean
  specialties: string[]
  accent: string
  photoHint: string
}

export interface Meal {
  id: string
  chefId: string
  name: string
  description: string
  priceIqd: number
  remaining: number
  window: string
  accent: string
  emoji: string
}

export type FrozenState = 'frozen' | 'chilled'
export type UnitType = 'piece' | 'weight'

export interface FrozenProduct {
  id: string
  chefId: string
  name: string
  category: string
  priceIqd: number
  unit: UnitType
  unitLabel: string
  state: FrozenState
  /** Arabic label shown on the product (فrying / oven / serving). */
  stateLabel: string
  accent: string
}

export interface Review {
  id: string
  chefId: string
  author: string
  rating: number
  text: string
  date: string
}

export type OrderStatus =
  | 'received'
  | 'preparing'
  | 'ready'
  | 'out_for_delivery'
  | 'delivered'

export interface OrderEvent {
  status: OrderStatus
  label: string
  at: string
  done: boolean
}

export interface CartItem {
  id: string
  kind: 'meal' | 'frozen'
  name: string
  chefName: string
  priceIqd: number
  qty: number
  meta?: string
}

export const ZONES: Zone[] = [
  {
    id: 'karada',
    name: 'الكرادة',
    tagline: 'غداء موظفين + طبخ بيتي قريب',
    available: true,
  },
  {
    id: 'mansour',
    name: 'المنصور',
    tagline: 'قريباً — توسّع المرحلة التالية',
    available: false,
  },
]

export const CHEFS: Chef[] = [
  {
    id: 'chef-um-ahmed',
    name: 'أم أحمد',
    kitchenName: 'مطبخ أم أحمد',
    bio: 'أطبخ منذ خمسة عشر عاماً لأهل البيت والجيران. دولمتي تُحجز قبل الظهيرة، والمرق على نار هادئة كل صباح.',
    rating: 4.9,
    reviewCount: 128,
    distanceKm: 1.2,
    certified: true,
    specialties: ['دولمة', 'مرق بامية', 'تشريب'],
    accent: '#6b7c3a',
    photoHint: 'قدر نحاسي وطبخة بيتي',
  },
  {
    id: 'chef-abu-sara',
    name: 'أبو سارة',
    kitchenName: 'بيت أبو سارة',
    bio: 'برياني بغداد وتمن أحمر بطريقتي. أجهّز الطلبات المسبقة قبل العاشرة حتى يوصل الغداء ساخناً.',
    rating: 4.7,
    reviewCount: 86,
    distanceKm: 2.1,
    certified: true,
    specialties: ['برياني', 'تمن أحمر', 'كباب بيتي'],
    accent: '#8a5a2b',
    photoHint: 'طبق برياني بالزعفران',
  },
  {
    id: 'chef-um-zainab',
    name: 'أم زينب',
    kitchenName: 'مفرزنات أم زينب',
    bio: 'كبة برغل وحلب وسمبوسك على أصولها، مجمّدة بعناية وجاهزة للقلي أو الفرن.',
    rating: 4.8,
    reviewCount: 203,
    distanceKm: 0.9,
    certified: true,
    specialties: ['كبة', 'سمبوسك', 'بورك'],
    accent: '#3d6b6b',
    photoHint: 'صينية كبة مرتبة',
  },
  {
    id: 'chef-hala',
    name: 'هالة',
    kitchenName: 'مطبخ هالة',
    bio: 'وجبات خفيفة وصحية للدوام: سلطة، شوربة، وأطباق يومية بحصص مناسبة.',
    rating: 4.6,
    reviewCount: 54,
    distanceKm: 2.8,
    certified: false,
    specialties: ['شوربة', 'سلطة', 'مكدوس'],
    accent: '#5a6b4a',
    photoHint: 'طبق غداء خفيف',
  },
]

export const MEALS: Meal[] = [
  {
    id: 'meal-dolma',
    chefId: 'chef-um-ahmed',
    name: 'دولمة مشكلة',
    description: 'ورق عنب، بصل محشي، وكوسة — حصة وافرة لشخص واحد.',
    priceIqd: 9000,
    remaining: 6,
    window: '١٢:٠٠ – ٢:٠٠',
    accent: '#6b7c3a',
    emoji: '🍃',
  },
  {
    id: 'meal-bamia',
    chefId: 'chef-um-ahmed',
    name: 'مرق بامية بلحم',
    description: 'مرق بيتي مع تمن أبيض طازج.',
    priceIqd: 7500,
    remaining: 3,
    window: '١٢:٠٠ – ٢:٠٠',
    accent: '#7a8f45',
    emoji: '🍲',
  },
  {
    id: 'meal-biryani',
    chefId: 'chef-abu-sara',
    name: 'برياني دجاج',
    description: 'رز مبهر بالزعفران مع دجاج متبّل.',
    priceIqd: 8500,
    remaining: 8,
    window: '١٢:٠٠ – ٢:٠٠',
    accent: '#8a5a2b',
    emoji: '🍚',
  },
  {
    id: 'meal-timman',
    chefId: 'chef-abu-sara',
    name: 'تمن أحمر ومرق',
    description: 'تمن أحمر كلاسيكي مع مرقة يومية.',
    priceIqd: 7000,
    remaining: 0,
    window: '١٢:٠٠ – ٢:٠٠',
    accent: '#9a4a2a',
    emoji: '🍛',
  },
  {
    id: 'meal-soup',
    chefId: 'chef-hala',
    name: 'شوربة عدس وسلطة',
    description: 'وجبة خفيفة مناسبة لمكتب العمل.',
    priceIqd: 5500,
    remaining: 11,
    window: '١٢:٠٠ – ٢:٠٠',
    accent: '#5a6b4a',
    emoji: '🥗',
  },
]

export const FROZEN_CATEGORIES = [
  'الكل',
  'كبة برغل',
  'كبة حلب',
  'سمبوسك',
  'بورك',
  'فطائر',
  'مخللات',
] as const

export const FROZEN: FrozenProduct[] = [
  {
    id: 'fr-kubba-b',
    chefId: 'chef-um-zainab',
    name: 'كبة برغل مشكلة',
    category: 'كبة برغل',
    priceIqd: 12000,
    unit: 'weight',
    unitLabel: 'كيلو',
    state: 'frozen',
    stateLabel: 'مجمّد جاهز للقلي',
    accent: '#3d6b6b',
  },
  {
    id: 'fr-kubba-h',
    chefId: 'chef-um-zainab',
    name: 'كبة حلب جاهزة للقلي',
    category: 'كبة حلب',
    priceIqd: 10000,
    unit: 'weight',
    unitLabel: 'نصف كيلو',
    state: 'frozen',
    stateLabel: 'مجمّد جاهز للقلي',
    accent: '#2f5a5a',
  },
  {
    id: 'fr-sambo',
    chefId: 'chef-um-zainab',
    name: 'سمبوسك لحم',
    category: 'سمبوسك',
    priceIqd: 500,
    unit: 'piece',
    unitLabel: 'قطعة',
    state: 'frozen',
    stateLabel: 'مجمّد جاهز للقلي',
    accent: '#4a6b3d',
  },
  {
    id: 'fr-borek',
    chefId: 'chef-um-zainab',
    name: 'بورك جبن وسبانخ',
    category: 'بورك',
    priceIqd: 8000,
    unit: 'weight',
    unitLabel: 'صينية صغيرة',
    state: 'chilled',
    stateLabel: 'مبرد جاهز للفرن',
    accent: '#6b5a3d',
  },
  {
    id: 'fr-pastry',
    chefId: 'chef-hala',
    name: 'فطائر زعتر',
    category: 'فطائر',
    priceIqd: 1500,
    unit: 'piece',
    unitLabel: 'قطعة',
    state: 'chilled',
    stateLabel: 'مبرد جاهز للفرن',
    accent: '#5a6b4a',
  },
  {
    id: 'fr-pickle',
    chefId: 'chef-um-ahmed',
    name: 'مخلل منزلي مشكل',
    category: 'مخللات',
    priceIqd: 4000,
    unit: 'piece',
    unitLabel: 'علبة',
    state: 'chilled',
    stateLabel: 'مبرد جاهز للتقديم',
    accent: '#6b7c3a',
  },
]

export const REVIEWS: Review[] = [
  {
    id: 'r1',
    chefId: 'chef-um-ahmed',
    author: 'سارة م.',
    rating: 5,
    text: 'الدولمة طعم بيت حقيقي، ووصلت ساخنة قبل الواحدة.',
    date: 'منذ يومين',
  },
  {
    id: 'r2',
    chefId: 'chef-um-ahmed',
    author: 'حسين ك.',
    rating: 5,
    text: 'المطبخ معتمد والصورة تطابق الواقع. سأعيد الطلب غداً.',
    date: 'منذ أسبوع',
  },
  {
    id: 'r3',
    chefId: 'chef-abu-sara',
    author: 'نور ع.',
    rating: 4,
    text: 'البرياني ممتاز، الكمية مناسبة لموظف واحد.',
    date: 'منذ ٣ أيام',
  },
  {
    id: 'r4',
    chefId: 'chef-um-zainab',
    author: 'زينب ر.',
    rating: 5,
    text: 'كبة البرغل الأفضل في الكرادة. مجمّدة نظيفة ومرتبة.',
    date: 'منذ ٥ أيام',
  },
]

export const DELIVERY_FEE_IQD = 2000

export function formatIqd(n: number): string {
  return `${n.toLocaleString('ar-IQ')} د.ع`
}

export function chefById(id: string): Chef | undefined {
  return CHEFS.find((c) => c.id === id)
}

export function mealsForChef(chefId: string): Meal[] {
  return MEALS.filter((m) => m.chefId === chefId)
}

export function frozenForChef(chefId: string): FrozenProduct[] {
  return FROZEN.filter((p) => p.chefId === chefId)
}

export function reviewsForChef(chefId: string): Review[] {
  return REVIEWS.filter((r) => r.chefId === chefId)
}

export function buildOrderTimeline(nowLabel = 'الآن'): OrderEvent[] {
  return [
    { status: 'received', label: 'تم استلام الطلب', at: nowLabel, done: true },
    { status: 'preparing', label: 'قيد التحضير عند الطاهي', at: 'قريباً', done: false },
    { status: 'ready', label: 'جاهز للاستلام من المندوب', at: '—', done: false },
    {
      status: 'out_for_delivery',
      label: 'خرج للتوصيل',
      at: '—',
      done: false,
    },
    { status: 'delivered', label: 'تم التسليم', at: '—', done: false },
  ]
}
