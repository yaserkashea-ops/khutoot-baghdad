import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { AppProvider } from './context/AppContext'
import { Layout } from './components/Layout'
import { ZoneGate } from './pages/ZoneGate'
import { Home } from './pages/Home'
import { ChefProfile } from './pages/ChefProfile'
import { TodayMenu } from './pages/TodayMenu'
import { PreOrder } from './pages/PreOrder'
import { FrozenStore } from './pages/FrozenStore'
import { FrozenDetail } from './pages/FrozenDetail'
import { MealDetail } from './pages/MealDetail'
import { SearchPage } from './pages/SearchPage'
import { Cart } from './pages/Cart'
import { Checkout } from './pages/Checkout'
import { OrderStatus } from './pages/OrderStatus'
import { Orders } from './pages/Orders'
import { NotFound } from './pages/NotFound'

export default function App() {
  return (
    <AppProvider>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route path="/" element={<ZoneGate />} />
            <Route path="/home" element={<Home />} />
            <Route path="/search" element={<SearchPage />} />
            <Route path="/menu" element={<TodayMenu />} />
            <Route path="/meal/:mealId" element={<MealDetail />} />
            <Route path="/preorder" element={<PreOrder />} />
            <Route path="/frozen" element={<FrozenStore />} />
            <Route path="/frozen/:productId" element={<FrozenDetail />} />
            <Route path="/chef/:chefId" element={<ChefProfile />} />
            <Route path="/cart" element={<Cart />} />
            <Route path="/checkout" element={<Checkout />} />
            <Route path="/orders" element={<Orders />} />
            <Route path="/order" element={<Orders />} />
            <Route path="/order/:orderId" element={<OrderStatus />} />
            <Route path="*" element={<NotFound />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AppProvider>
  )
}
