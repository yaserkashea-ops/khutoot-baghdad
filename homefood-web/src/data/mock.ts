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
  yearsCooking: number
}

export interface Meal {
  id: string
  chefId: string
  name: string
  description: string
  longDescription: string
  ingredients: string[]
  tags: string[]
  priceIqd: number
  remaining: number
  window: string
  prepMinutes: number
  spice: 'mild' | 'medium' | 'hot'
  accent: string
  emoji: string
}

export type FrozenState = 'frozen' | 'chilled'
export type UnitType = 'piece' | 'weight'

export interface WeightOption {
  id: string
  label: string
  multiplier: number
}

export interface FrozenProduct {
  id: string
  chefId: string
  name: string
  description: string
  category: string
  priceIqd: number
  unit: UnitType
  unitLabel: string
  state: FrozenState
  stateLabel: string
  weightOptions?: WeightOption[]
  packHint: string
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
  lineKey?: string
}

export interface PreOrderWindow {
  id: string
  label: string
  hint: string
  cutoff: string
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

export const PREORDER_WINDOWS: PreOrderWindow[] = [
  {
    id: 'tonight-lunch',
    label: 'احجز الليلة · غداء غدٍ',
    hint: 'نافذة التوصيل ١٢:٠٠ – ٢:٠٠',
    cutoff: 'إغلاق الحجز ١١:٣٠ م',
  },
  {
    id: 'morning-lunch',
    label: 'احجز صباحاً · غداء اليوم',
    hint: 'نافذة التوصيل ١٢:٠٠ – ٢:٠٠',
    cutoff: 'آخر طلب ١٠:٠٠ ص',
  },
  {
    id: 'evening-frozen',
    label: 'توصيل مسائي · مفرزنات',
    hint: '٥:٠٠ – ٨:٠٠ م · خارج ذروة الغداء',
    cutoff: 'طلب قبل ٣:٠٠ م',
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
    yearsCooking: 15,
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
    yearsCooking: 10,
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
    yearsCooking: 12,
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
    yearsCooking: 6,
  },
  {
    id: 'chef-um-noor',
    name: 'أم نور',
    kitchenName: 'مطبخ أم نور',
    bio: 'أطباق تراثية بغدادية بلمسة خفيفة من الحامض والبهارات البيتية.',
    rating: 4.5,
    reviewCount: 41,
    distanceKm: 3.1,
    certified: true,
    specialties: ['تشريب', 'قيمه', 'كبه مقلية'],
    accent: '#7a5538',
    photoHint: 'مائدة بيتية',
    yearsCooking: 18,
  },
]

export const MEALS: Meal[] = [
  {
    id: 'meal-dolma',
    chefId: 'chef-um-ahmed',
    name: 'دولمة مشكلة',
    description: 'ورق عنب، بصل محشي، وكوسة — حصة وافرة لشخص واحد.',
    longDescription:
      'دولمة على أصول بغداد: ورق عنب طري، بصل محشي، وكوسة محشوة بلحم ناعم ورز متبّل. تُقدَّم ساخنة مع لبن رائب.',
    ingredients: ['ورق عنب', 'بصل', 'كوسة', 'لحم', 'رز', 'بهارات بيتية'],
    tags: ['تراثي', 'وجبة غداء', 'لحم'],
    priceIqd: 9000,
    remaining: 6,
    window: '١٢:٠٠ – ٢:٠٠',
    prepMinutes: 45,
    spice: 'mild',
    accent: '#6b7c3a',
    emoji: '🍃',
  },
  {
    id: 'meal-bamia',
    chefId: 'chef-um-ahmed',
    name: 'مرق بامية بلحم',
    description: 'مرق بيتي مع تمن أبيض طازج.',
    longDescription:
      'مرق بامية بلحم طري على نار هادئة، يُقدَّم مع تمن أبيض مفلفل. مناسب لمكتب أو منزل.',
    ingredients: ['بامية', 'لحم', 'طماطة', 'تمن', 'ثوم'],
    tags: ['مرق', 'وجبة غداء', 'لحم'],
    priceIqd: 7500,
    remaining: 3,
    window: '١٢:٠٠ – ٢:٠٠',
    prepMinutes: 40,
    spice: 'medium',
    accent: '#7a8f45',
    emoji: '🍲',
  },
  {
    id: 'meal-biryani',
    chefId: 'chef-abu-sara',
    name: 'برياني دجاج',
    description: 'رز مبهر بالزعفران مع دجاج متبّل.',
    longDescription:
      'برياني بغدادي بطبقات رز وزعفران ودجاج متبّل، مع مكسرات خفيفة وبطاطس مقرمشة.',
    ingredients: ['رز بسمتي', 'دجاج', 'زعفران', 'بهارات', 'بطاطس'],
    tags: ['برياني', 'دجاج', 'وجبة غداء'],
    priceIqd: 8500,
    remaining: 8,
    window: '١٢:٠٠ – ٢:٠٠',
    prepMinutes: 50,
    spice: 'medium',
    accent: '#8a5a2b',
    emoji: '🍚',
  },
  {
    id: 'meal-timman',
    chefId: 'chef-abu-sara',
    name: 'تمن أحمر ومرق',
    description: 'تمن أحمر كلاسيكي مع مرقة يومية.',
    longDescription: 'تمن أحمر بمرق يوميّ حسب توفر المطبخ — كمية محدودة وتنفد سريعاً.',
    ingredients: ['تمن', 'مرق', 'بهارات'],
    tags: ['تمن', 'وجبة غداء'],
    priceIqd: 7000,
    remaining: 0,
    window: '١٢:٠٠ – ٢:٠٠',
    prepMinutes: 35,
    spice: 'mild',
    accent: '#9a4a2a',
    emoji: '🍛',
  },
  {
    id: 'meal-soup',
    chefId: 'chef-hala',
    name: 'شوربة عدس وسلطة',
    description: 'وجبة خفيفة مناسبة لمكتب العمل.',
    longDescription:
      'شوربة عدس كريمية مع سلطة موسمية وقطعة خبز محمّص. خيار صحي لدوام طويل.',
    ingredients: ['عدس', 'خضار', 'ليمون', 'خبز'],
    tags: ['خفيف', 'صحي', 'دوام'],
    priceIqd: 5500,
    remaining: 11,
    window: '١٢:٠٠ – ٢:٠٠',
    prepMinutes: 25,
    spice: 'mild',
    accent: '#5a6b4a',
    emoji: '🥗',
  },
  {
    id: 'meal-qeema',
    chefId: 'chef-um-noor',
    name: 'قيمة بتمر هندي',
    description: 'قيمة بغدادية حامضة مع تمن أبيض.',
    longDescription: 'قيمة بلحم مفروم وحمّص وتمر هندي — طعم بيتي بغدادي أصيل.',
    ingredients: ['لحم مفروم', 'حمص', 'تمر هندي', 'تمن'],
    tags: ['تراثي', 'لحم', 'حامض'],
    priceIqd: 8000,
    remaining: 5,
    window: '١٢:٠٠ – ٢:٠٠',
    prepMinutes: 40,
    spice: 'medium',
    accent: '#7a5538',
    emoji: '🥘',
  },
  {
    id: 'meal-tashreeb',
    chefId: 'chef-um-noor',
    name: 'تشريب دجاج',
    description: 'تشريب خبز بمرق دجاج غني.',
    longDescription: 'تشريب على أصوله: خبز يُنقع بمرق دجاج مع حمص وليمون.',
    ingredients: ['دجاج', 'خبز', 'حمص', 'مرق'],
    tags: ['تراثي', 'دجاج'],
    priceIqd: 7800,
    remaining: 4,
    window: '١٢:٠٠ – ٢:٠٠',
    prepMinutes: 55,
    spice: 'mild',
    accent: '#6a4a32',
    emoji: '🥣',
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
    description: 'كبة برغل محشوة بلحم ناعم، مرتبة ومجمّدة فور التحضير.',
    category: 'كبة برغل',
    priceIqd: 12000,
    unit: 'weight',
    unitLabel: 'كيلو',
    state: 'frozen',
    stateLabel: 'مجمّد جاهز للقلي',
    weightOptions: [
      { id: 'half', label: 'نصف كيلو', multiplier: 0.5 },
      { id: 'kilo', label: 'كيلو', multiplier: 1 },
      { id: 'kilo5', label: '١٫٥ كيلو', multiplier: 1.5 },
    ],
    packHint: 'تُشحن مع كيس ثلج جاف داخل المنطقة',
    accent: '#3d6b6b',
  },
  {
    id: 'fr-kubba-h',
    chefId: 'chef-um-zainab',
    name: 'كبة حلب جاهزة للقلي',
    description: 'كبة حلب مقرمشة من الخارج، جاهزة للقلي العميق.',
    category: 'كبة حلب',
    priceIqd: 10000,
    unit: 'weight',
    unitLabel: 'نصف كيلو',
    state: 'frozen',
    stateLabel: 'مجمّد جاهز للقلي',
    weightOptions: [
      { id: 'half', label: 'نصف كيلو', multiplier: 1 },
      { id: 'kilo', label: 'كيلو', multiplier: 2 },
    ],
    packHint: 'يفضّل القلي مباشرة دون إذابة كاملة',
    accent: '#2f5a5a',
  },
  {
    id: 'fr-sambo',
    chefId: 'chef-um-zainab',
    name: 'سمبوسك لحم',
    description: 'سمبوسك لحم متبّل — اطلب بالقطعة حسب عدد الضيوف.',
    category: 'سمبوسك',
    priceIqd: 500,
    unit: 'piece',
    unitLabel: 'قطعة',
    state: 'frozen',
    stateLabel: 'مجمّد جاهز للقلي',
    packHint: 'الحد الأدنى ١٠ قطع للتوصيل',
    accent: '#4a6b3d',
  },
  {
    id: 'fr-borek',
    chefId: 'chef-um-zainab',
    name: 'بورك جبن وسبانخ',
    description: 'صينية بورك رقيقة محشوة جبن وسبانخ، مبرّدة للفرن.',
    category: 'بورك',
    priceIqd: 8000,
    unit: 'weight',
    unitLabel: 'صينية صغيرة',
    state: 'chilled',
    stateLabel: 'مبرد جاهز للفرن',
    weightOptions: [
      { id: 'small', label: 'صينية صغيرة', multiplier: 1 },
      { id: 'large', label: 'صينية كبيرة', multiplier: 1.75 },
    ],
    packHint: 'اخبز على ١٨٠° لمدة ٢٠–٢٥ دقيقة',
    accent: '#6b5a3d',
  },
  {
    id: 'fr-pastry',
    chefId: 'chef-hala',
    name: 'فطائر زعتر',
    description: 'فطائر زعتر طازجة يوم التحضير، مبرّدة.',
    category: 'فطائر',
    priceIqd: 1500,
    unit: 'piece',
    unitLabel: 'قطعة',
    state: 'chilled',
    stateLabel: 'مبرد جاهز للفرن',
    packHint: 'سخّن ٥ دقائق قبل التقديم',
    accent: '#5a6b4a',
  },
  {
    id: 'fr-pickle',
    chefId: 'chef-um-ahmed',
    name: 'مخلل منزلي مشكل',
    description: 'مخلل خيار وجزر ولفت بخلطة بيتية.',
    category: 'مخللات',
    priceIqd: 4000,
    unit: 'piece',
    unitLabel: 'علبة',
    state: 'chilled',
    stateLabel: 'مبرد جاهز للتقديم',
    packHint: 'يُحفظ مبرّداً بعد الفتح',
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
  {
    id: 'r5',
    chefId: 'chef-hala',
    author: 'مريم س.',
    rating: 5,
    text: 'الشوربة خفيفة ولطيفة للدوام — أوصي بها.',
    date: 'منذ يوم',
  },
  {
    id: 'r6',
    chefId: 'chef-um-noor',
    author: 'علي ج.',
    rating: 4,
    text: 'القيمة حامضة بالمقدار الصح. تشريب الدجاج أيضاً ممتاز.',
    date: 'منذ ٤ أيام',
  },
]

export const MEAL_FILTERS = ['الكل', 'متوفر', 'تراثي', 'خفيف', 'دجاج', 'لحم'] as const
export const CHEF_SORTS = [
  { id: 'near', label: 'الأقرب' },
  { id: 'rating', label: 'الأعلى تقييماً' },
  { id: 'certified', label: 'المعتمد أولاً' },
] as const

export const DELIVERY_FEE_IQD = 2000
export const FREE_DELIVERY_FROM_IQD = 25000

export function formatIqd(n: number): string {
  return `${n.toLocaleString('ar-IQ')} د.ع`
}

export function spiceLabel(spice: Meal['spice']): string {
  if (spice === 'hot') return 'حار'
  if (spice === 'medium') return 'متوسط'
  return 'خفيف'
}

export function chefById(id: string): Chef | undefined {
  return CHEFS.find((c) => c.id === id)
}

export function mealById(id: string): Meal | undefined {
  return MEALS.find((m) => m.id === id)
}

export function frozenById(id: string): FrozenProduct | undefined {
  return FROZEN.find((p) => p.id === id)
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

export function buildOrderTimeline(
  nowLabel = 'الآن',
  progress: OrderStatus = 'preparing',
): OrderEvent[] {
  const order: OrderStatus[] = [
    'received',
    'preparing',
    'ready',
    'out_for_delivery',
    'delivered',
  ]
  const labels: Record<OrderStatus, string> = {
    received: 'تم استلام الطلب',
    preparing: 'قيد التحضير عند الطاهي',
    ready: 'جاهز للاستلام من المندوب',
    out_for_delivery: 'خرج للتوصيل',
    delivered: 'تم التسليم',
  }
  const idx = order.indexOf(progress)
  return order.map((status, i) => ({
    status,
    label: labels[status],
    at: i === 0 ? nowLabel : i <= idx ? 'تم' : i === idx + 1 ? 'قريباً' : '—',
    done: i <= idx,
  }))
}

export function searchChefs(query: string, sortId = 'near'): Chef[] {
  const q = query.trim()
  let list = CHEFS.filter((c) => {
    if (!q) return true
    const blob = `${c.name} ${c.kitchenName} ${c.specialties.join(' ')}`
    return blob.includes(q)
  })
  if (sortId === 'rating') list = [...list].sort((a, b) => b.rating - a.rating)
  else if (sortId === 'certified')
    list = [...list].sort(
      (a, b) => Number(b.certified) - Number(a.certified) || a.distanceKm - b.distanceKm,
    )
  else list = [...list].sort((a, b) => a.distanceKm - b.distanceKm)
  return list
}

export function searchMeals(query: string, filter = 'الكل'): Meal[] {
  const q = query.trim()
  return MEALS.filter((m) => {
    if (filter === 'متوفر' && m.remaining <= 0) return false
    if (filter !== 'الكل' && filter !== 'متوفر' && !m.tags.some((t) => t.includes(filter))) {
      // also match tag loosely / name
      if (!m.name.includes(filter) && !m.tags.includes(filter)) return false
    }
    if (!q) return true
    const chef = chefById(m.chefId)
    const blob = `${m.name} ${m.description} ${m.tags.join(' ')} ${chef?.name ?? ''} ${chef?.kitchenName ?? ''}`
    return blob.includes(q)
  })
}
