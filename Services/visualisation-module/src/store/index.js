import Vue from 'vue';
import Vuex from 'vuex';

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    elements: [],
    usages: [],
    patterns: [],
  },
  getters: {
    ELEMENTS: state => state.elements,
    USAGES: state => state.usages,
    PATTERNS: state => state.patterns,
  },
  mutations: {
    SET_ELEMENTS(state, payload) {
      state.elements = payload;
    },
    UPDATE_ELEMENTS(state, payload) {
      payload.forEach((elem) => {
        const id = state.elements
          .findIndex(stored => stored.Name === elem.Name && stored.Nature === elem.Nature);
        if (id !== -1) {
          Vue.set(state.elements, id, elem);
        } else {
          state.elements.push(elem);
        }
      });
    },
    SET_USAGES(state, payload) {
      state.usages = payload;
    },
    SET_PATTERNS(state, payload) {
      state.patterns = payload;
    },
  },
  actions: {
    UPDATE_ELEMENTS: (context, payload) => {
      context.commit('UPDATE_ELEMENTS', payload);
    },
    SET_USAGES(context, payload) {
      context.commit('SET_USAGES', payload);
    },
    SET_PATTERNS(context, payload) {
      context.commit('SET_PATTERNS', payload);
    },
  },
});
