import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AppProvider } from './context/AppContext'
import { Layout } from './components/Layout'
import { ZoneGate } from './pages/ZoneGate'
import { Home } from './pages/Home'
import { ChefProfile } from './pages/ChefProfile'
import { TodayMenu } from './pages/TodayMenu'
import { PreOrder } from './pages/PreOrder'
import { FrozenStore } from './pages/FrozenStore'
import { Cart } from './pages/Cart'
import { Checkout } from './pages/Checkout'
import { OrderStatus } from './pages/OrderStatus'

export default function App() {
  return (
    <AppProvider>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route path="/" element={<ZoneGate />} />
            <Route path="/home" element={<Home />} />
            <Route path="/menu" element={<TodayMenu />} />
            <Route path="/preorder" element={<PreOrder />} />
            <Route path="/frozen" element={<FrozenStore />} />
            <Route path="/chef/:chefId" element={<ChefProfile />} />
            <Route path="/cart" element={<Cart />} />
            <Route path="/checkout" element={<Checkout />} />
            <Route path="/order" element={<OrderStatus />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AppProvider>
  )
}
