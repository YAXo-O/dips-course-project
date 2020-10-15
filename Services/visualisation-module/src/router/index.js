import Vue from 'vue';
import Router from 'vue-router';
import MainWindow from '@/components/pages/main-window/';

Vue.use(Router);

export default new Router({
  routes: [
    {
      path: '/',
      name: 'MainWindow',
      component: MainWindow,
    },
  ],
});
