import { createRouter, createWebHistory } from 'vue-router'
import { useAuth } from '../composables/useAuth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/login' },
    {
      path: '/login',
      name: 'Login',
      component: () => import('../views/LoginView.vue'),
      meta: { requiresGuest: true },
    },
    {
      path: '/admin',
      name: 'Admin',
      component: () => import('../views/AdminView.vue'),
      meta: { requiresAuth: true, requiresRole: 'admin' },
    },
    {
      path: '/manager',
      name: 'Manager',
      component: () => import('../views/ManagerView.vue'),
      meta: { requiresAuth: true, requiresRole: 'manager' },
    },
    {
      path: '/employee',
      name: 'Employee',
      component: () => import('../views/EmployeeView.vue'),
      meta: { requiresAuth: true, requiresRole: 'employee' },
    },
  ],
})

router.beforeEach(async (to) => {
  const { ready, loading, isAuthenticated, profile } = useAuth()

  await ready()

  if (loading.value) return false

  if (to.meta.requiresAuth && !isAuthenticated.value) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }

  if (to.meta.requiresGuest && isAuthenticated.value) {
    const role = profile.value?.role
    if (role === 'admin') return { path: '/admin' }
    if (role === 'manager') return { path: '/manager' }
    return { path: '/employee' }
  }

  const needed = to.meta.requiresRole as string | undefined
  if (needed && profile.value?.role !== needed) {
    const role = profile.value?.role
    if (role === 'admin') return { path: '/admin' }
    if (role === 'manager') return { path: '/manager' }
    return { path: '/employee' }
  }

  return true
})

export default router
