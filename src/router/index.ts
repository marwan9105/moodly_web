import { createRouter, createWebHistory } from 'vue-router';
import { useAuth } from '../composables/useAuth';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/login',
    },
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
});

router.beforeEach(async (to, _from, next) => {
  const { isAuthenticated, profile, loading, loadUser } = useAuth();

  if (loading.value) {
    await loadUser();
  }

  if (to.meta.requiresAuth && !isAuthenticated.value) {
    next('/login');
  } else if (to.meta.requiresGuest && isAuthenticated.value) {
    if (profile.value?.role === 'admin') {
      next('/admin');
    } else if (profile.value?.role === 'manager') {
      next('/manager');
    } else {
      next('/employee');
    }
  } else if (to.meta.requiresRole && profile.value?.role !== to.meta.requiresRole) {
    if (profile.value?.role === 'admin') {
      next('/admin');
    } else if (profile.value?.role === 'manager') {
      next('/manager');
    } else {
      next('/employee');
    }
  } else {
    next();
  }
});

export default router;
