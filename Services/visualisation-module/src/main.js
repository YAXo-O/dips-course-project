// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue';
import BootstrapVue from 'bootstrap-vue';
import 'bootstrap/dist/css/bootstrap.css';
import 'bootstrap-vue/dist/bootstrap-vue.css';
import VueSocketIO from 'vue-socket.io';
import io from 'socket.io-client';
import App from './App';
import router from './router';
import store from './store';

Vue.config.productionTip = false;

Vue.use(BootstrapVue);
Vue.use(new VueSocketIO({
  debug: true,
  connection: io(':4242/', {
    transports: ['websocket'],
    requestTimeout: 100,
  }),
}));

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  store,
  components: { App },
  template: '<App/>',
});
